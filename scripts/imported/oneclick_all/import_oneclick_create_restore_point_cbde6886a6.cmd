@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
Powershell -NoProfile -Command "try { $ProgressPreference='SilentlyContinue'; $ErrorActionPreference='Stop'; Checkpoint-Computer -Description 'Oneclick V8.3 Restore Point'; exit 0 } catch { exit 1 }" >nul 2>&1
endlocal
