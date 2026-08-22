$ErrorActionPreference="Stop"
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$app=Get-Content -Raw -Encoding UTF8 (Join-Path $Root "app.config.json")|ConvertFrom-Json
$deps=Get-Content -Raw -Encoding UTF8 (Join-Path $Root "dependencies.json")|ConvertFrom-Json
$src=[System.IO.File]::ReadAllText((Join-Path $Root "src\index.template.html"),[System.Text.Encoding]::UTF8)
if([string]::IsNullOrWhiteSpace([string]$app.name)){throw "app.config.json name is empty"}
if([string]$app.version -ne "1.3.0"){throw "Expected version 1.3.0"}
$ids=@{};foreach($d in @($deps.dependencies)){if($ids.ContainsKey([string]$d.id)){throw "Duplicate dependency id: $($d.id)"};$ids[[string]$d.id]=$true;if([string]$d.version -match '[\*xX~^><= ]'){throw "Dependency must use an exact version: $($d.id)"}}
foreach($token in @("__APP_CONFIG_JSON__","__BUILD_MANIFEST_JSON__","__EMBEDDED_ASSET_BUNDLE_JSON__")){if(([regex]::Matches($src,[regex]::Escape($token))).Count -ne 1){throw "Placeholder must occur once: $token"}}
foreach($marker in @("APP:BEGIN","APP:END","APP:HELP:BEGIN","APP:HELP:END","AirRemoteBridge","blazepalm","connect-src 'none'")){if(-not $src.Contains($marker)){throw "Required source marker missing: $marker"}}
if($src -match '<script[^>]+src\s*=\s*["'']https?://'){throw "External runtime script is not allowed"}
Write-Host "Repository checks passed." -ForegroundColor Green
