@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "PATCH_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %PATCH_EXIT%
