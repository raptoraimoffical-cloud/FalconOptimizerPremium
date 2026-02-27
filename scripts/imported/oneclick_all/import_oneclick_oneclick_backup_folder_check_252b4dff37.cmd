@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
   for /f "usebackq delims=" %%A in (`Powershell -NoProfile -Command "Get-Date -Format 'MM-dd-yyyy_HH-mm'"`) do set "CurrentDate=%%A"
endlocal
