@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
Powershell -NoProfile -Command ^
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowershellV2 -NoRestart -ErrorAction SilentlyContinue; ^
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowershellV2Root -NoRestart -ErrorAction SilentlyContinue; ^
endlocal
