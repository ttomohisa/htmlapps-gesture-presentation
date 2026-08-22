param(
  [Parameter(Mandatory=$true)][string]$InputPath,
  [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference="Stop"
$html=[System.IO.File]::ReadAllBytes($InputPath)
$out=New-Object System.IO.MemoryStream
$gzip=New-Object System.IO.Compression.GZipStream -ArgumentList @($out,[System.IO.Compression.CompressionMode]::Compress,$true)
try{$gzip.Write($html,0,$html.Length)}finally{$gzip.Dispose()}
try{$payload=[Convert]::ToBase64String($out.ToArray())}finally{$out.Dispose()}
$text=[System.IO.File]::ReadAllText($InputPath,[System.Text.Encoding]::UTF8)
$favicon="";$m=[regex]::Match($text,'<link\s+rel="icon"\s+href="([^"]+)"');if($m.Success){$favicon=$m.Groups[1].Value}
$loader=@"
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gesture Presentation</title><link rel="icon" href="$favicon"><style>body{margin:0;display:grid;place-items:center;min-height:100vh;font-family:system-ui,sans-serif;background:#f5f5f2;color:#20211f}.box{text-align:center;padding:24px}.spin{width:26px;height:26px;margin:0 auto 12px;border:3px solid #dadbd6;border-top-color:#16624f;border-radius:50%;animation:s .8s linear infinite}@keyframes s{to{transform:rotate(360deg)}}</style></head><body><div class="box"><div class="spin"></div><div>Opening Gesture Presentation...</div></div><script>(async()=>{const b='$payload',r=atob(b),u=new Uint8Array(r.length);for(let i=0;i<r.length;i++)u[i]=r.charCodeAt(i);if(typeof DecompressionStream!=='function'){document.body.textContent='This browser cannot open the compressed build. Use dist/index.html instead.';return}const s=new Blob([u]).stream().pipeThrough(new DecompressionStream('gzip'));const t=await new Response(s).text();document.open();document.write(t);document.close()})().catch(e=>{document.body.textContent='Failed to open application: '+e.message})</script></body></html>
"@
$dir=Split-Path -Parent $OutputPath;New-Item -ItemType Directory -Force -Path $dir|Out-Null
[System.IO.File]::WriteAllText($OutputPath,$loader,(New-Object System.Text.ASCIIEncoding))
Write-Host "Self-extract HTML created: $OutputPath" -ForegroundColor Green
