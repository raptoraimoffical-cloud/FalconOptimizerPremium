@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Recheck_WinSer
echo.
setlocal
if /i "%ServerType%"=="Server" (
    rd /s /q "C:\Oneclick Tools\DPC Checker" >nul 2>&1
    endlocal & goto :Timer_Res_11
) else (
    endlocal & goto :DPC_Checker
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0