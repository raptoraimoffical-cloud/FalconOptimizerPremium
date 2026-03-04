@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild') do set CurrentBuild=%%A
endlocal
