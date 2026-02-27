@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Autorun_Oneclick
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
echo.
echo [Falcon] Done.
endlocal
exit /b 0