@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Check_Plan_Import
echo.
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:(" %%i in ('powercfg /list ^| findstr /C:"Quaked Ultimate Performance"') do (
    set Plan_Guid=%%i
)
for /f "tokens=2 delims=:(" %%i in ('powercfg /list ^| findstr /C:"Quaked Ultimate Performance Idle Off"') do (
    set Idle_Off_Plan_Guid=%%i
)
if defined Plan_Guid (
   powercfg /setactive %Plan_Guid% >nul 2>&1
   endlocal & goto :Plan_Import_Worked  
) else if defined Idle_Off_Plan_Guid (
   powercfg /setactive %Idle_Off_Plan_Guid% >nul 2>&1
   endlocal & goto :Plan_Import_Worked  
) else (
   endlocal & goto :Plan_Import_Failed
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0