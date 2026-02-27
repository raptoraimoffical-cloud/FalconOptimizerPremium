@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Custom_Timer_Resolution
echo.
setlocal
color A
chcp 65001 >nul 2>&1
echo. 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution %CustomValue% --no-console" /f >nul 2>&1
if %errorlevel%==0 (
   echo.
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   goto :Power_Plan
) else (
   goto :Timer_Res_11
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0