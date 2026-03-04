:: Made by Falcon
:: TikTok: _Falcon_
:: Discord: https://discord.gg/8NqDSMzYun
:: Windows Updates Information: https://github.com/FalconK/Scripting-Station/blob/main/System%20Docs/Windows%20Updates.md

:: Start Log.
echo [%DATE% %TIME%] Update Disabler V1.2: Successfully started. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"

:: Creating Update Policy Reg Backup.
reg export "HKLM\SOFTWARE\Microsoft\WindowsUpdate" "C:\FalconLibrary Tools\Update Disabler\Reg Backup\PolicyBackup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler Reg Policy Backup: Failed to create. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler Reg Policy Backup: Created successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating Windows Update Service Backup.
reg export "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" "C:\FalconLibrary Tools\Update Disabler\Reg Backup\WindowsUpdateServiceBackup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler Service Backup #1: Failed to create. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler Service Backup #1: Created successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating Update Orchestrator Service Backup.
reg export "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" "C:\FalconLibrary Tools\Update Disabler\Reg Backup\UpdateOrchestratorServiceBackup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler Service Backup #2: Failed to create. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler Service Backup #2: Created successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating Windows Update Medic Service Backup.
reg export "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" "C:\FalconLibrary Tools\Update Disabler\Reg Backup\WindowsUpdateMedicServiceBackup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler Service Backup #3: Failed to create. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler Service Backup #3: Created successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating Regular MoUsoCoreWorker.exe Backup.
copy "C:\Windows\UUS\amd64\MoUsoCoreWorker.exe" "C:\FalconLibrary Tools\Update Disabler\File Backup" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler File Backup #1: Failed to copy. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler File Backup #1: Copied successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating Preview MoUsoCoreWorker.exe Backup.
copy "C:\Windows\UUS\Packages\Preview\amd64\MoUsoCoreWorker.exe" "C:\FalconLibrary Tools\Update Disabler\File Backup\Extra" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler File Backup #2: Failed to copy. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler File Backup #2: Copied successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating UsoClient.exe Backup.
copy "C:\Windows\System32\UsoClient.exe" "C:\FalconLibrary Tools\Update Disabler\File Backup" >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Update Disabler File Backup #3: Failed to copy. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Update Disabler File Backup #3: Copied successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Deleting Update Services.
echo [%DATE% %TIME%] Update Disabler: Deleting Update Services. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
sc delete "wuauserv" >nul 2>&1
sc delete "WaaSMedicSvc" >nul 2>&1
sc delete "UsoSvc" >nul 2>&1 

:: Delete Update Files.
echo [%DATE% %TIME%] Update Disabler: Deleting Update Files. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
del "C:\Windows\UUS\amd64\MoUsoCoreWorker.exe" /s /f /q >nul 2>&1
del "C:\Windows\UUS\Packages\Preview\amd64\MoUsoCoreWorker.exe" /s /f /q >nul 2>&1
del "C:\Windows\System32\UsoClient.exe" /s /f /q >nul 2>&1

:: Defer Updates.
echo [%DATE% %TIME%] Update Disabler: Deferring Updates. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferUpdatePeriod" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferUpgrade" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferUpgradePeriod" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d "1" /f >nul 2>&1

:: Permanently Pausing Updates.
echo [%DATE% %TIME%] Update Disabler: Pausing Updates. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v PausedFeatureStatus /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v PausedQualityStatus /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v FlightSettingsMaxPauseDays /t REG_DWORD /d 3650 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseFeatureUpdatesEndTime /t REG_SZ /d "3000-11-06T14:03:37Z" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseFeatureUpdatesStartTime /t REG_SZ /d "2023-11-06T14:03:37Z" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseQualityUpdatesEndTime /t REG_SZ /d "3000-11-06T14:03:37Z" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseQualityUpdatesStartTime /t REG_SZ /d "2023-11-06T14:03:37Z" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseUpdatesExpiryTime /t REG_SZ /d "3000-11-06T14:03:37Z" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v PauseUpdatesStartTime /t REG_SZ /d "2023-11-06T14:03:37Z" /f >nul 2>&1

:: End Log.
echo [%DATE% %TIME%] Update Disabler V1.2: Successfully Ended. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
exit