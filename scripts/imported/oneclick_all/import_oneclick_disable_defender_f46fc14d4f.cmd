@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
    Powershell -NoProfile -Command "Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue"
    start "" "https://github.com/QuakedK/Oneclick/blob/main/Help/Windows%%20Defender%%20Options.md"
    Powershell -NoProfile -Command "Write-Host 'Invalid choice, Please choose options 1-3.' -ForegroundColor White -BackgroundColor Red"
endlocal
