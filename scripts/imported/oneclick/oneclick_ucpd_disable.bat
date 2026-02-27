@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: UCPD_Disable
echo.
color C
chcp 65001 >nul 2>&1
echo.
if /i "%choice%"=="Y" (
    color A
    sc config "ucpd" start=disabled >nul 2>&1
    schtasks /change /disable /tn "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity" >nul 2>&1
    echo.
set "OneclickPath=%~f0"
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "AutorunOneclickAfterRestart" /t REG_SZ /d "\"%OneclickPath%\"" /f >nul 2>&1
if %errorlevel% equ 0 (
echo. 
)
    shutdown /r /t 0
    exit  
) else (
    color C
    chcp 65001 >nul 2>&1
    echo
    shutdown /r /t 0
    exit 
)
) else if /i "%choice%"=="N" (
    color C
    chcp 437 >nul
    goto :TrustedInstaller_Check
) else (
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose Y or N.' -ForegroundColor White -BackgroundColor Red"
    goto :UCPD_Disable
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0