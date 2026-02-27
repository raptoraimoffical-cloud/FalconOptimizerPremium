@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
   start "" "C:\VC Redist\VC_redist.x64.exe" /install /passive /norestart
   rd /s /q "C:\VC Redist" >nul 2>&1
   rd /s /q "C:\VC Redist" >nul 2>&1
endlocal
