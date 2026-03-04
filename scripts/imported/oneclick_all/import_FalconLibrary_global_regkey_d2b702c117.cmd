@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d "1" /f >nul 2>&1
endlocal
