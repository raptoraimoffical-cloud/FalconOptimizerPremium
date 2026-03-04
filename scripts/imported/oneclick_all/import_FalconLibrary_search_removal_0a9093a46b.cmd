@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeWebView" >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Services\UdkUserSvc" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
       takeown /F "%%~S" >nul 2>&1
       icacls "%%~S" /grant administrators:F >nul 2>&1
       del "%%~S" /s /f /q >nul 2>&1
endlocal
