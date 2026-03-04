:: Made by Falcon
:: TikTok: _Falcon_
:: Discord: https://discord.gg/8NqDSMzYun

:: Start Log.
echo [%DATE% %TIME%] Task Destroyer V1.3: Successfully started. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"

:: Creating Reg Backup.
echo [%DATE% %TIME%] Task Destroyer: Creating TaskSchedulerBackup.reg >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree" "C:\FalconLibrary Tools\Task Destroyer\Reg Backup\TaskSchedulerBackup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Task Destroyer Reg Backup: Failed to create. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Task Destroyer Reg Backup: Created successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
)

:: Creating Task Backup.
echo [%DATE% %TIME%] Task Destroyer: Creating Task file backup. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
xcopy "C:\WINDOWS\System32\Tasks" "C:\FalconLibrary Tools\Task Destroyer\Task Backup\Tasks" /E /I /H /Y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] Task Destroyer: Task file backup failed to copy. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
) else ( 
    echo [%DATE% %TIME%] Task Destroyer: Task file backup copied successfully. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt" 
)

:: Delete All Task.
echo [%DATE% %TIME%] Task Destroyer: Deleting all task in Task Scheduler. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt" 
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskStateFlags" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache" /f >nul 2>&1

:: Delete System32 Task Folder.
echo [%DATE% %TIME%] Task Destroyer: Deleting System32 Task folder. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt" 
rd /s /q "C:\WINDOWS\System32\Tasks" >nul 2>&1

:: End Log.
echo [%DATE% %TIME%] Task Destroyer V1.3: Successfully Ended. >> "C:\FalconLibrary Logs\FalconLibrary Log.txt"
exit




