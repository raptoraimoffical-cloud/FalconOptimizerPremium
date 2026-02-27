@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Plan_Import_Worked
echo.
color A
chcp 65001 >nul 2>&1
powercfg.cpl
echo.
<nul set /p="→ Press any key to continue . . . "
pause >nul
taskkill /F /FI "WINDOWTITLE eq Power Options" >nul 2>&1
goto :Clean_Up
echo.
echo [Falcon] Done.
endlocal
exit /b 0