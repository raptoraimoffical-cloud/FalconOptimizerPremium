@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Autorun_FalconLibrary
echo.
set "FalconLibraryPath=%~f0"
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "AutorunFalconLibraryAfterRestart" /t REG_SZ /d "\"%FalconLibraryPath%\"" /f >nul 2>&1
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