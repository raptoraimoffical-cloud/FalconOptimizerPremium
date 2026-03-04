:: Made by Falcon
:: TikTok: _Falcon_
:: Discord: https://discord.gg/8NqDSMzYun

:: Start Log.
echo [%DATE% %TIME%] Autologger Destroyer V1.0: Successfully started. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"

:: Creating Autologger Reg Backup.
reg export "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger" "C:\FalconLibrary Tools\Autologger Destroyer\Reg Backup\AutologgerBackup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Autologger Destroyer Reg Key: Failed to create. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Autologger Destroyer Reg Key: Created successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Check for Windows Version.
setlocal enabledelayedexpansion
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild') do set CurrentBuild=%%A
if !CurrentBuild! GEQ 22000 (
   echo [%DATE% %TIME%] Autologger Destroyer Windows Version Check: Win 11+ >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else (
   echo [%DATE% %TIME%] Autologger Destroyer Windows Version Check: Win 10. - Disabling EventLog-Application and EventLog-System. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-Application" /v "Start" /t REG_DWORD /d "0" /f >nul 2>&1
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-System" /v "Start" /t REG_DWORD /d "0" /f >nul 2>&1
)
endlocal

:: Disable Autologgers
echo [%DATE% %TIME%] Autologger Destroyer: Disabling Autologgers. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
for %%A in (
    "Cellcore"
    "CimFSUnionFS-Filter"
    "Circular Kernel Context Logger"
    "CloudExperienceHostOobe" 
    "DefenderApiLogger" 
    "DefenderAuditLogger" 
    "DiagLog" 
    "Diagtrack-Listener"
    "EventLog-Security"
    "FilterMgr-Logger"
    "FaceTel" 
    "LwtNetLog" 
    "Mellanox-Kernel" 
    "Microsoft-Windows-Rdp-Graphics-RdpIdd-Trace" 
    "Microsoft-Windows-Setup" 
    "NBSMBLOGGER" 
    "NetCore" 
    "NtfsLog" 
    "PEAuthLog" 
    "RadioMgr" 
    "RdrLog" 
    "ReadyBoot" 
    "ReFSLog" 
    "SetupPlatform" 
    "SetupPlatformTel" 
    "SpoolerLogger" 
    "SQMLogger" 
    "TCPIPLOGGER" 
    "TileStore" 
    "UBPM" 
    "WdiContextLog" 
    "WFP-IPsec Trace" 
    "WiFiDriverIHVSession" 
    "WiFiDriverIHVSessionRepro" 
    "WiFiSession" 
    "WMI_Traces" 
) do (
    reg query "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~A" >nul 2>&1
    if not errorlevel 1 (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~A" /v "Start" /t REG_DWORD /d "0" /f >nul 2>&1
        echo [%DATE% %TIME%] Autologger Destroyer: Disabled %%~A. >> "C:\FalconLibrary Logs\Extra\Autologger Destroyer Log.txt"
    )
)

:: End Log.
echo [%DATE% %TIME%] Autologger Destroyer V1.0: Successfully Ended. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
exit

