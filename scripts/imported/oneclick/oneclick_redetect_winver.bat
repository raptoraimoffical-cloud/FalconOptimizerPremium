@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Redetect_WinVer
echo.
setlocal enabledelayedexpansion
if !CurrentBuild! GEQ 22000 (
    rd /s /q "C:\Oneclick Tools\DPC Checker" >nul 2>&1
    endlocal & goto :Timer_Res_11
) else (
    endlocal & goto :Recheck_WinSer
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0