@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "AutorunOneclickAfterRestart" /t REG_SZ /d "\"%OneclickPath%\"" /f >nul 2>&1
endlocal
