@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File ".\build-standalone.ps1" %*
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" echo Build failed with exit code %ERR%.
exit /b %ERR%
