param(
  [switch]$ForceDownload,
  [switch]$SkipSelfExtract,
  [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version Latest
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplatePath = Join-Path $Root "src\index.template.html"
$AppConfigPath = Join-Path $Root "app.config.json"
$DependenciesPath = Join-Path $Root "dependencies.json"
$CacheRoot = Join-Path $Root ".cache"
$DistRoot = Join-Path $Root "dist"

function Write-Step([string]$Message) { Write-Host "[Gesture Presentation] $Message" -ForegroundColor Cyan }
function Get-Json([string]$Path) {
  if (-not (Test-Path $Path)) { throw "Required file not found: $Path" }
  return Get-Content -Raw -Encoding UTF8 $Path | ConvertFrom-Json
}
function Get-Sha256Hex([byte[]]$Bytes) {
  $algorithm = [System.Security.Cryptography.SHA256]::Create()
  try { $hash = $algorithm.ComputeHash($Bytes) } finally { $algorithm.Dispose() }
  return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}
function Get-Sha256FileHex([string]$Path) {
  $stream = [System.IO.File]::OpenRead($Path)
  $algorithm = [System.Security.Cryptography.SHA256]::Create()
  try { $hash = $algorithm.ComputeHash($stream) } finally { $algorithm.Dispose(); $stream.Dispose() }
  return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}
function Get-SafeId([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notmatch '^[a-z0-9][a-z0-9._-]*$') { throw "Invalid dependency or asset id: $Value" }
  return $Value
}
function ConvertTo-SafeJson([object]$Value, [int]$Depth = 40) {
  return ($Value | ConvertTo-Json -Compress -Depth $Depth).Replace("<", "\u003c").Replace(">", "\u003e").Replace("&", "\u0026")
}
function Compress-GzipBytes([byte[]]$Bytes) {
  $output = New-Object System.IO.MemoryStream
  $gzip = New-Object System.IO.Compression.GZipStream -ArgumentList @($output,[System.IO.Compression.CompressionMode]::Compress,$true)
  try { $gzip.Write($Bytes,0,$Bytes.Length) } finally { $gzip.Dispose() }
  try { return ,$output.ToArray() } finally { $output.Dispose() }
}
function Get-MimeType([string]$Path) {
  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".js" { "text/javascript"; break }
    ".mjs" { "text/javascript"; break }
    ".wasm" { "application/wasm"; break }
    ".json" { "application/json"; break }
    default { "application/octet-stream" }
  }
}
function Get-AssetBytes([string]$Path, [bool]$Strip) {
  if (-not (Test-Path $Path)) { throw "Dependency asset not found: $Path" }
  if ($Strip -and [System.IO.Path]::GetExtension($Path) -in @(".js", ".mjs", ".css")) {
    $text = [System.IO.File]::ReadAllText($Path,[System.Text.Encoding]::UTF8)
    $text = [regex]::Replace($text,"(?m)^\s*//# sourceMappingURL=.*$","")
    $text = [regex]::Replace($text,"(?m)^\s*/\*# sourceMappingURL=.*?\*/\s*$","")
    return [System.Text.Encoding]::UTF8.GetBytes($text)
  }
  return [System.IO.File]::ReadAllBytes($Path)
}
function Resolve-NpmPackage([string]$PackageName,[string]$Version) {
  $key = (($PackageName -replace "[^A-Za-z0-9._-]","-") + "-" + $Version)
  $dir = Join-Path $CacheRoot $key
  $archive = Join-Path $dir "package.tgz"
  $extract = Join-Path $dir "extracted"
  $packageRoot = Join-Path $extract "package"
  if ($ForceDownload -and (Test-Path $dir)) { Remove-Item -Recurse -Force $dir }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if (-not (Test-Path $archive)) {
    $encoded = [Uri]::EscapeDataString($PackageName)
    Write-Step "Resolving $PackageName@$Version"
    $metadata = Invoke-RestMethod -Uri "https://registry.npmjs.org/$encoded/$Version" -UseBasicParsing -Headers @{"User-Agent"="htmlapps-gesture-presentation/1.0"}
    if (-not $metadata.dist.tarball) { throw "npm metadata did not contain a tarball for $PackageName@$Version" }
    $partial = "$archive.part"
    Remove-Item -Force -ErrorAction SilentlyContinue $partial
    Invoke-WebRequest -Uri ([string]$metadata.dist.tarball) -OutFile $partial -UseBasicParsing -Headers @{"User-Agent"="htmlapps-gesture-presentation/1.0"}
    Move-Item -Force $partial $archive
  }
  if (-not (Test-Path $packageRoot)) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $extract
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    & tar.exe -xzf $archive -C $extract
    if ($LASTEXITCODE -ne 0) { throw "tar.exe failed for $PackageName@$Version" }
  }
  $packageJson = Join-Path $packageRoot "package.json"
  if (Test-Path $packageJson) {
    $actual = [string]((Get-Content -Raw -Encoding UTF8 $packageJson | ConvertFrom-Json).version)
    if ($actual -and $actual -ne $Version) { throw "Expected $PackageName@$Version but archive contains $actual" }
  }
  return @{ Root=$packageRoot; Archive=$archive; ArchiveSha256=(Get-Sha256FileHex $archive) }
}
function Resolve-SafePath([string]$PackageRoot,[string]$Relative) {
  $rootFull = [System.IO.Path]::GetFullPath($PackageRoot).TrimEnd([char[]]@([char]92,[char]47))
  $assetFull = [System.IO.Path]::GetFullPath((Join-Path $PackageRoot $Relative))
  if (-not $assetFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar,[System.StringComparison]::OrdinalIgnoreCase)) { throw "Asset path escapes package root: $Relative" }
  return $assetFull
}

if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) { throw "tar.exe is required (current Windows 10/11 includes it)." }
New-Item -ItemType Directory -Force -Path $CacheRoot,$DistRoot | Out-Null
$app = Get-Json $AppConfigPath
$depConfig = Get-Json $DependenciesPath
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path $Root ([string]$app.build.output) }
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath = Join-Path $Root $OutputPath }

$bundle = [ordered]@{ schemaVersion=2; dependencies=[ordered]@{} }
$manifestDependencies = @()
$seen = @{}
foreach ($dep in @($depConfig.dependencies)) {
  $id = Get-SafeId ([string]$dep.id)
  if ($seen.ContainsKey($id)) { throw "Duplicate dependency id: $id" }
  $seen[$id] = $true
  $pkg = Resolve-NpmPackage ([string]$dep.package) ([string]$dep.version)
  $assetMap = [ordered]@{}
  $manifestAssets = @()
  $assetSeen = @{}
  foreach ($asset in @($dep.assets)) {
    $key = Get-SafeId ([string]$asset.key)
    if ($assetSeen.ContainsKey($key)) { throw "Duplicate asset key $id/$key" }
    $assetSeen[$key]=$true
    $path = Resolve-SafePath $pkg.Root ([string]$asset.path)
    $strip = $false; if ($asset.PSObject.Properties.Name -contains "stripSourceMapComment") { $strip=[bool]$asset.stripSourceMapComment }
    $bytes = Get-AssetBytes $path $strip
    $mime = if ($asset.PSObject.Properties.Name -contains "mime" -and -not [string]::IsNullOrWhiteSpace([string]$asset.mime)) { [string]$asset.mime } else { Get-MimeType $path }
    $setting = "none"; if ($asset.PSObject.Properties.Name -contains "compression") { $setting=([string]$asset.compression).ToLowerInvariant() }
    if ($setting -notin @("none","gzip","auto")) { throw "Unsupported compression: $setting" }
    $stored = $bytes; $resolved = "none"
    if ($setting -in @("gzip","auto")) {
      $gz = Compress-GzipBytes $bytes
      if ($setting -eq "gzip" -or $gz.Length -lt $bytes.Length) { $stored=$gz; $resolved="gzip" }
    }
    $assetMap[$key] = [ordered]@{mime=$mime;compression=$resolved;originalBytes=$bytes.Length;storedBytes=$stored.Length;base64=[Convert]::ToBase64String($stored)}
    $manifestAssets += [ordered]@{key=$key;path=[string]$asset.path;mime=$mime;compression=$resolved;bytes=$bytes.Length;storedBytes=$stored.Length;sha256=(Get-Sha256Hex $bytes)}
  }
  $bundle.dependencies[$id]=[ordered]@{package=[string]$dep.package;version=[string]$dep.version;assets=$assetMap}
  $license="";$homepage="";if($dep.PSObject.Properties.Name -contains "license"){$license=[string]$dep.license};if($dep.PSObject.Properties.Name -contains "homepage"){$homepage=[string]$dep.homepage}
  $manifestDependencies += [ordered]@{id=$id;package=[string]$dep.package;version=[string]$dep.version;license=$license;homepage=$homepage;tarballSha256=$pkg.ArchiveSha256;assets=$manifestAssets}
}
$manifest=[ordered]@{schemaVersion=2;builder="htmlapps-template-compatible/1.0";generatedAtUtc=[DateTime]::UtcNow.ToString("o");app=[ordered]@{name=[string]$app.name;slug=[string]$app.slug;version=[string]$app.version};dependencies=$manifestDependencies}

Write-Step "Generating readable single HTML"
$template=[System.IO.File]::ReadAllText($TemplatePath,[System.Text.Encoding]::UTF8)
$replacements=[ordered]@{
  "__APP_CONFIG_JSON__"=(ConvertTo-SafeJson $app 20)
  "__BUILD_MANIFEST_JSON__"=(ConvertTo-SafeJson $manifest 40)
  "__EMBEDDED_ASSET_BUNDLE_JSON__"=(ConvertTo-SafeJson $bundle 60)
}
foreach($entry in $replacements.GetEnumerator()){
  $count=([regex]::Matches($template,[regex]::Escape($entry.Key))).Count
  if($count -ne 1){throw "Template placeholder $($entry.Key) must occur exactly once; found $count."}
  $template=$template.Replace($entry.Key,[string]$entry.Value)
}
$outputDir=Split-Path -Parent $OutputPath;New-Item -ItemType Directory -Force -Path $outputDir|Out-Null
[System.IO.File]::WriteAllText($OutputPath,$template,(New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $outputDir "dependency-manifest.json"),($manifest|ConvertTo-Json -Depth 50),(New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $outputDir ".nojekyll"),"",(New-Object System.Text.UTF8Encoding($false)))

& (Join-Path $Root "scripts\verify-standalone.ps1") -Path $OutputPath
if($LASTEXITCODE -ne 0){throw "Readable HTML verification failed."}

$selfPath=""
if(-not $SkipSelfExtract -and $app.build.selfExtract -and [bool]$app.build.selfExtract.enabled){
  $selfPath=Join-Path $Root ([string]$app.build.selfExtract.output)
  & (Join-Path $Root "scripts\build-self-extract.ps1") -InputPath $OutputPath -OutputPath $selfPath
  if($LASTEXITCODE -ne 0){throw "Self-extract build failed."}
}

$readableBytes=(Get-Item $OutputPath).Length
$selfBytes=if($selfPath -and (Test-Path $selfPath)){(Get-Item $selfPath).Length}else{0}
$assetRows=@();foreach($d in $manifestDependencies){foreach($a in $d.assets){$assetRows += [ordered]@{dependency=$d.id;asset=$a.key;originalBytes=$a.bytes;storedBytes=$a.storedBytes;compression=$a.compression}}}
$report=[ordered]@{generatedAtUtc=[DateTime]::UtcNow.ToString("o");readableBytes=$readableBytes;readableMiB=[math]::Round($readableBytes/1MB,2);selfExtractBytes=$selfBytes;selfExtractMiB=[math]::Round($selfBytes/1MB,2);assets=$assetRows}
[System.IO.File]::WriteAllText((Join-Path $outputDir "build-size-report.json"),($report|ConvertTo-Json -Depth 10),(New-Object System.Text.UTF8Encoding($false)))
Write-Step ("Done: readable {0:N2} MiB, self-extract {1:N2} MiB" -f ($readableBytes/1MB),($selfBytes/1MB))
