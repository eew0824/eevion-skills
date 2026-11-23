@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set "installExitCode=%errorlevel%"
if /i not "%~1"=="--no-pause" pause
exit /b %installExitCode%
