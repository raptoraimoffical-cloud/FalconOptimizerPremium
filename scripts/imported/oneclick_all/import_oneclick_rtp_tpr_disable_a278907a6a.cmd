@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
start windowsdefender: >nul 2>&1
taskkill /f /im SecHealthUI.exe >nul 2>&1
endlocal
