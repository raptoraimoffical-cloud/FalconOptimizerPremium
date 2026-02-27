@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Power_Plan
echo.
color 9
chcp 65001 >nul 2>&1
echo.
if "%option%"=="1" (
    powercfg -import "C:\Oneclick Tools\Power Plans\Quaked Ultimate Performance.pow" >nul 2>&1
    goto :Check_Plan_Import
) else if "%option%"=="2" (
    powercfg -import "C:\Oneclick Tools\Power Plans\Quaked Ultimate Performance Idle Off.pow" >nul 2>&1
    goto :Check_Plan_Import
) else if "%option%"=="3" (
    color A
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Power%%20Plan%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Power_Plan
) else if "%option%"=="4" (
    goto :Clean_Up
) else (
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-4.' -ForegroundColor White -BackgroundColor Red"
    goto :Power_Plan
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0