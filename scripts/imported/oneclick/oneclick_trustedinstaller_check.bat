@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: TrustedInstaller_Check
echo.
sc qc "TrustedInstaller" | find "START_TYPE" | find "DISABLED" >nul 2>&1
if errorlevel 1 (
) else ( 
    sc config TrustedInstaller start=auto >nul 2>&1
    net start TrustedInstaller >nul 2>&1
)
if not exist "C:\Oneclick Tools" (
) else (
   rd /s /q "C:\Oneclick Tools" >nul 2>&1 
)
goto :Download_Tools
echo.
echo [Falcon] Done.
endlocal
exit /b 0