@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0\..\.."
echo [Falcon] Running imported tweak: Setup_Restore_Point
echo.
color A
chcp 65001 >nul 2>&1
echo. 
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SystemRestore" /v "DisableConfig" /f >nul 2>&1
echo.
sc config VSS start=demand >nul 2>&1
sc config swprv start=demand >nul 2>&1
echo.
chcp 437 >nul
Powershell -NoProfile -Command "try { $ErrorActionPreference='Stop'; Enable-ComputerRestore -Drive '%SystemDrive%\' ; exit 0 } catch { exit 1 }" >nul 2>&1
set "SP_Error=%ERRORLEVEL%"
chcp 65001 >nul
if %SP_Error% neq 0 (
    goto :Restore_Failure
) else (
    goto :Create_Restore_Point
)
echo.
echo [Falcon] Done.
endlocal
exit /b 0