@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
sc config TrustedInstaller start=disabled >nul 2>&1
rd /s /q "C:\Oneclick Tools\Edge Remover"
rd /s /q "C:\Oneclick Tools\OOshutup10"
rd /s /q "C:\Oneclick Tools\Power Plans"
endlocal
