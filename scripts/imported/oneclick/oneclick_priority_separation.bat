@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Priority_Separation
echo.
color 9
chcp 65001 >nul 2>&1
echo.
if "%option%"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x2a" /f >nul 2>&1 
    goto :Redetect_WinVer
) else if "%option%"=="2" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x00000024" /f >nul 2>&1
    goto :Redetect_WinVer
) else if "%option%"=="3" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "0x1a" /f >nul 2>&1
    goto :Redetect_WinVer
) else if "%option%"=="4" (
    goto :Custom_Priority_Separation
) else if "%option%"=="5" (
    color A
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Priority%%20Separation%%20Options.md"
    echo.
    <nul set /p="→ Press any key to continue . . . "
    pause >nul
    goto :Priority_Separation
) else if "%option%"=="6" (
    goto :Redetect_WinVer
) else (
    chcp 437 >nul
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-6.' -ForegroundColor White -BackgroundColor Red"
    goto :Priority_Separation
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0