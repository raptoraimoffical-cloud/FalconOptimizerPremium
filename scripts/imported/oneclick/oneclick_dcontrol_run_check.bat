@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Dcontrol_Run_Check
echo.
if exist "C:\Program Files (x86)\DefenderControl\dControl.exe" (
) else (
)
sc qc "WinDefend" | find "START_TYPE" | find "DISABLED" >nul
if not errorlevel 1 (
) else (
)
"C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:hide -U:T -P:E cmd /c reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d "4" /f
if errorlevel 1 (
) else (
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0