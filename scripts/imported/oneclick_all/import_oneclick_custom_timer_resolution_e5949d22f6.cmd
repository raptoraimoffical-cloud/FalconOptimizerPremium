@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TimerResolution" /t REG_SZ /d "C:\Oneclick Tools\Timer Resolution\SetTimerResolution.exe --resolution %CustomValue% --no-console" /f >nul 2>&1
endlocal
