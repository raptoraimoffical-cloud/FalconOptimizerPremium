@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Restart
echo.
color A
chcp 65001 >nul 2>&1
sc config TrustedInstaller start=disabled >nul 2>&1
rd /s /q "C:\Oneclick Tools\Edge Remover"
rd /s /q "C:\Oneclick Tools\OOshutup10"
rd /s /q "C:\Oneclick Tools\Power Plans"
echo. 
)
shutdown /r /t 0
exit 
echo.
echo [Falcon] Done.
endlocal
exit /b 0