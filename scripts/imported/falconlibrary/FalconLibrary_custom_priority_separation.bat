@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Custom_Priority_Separation
echo.
setlocal
color A
chcp 65001 >nul 2>&1
echo. 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "%CustomValue%" /f >nul 2>&1
if %errorlevel%==0 (
   echo.
   <nul set /p="→ Press any key to continue . . . "
   pause >nul
   goto :Redetect_WinVer
) else (
   goto :Priority_Separation
)
endlocal
echo.
echo [Falcon] Done.
endlocal
exit /b 0