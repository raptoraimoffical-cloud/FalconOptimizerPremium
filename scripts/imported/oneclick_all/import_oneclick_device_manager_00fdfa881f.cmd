@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
for /f "delims=" %%D in ('Powershell -NoProfile -Command "Get-PnpDevice | Select-Object -ExpandProperty FriendlyName"') do (
        Powershell -NoProfile -Command "try { Get-PnpDevice -FriendlyName '!Device[%%i]!' -ErrorAction Stop | Disable-PnpDevice -Confirm:$false -ErrorAction Stop; exit 0 } catch { exit 1 }"
endlocal
