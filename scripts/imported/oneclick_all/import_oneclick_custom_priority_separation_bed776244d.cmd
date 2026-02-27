@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "%CustomValue%" /f >nul 2>&1
endlocal
