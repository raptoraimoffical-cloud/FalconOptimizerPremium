@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
endlocal
