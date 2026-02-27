@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    powercfg -import "C:\Oneclick Tools\Power Plans\Quaked Ultimate Performance.pow" >nul 2>&1
    powercfg -import "C:\Oneclick Tools\Power Plans\Quaked Ultimate Performance Idle Off.pow" >nul 2>&1
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Power%%20Plan%%20Options.md"
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-4.' -ForegroundColor White -BackgroundColor Red"
endlocal
