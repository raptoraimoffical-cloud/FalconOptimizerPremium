@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    sc config "ucpd" start=disabled >nul 2>&1
    schtasks /change /disable /tn "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity" >nul 2>&1
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
endlocal
