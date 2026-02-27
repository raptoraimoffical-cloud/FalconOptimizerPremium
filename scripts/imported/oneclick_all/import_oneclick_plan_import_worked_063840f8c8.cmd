@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
powercfg.cpl
taskkill /F /FI "WINDOWTITLE eq Power Options" >nul 2>&1
endlocal
