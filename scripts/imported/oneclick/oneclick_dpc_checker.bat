@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: DPC_Checker
echo.
color C
chcp 65001 >nul 2>&1
echo.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "DPC Checker" /t REG_SZ /d "C:\Oneclick Tools\DPC Checker\dpclat.exe" /f >nul 2>&1
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul
echo.
echo [Falcon] Done.
endlocal
exit /b 0