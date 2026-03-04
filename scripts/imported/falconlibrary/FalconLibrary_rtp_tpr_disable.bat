@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: RTP_TPR_Disable
echo.
color A
chcp 65001 >nul 2>&1
echo. 
echo.
echo.
echo.
start windowsdefender: >nul 2>&1
<nul set /p="%White%Once all steps are completed, Press any key to continue . . . "
pause >nul
taskkill /f /im SecHealthUI.exe >nul 2>&1
goto :Dcontrol_Download
echo.
echo [Falcon] Done.
endlocal
exit /b 0