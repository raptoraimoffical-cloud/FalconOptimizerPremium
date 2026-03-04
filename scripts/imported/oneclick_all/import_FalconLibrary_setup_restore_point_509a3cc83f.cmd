@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SystemRestore" /v "DisableConfig" /f >nul 2>&1
sc config VSS start=demand >nul 2>&1
sc config swprv start=demand >nul 2>&1
Powershell -NoProfile -Command "try { $ErrorActionPreference='Stop'; Enable-ComputerRestore -Drive '%SystemDrive%\' ; exit 0 } catch { exit 1 }" >nul 2>&1
endlocal
