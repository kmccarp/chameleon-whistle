@echo off
REM Double-click me. Launches the PowerShell installer with a per-process
REM execution-policy bypass, so no system settings are changed.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
pause
