@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg export "%~1" "%Oneclick_Backup_Folder%\Network\NetworkBackup%NetworkBackupCounter%.reg" /y >nul 2>&1
endlocal
