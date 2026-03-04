@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
sc qc "TrustedInstaller" | find "START_TYPE" | find "DISABLED" >nul 2>&1
    sc config TrustedInstaller start=auto >nul 2>&1
    net start TrustedInstaller >nul 2>&1
   rd /s /q "C:\Oneclick Tools" >nul 2>&1
endlocal
