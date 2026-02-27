@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
sc qc "WinDefend" | find "START_TYPE" | find "DISABLED" >nul
"C:\Oneclick Tools\NSudo\NSudoLG.exe" -ShowWindowMode:hide -U:T -P:E cmd /c reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d "4" /f
endlocal
