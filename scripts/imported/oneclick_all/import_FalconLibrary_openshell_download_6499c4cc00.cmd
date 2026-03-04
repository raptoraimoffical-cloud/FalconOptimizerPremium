@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
   start "" "C:\Oneclick Tools\OpenShell\OpenShellSetup_4_4_196.exe" /qn ADDLOCAL=StartMenu
   rd /s /q "C:\Oneclick Tools\OpenShell" >nul 2>&1
endlocal
