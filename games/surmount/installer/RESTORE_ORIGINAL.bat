@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore.ps1" %*
set "patchExitCode=%ERRORLEVEL%"
echo.
pause
exit /b %patchExitCode%
