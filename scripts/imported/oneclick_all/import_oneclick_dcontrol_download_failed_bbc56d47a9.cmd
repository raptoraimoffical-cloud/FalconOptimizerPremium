@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    start "" "https://www.sordum.org/9480/defender-control-v2-1/"
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
endlocal
