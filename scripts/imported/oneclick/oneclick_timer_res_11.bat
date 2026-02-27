@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Timer_Res_11
echo.
color D
chcp 65001 >nul 2>&1
echo.
if "%option%"=="1" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5000 --no-console" /f >nul 2>&1
    goto :Power_Plan
) else if "%option%"=="2" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5040 --no-console" /f >nul 2>&1
    goto :Power_Plan
) else if "%option%"=="3" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution 5070 --no-console" /f >nul 2>&1
    goto :Power_Plan
) else if "%option%"=="4" (
    goto :Custom_Timer_Resolution
) else if "%option%"=="5" (
    color A
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Timer%%20Resolution%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Timer_Res_11
) else if "%option%"=="6" (
    rd /s /q "C:\Oneclick Tools\Timer Resolution" >nul 2>&1
    goto :Power_Plan
) else (
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
    goto :Priority_Separation
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0