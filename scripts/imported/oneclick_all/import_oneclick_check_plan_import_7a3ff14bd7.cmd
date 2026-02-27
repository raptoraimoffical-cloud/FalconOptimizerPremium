@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
for /f "tokens=2 delims=:(" %%i in ('powercfg /list ^| findstr /C:"Quaked Ultimate Performance"') do (
for /f "tokens=2 delims=:(" %%i in ('powercfg /list ^| findstr /C:"Quaked Ultimate Performance Idle Off"') do (
   powercfg /setactive %Plan_Guid% >nul 2>&1
   powercfg /setactive %Idle_Off_Plan_Guid% >nul 2>&1
endlocal
