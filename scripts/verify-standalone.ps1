param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference="Stop"
if(-not(Test-Path $Path)){throw "File not found: $Path"}
$text=[System.IO.File]::ReadAllText($Path,[System.Text.Encoding]::UTF8)
foreach($token in @("__APP_CONFIG_JSON__","__BUILD_MANIFEST_JSON__","__EMBEDDED_ASSET_BUNDLE_JSON__")){if($text.Contains($token)){throw "Unresolved placeholder: $token"}}
if($text -notmatch "connect-src 'none'"){throw "CSP must contain connect-src 'none'."}
if($text -match '<script[^>]+src\s*=\s*["'']https?://'){throw "Runtime external script found."}
if($text -match '<link[^>]+href\s*=\s*["'']https?://'){throw "Runtime external stylesheet/link found."}
if($text -notmatch 'AirRemoteBridge'){throw "AirRemoteBridge is missing."}
Write-Host "Standalone verification passed: $Path" -ForegroundColor Green
