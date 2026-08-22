@echo off
setlocal
cd /d "%~dp0"
if not exist "dist\index.html" call build-standalone.bat
if errorlevel 1 exit /b %ERRORLEVEL%
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File ".\scripts\start-local.ps1"
