@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
sc query "ucpd" | find "STATE" | find "RUNNING" >nul
endlocal
