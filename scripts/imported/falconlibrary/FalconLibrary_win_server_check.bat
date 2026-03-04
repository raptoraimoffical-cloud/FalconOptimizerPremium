@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Win_Server_Check
echo.
setlocal enabledelayedexpansion
for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName') do set "ProductName=%%A %%B"
if !errorlevel! == 0 (
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f >nul 2>&1
if %errorlevel% EQU 0 (
) else (
)
    endlocal & goto :VCRuntime_Check
) else (
    endlocal & goto :VCRuntime_Check
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0