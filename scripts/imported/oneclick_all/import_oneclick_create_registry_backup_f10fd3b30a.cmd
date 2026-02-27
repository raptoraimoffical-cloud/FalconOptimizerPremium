@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    reg export "%%R" "%Oneclick_Backup_Folder%\Registry\%%R.reg" /y >nul 2>&1
endlocal
