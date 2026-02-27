@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
   start "" "C:\Dcontrol\dControl.exe"
   taskkill /IM dControl.exe /F >nul 2>&1
   rd /s /q "C:\Dcontrol" >nul 2>&1
   rd /s /q "C:\Dcontrol" >nul 2>&1
endlocal
