@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
sc query "WinDefend" | find "STATE" | find "RUNNING" >nul
endlocal
