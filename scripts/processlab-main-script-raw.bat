@echo off

cd %systemroot%\system32
call :IsAdmin


Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
Reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground_UserInControlOfTheseApps" /f
Reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground_ForceAllowTheseApps" /f
Reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground_ForceDenyTheseApps" /f
cls


reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "4294967295" /f
cls

echo "Disabling Font Cache"
sc config fontcache start=disabled
sc config fontcache3.0.0.0 start=disabled
cls

sc config dps start=disabled
sc config wdisystemhost start=disabled
sc config wdiservicehost start=disabled
sc config diagtrack start=disabled
sc config dssvc start=disabled
sc config dusmsvc start=disabled
sc config diagsvc start=disabled
sc config telemetry start=disabled
sc config diagnosticshub.standardcollector.service start=disabled
sc config ndu start=disabled
cls

echo "Disabling Themes"
sc config themes start=disabled
cls

echo "Disabling Program Compatibility Assistant"
sc config pcasvc start=disabled
cls

echo "Disabling Sensors"
sc config sensrsvc start=disabled
sc config sensordataservice start=disabled
sc config sensorservice start=disabled
cls

echo "Disabling Smart Card"
sc config scardsvr start=disabled
sc config scdeviceenum start=disabled
sc config scpolicysvc start=disabled
cls

echo "Disabling Virtualization Services"
sc config uevagentservice start=disabled
sc config uevagentdriver start=disabled
sc config appvclient start=disabled
cls

echo "Disabling Autoplay"
sc config shellhwdetection start=disabled
cls

echo "Disabling Beep"
sc config beep start=disabled
cls

echo "Services has been disabled, please reboot your system."
pause

:IsAdmin
Reg.exe query "HKU\S-1-5-19\Environment"
If Not %ERRORLEVEL% EQU 0 (
 Cls & Echo You must have administrator rights to continue ... 
 Pause & Exit
)
Cls
goto:eof
