param([int]$Port=8080)
$ErrorActionPreference="Stop"
$Root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$File=Join-Path $Root "dist\index.html"
if(-not(Test-Path $File)){throw "dist/index.html not found. Run build-standalone.bat first."}
$listener=New-Object System.Net.HttpListener
$prefix="http://localhost:$Port/";$listener.Prefixes.Add($prefix);$listener.Start()
Write-Host "Gesture Presentation local server: $prefix" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor DarkGray
try{Start-Process $prefix}catch{}
try{
  while($listener.IsListening){
    $context=$listener.GetContext();$response=$context.Response
    if($context.Request.Url.AbsolutePath -eq "/" -or $context.Request.Url.AbsolutePath -eq "/index.html"){
      $bytes=[System.IO.File]::ReadAllBytes($File);$response.ContentType="text/html; charset=utf-8";$response.ContentLength64=$bytes.Length;$response.OutputStream.Write($bytes,0,$bytes.Length)
    }else{$response.StatusCode=404}
    $response.OutputStream.Close()
  }
}finally{$listener.Stop();$listener.Close()}
