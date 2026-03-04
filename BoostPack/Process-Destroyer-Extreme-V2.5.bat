:: Made by Quaked
:: TikTok: _Quaked_
:: Discord: https://discord.gg/8NqDSMzYun

@echo off
title Process Destroyer Extreme V2.5
color B

:: Creating PD Extreme Services Reg Backup.
reg export "HKLM\System\CurrentControlSet\Services" "C:\Oneclick Tools\Process Destroyer\Revert\Services_Backup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] PD Extreme Services Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] PD Extreme Services Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Creating TrustedInstaller Reg Backup.
reg export "HKLM\System\CurrentControlSet\Services\TrustedInstaller" "C:\Oneclick Tools\Process Destroyer\Revert\Trusted_Installer_Backup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] PD Extreme TrustedInstaller Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] PD Extreme TrustedInstaller Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Creating Windows Installer Reg Backup.
reg export "HKLM\System\CurrentControlSet\Services\msiserver" "C:\Oneclick Tools\Process Destroyer\Revert\Windows_Installer_Backup.reg" /y >nul 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] PD Extreme Windows Installer Reg Backup: Failed to create. >> "C:\Oneclick Logs\Oneclick Log.txt"
) else ( 
    echo [%DATE% %TIME%] PD Extreme Windows Installer Reg Backup: Created successfully. >> "C:\Oneclick Logs\Oneclick Log.txt"
)

:: Process Destroyer Extreme GUI.
cls
chcp 65001 >nul 2>&1
echo ╔═══════════════════════════════════════╗
echo ║ ✅ Running Process Destroyer Extreme. ║
echo ╚═══════════════════════════════════════╝
setlocal enabledelayedexpansion
timeout 2 > nul

:: Count Variables.
set "FoundCount=0"
set "NotFoundCount=0"
set "DeleteCount=0"

:: Windows Services.
set "svc1=AarSvc"
set "svc2=ADPSvc"
set "svc3=AJRouter"
set "svc4=ALG"
set "svc5=AppIDSvc"
set "svc6=AppInfo"
set "svc7=AppMgmt"
set "svc8=AppReadiness"
set "svc9=AppXSvc"
set "svc10=AssignedAccessManagerSvc"
set "svc11=autotimesvc"
set "svc12=AxInstSV"
set "svc13=BcastDVRUserService"
set "svc14=BDESVC"
set "svc15=BFE"
set "svc16=BITS"
set "svc17=BluetoothUserService"
set "svc18=BTAGService"
set "svc19=BthAvctpSvc"
set "svc20=bthserv"
set "svc21=CaptureService"
set "svc22=cbdhsvc"
set "svc23=CDPUserSvc"
set "svc24=CDPSvc"
set "svc25=CertPropSvc"
set "svc26=ClipSVC"
set "svc27=CloudBackupRestoreSvc"
set "svc28=cloudidsvc"
set "svc29=COMSysApp"
set "svc30=ConsentUxUserSvc"
set "svc31=CredentialEnrollmentManagerUserSvc"
set "svc32=CscService"
set "svc33=dcsvc"
set "svc34=defragsvc"
set "svc35=DeviceAssociationBrokerSvc"
set "svc36=DeviceAssociationService"
set "svc37=DevicePickerUserSvc"
set "svc38=DevicesFlowUserSvc"
set "svc39=DevQueryBroker"
set "svc40=diagnosticshub.standardcollector.service"
set "svc41=DiagTrack"
set "svc42=diagsvc"
set "svc43=DisplayEnhancementService"
set "svc44=DmEnrollmentSvc"
set "svc45=dmwappushservice"
set "svc46=DoSvc"
set "svc47=dot3svc"
set "svc48=DPS"
set "svc49=DsmSvc"
set "svc50=DsSvc"
set "svc51=DusmSvc"
set "svc52=Eaphost"
set "svc53=EFS"
set "svc54=embeddedmode"
set "svc55=EntAppSvc"
set "svc56=EventLog"
set "svc57=EventSystem"
set "svc58=fdPHost"
set "svc59=FDResPub"
set "svc60=fhsvc"
set "svc61=FontCache"
set "svc62=FrameServer"
set "svc63=FrameServerMonitor"
set "svc64=GameInputSvc"
set "svc65=GraphicsPerfSvc"
set "svc66=gpsvc"
set "svc67=hidserv"
set "svc68=hpatchmon"
set "svc69=HvHost"
set "svc70=icssvc"
set "svc71=IKEEXT"
set "svc72=InstallService"
set "svc73=InventorySvc"
set "svc74=iphlpsvc"
set "svc75=IpxlatCfgSvc"
set "svc76=Keyiso"
set "svc77=KtmRm"
set "svc78=LanmanServer"
set "svc79=LanmanWorkstation"
set "svc80=lfsvc"
set "svc81=LocalKdc"
set "svc82=LicenseManager"
set "svc83=lltdsvc"
set "svc84=lmhosts"
set "svc85=LxpSvc"
set "svc86=MapsBroker"
set "svc87=McpManagementService"
set "svc88=McmSvc"
set "svc89=MessagingService"
set "svc90=midisrv"
set "svc91=MDCoreSvc"
set "svc92=mpssvc"
set "svc93=MSDTC"
set "svc94=MSiSCSI"
set "svc95=msiserver"
set "svc96=NaturalAuthentication"
set "svc97=NcaSvc"
set "svc98=NcbService"
set "svc99=NcdAutoSetup"
set "svc100=Netlogon"
set "svc101=Netman"
set "svc102=NetSetupSvc"
set "svc103=NetTcpPortSharing"
set "svc104=NgcCtnrSvc"
set "svc105=NgcSvc"
set "svc106=NlaSvc"
set "svc107=NPSMSvc"
set "svc108=OneSyncSvc"
set "svc109=p2pimsvc"
set "svc110=p2psvc"
set "svc111=P9RdrService"
set "svc112=PcaSvc"
set "svc113=PeerDistSvc"
set "svc114=PenService"
set "svc115=perceptionsimulation"
set "svc116=PerfHost"
set "svc117=PhoneSvc"
set "svc118=PimIndexMaintenanceSvc"
set "svc119=pla"
set "svc120=PlugPlay"
set "svc121=PNRPAutoReg"
set "svc122=PNRPsvc"
set "svc123=PrintDeviceConfigurationService"
set "svc124=PrintNotify"
set "svc125=PrintScanBrokerService"
set "svc126=PrintWorkflowUserSvc"
set "svc127=PushToInstall"
set "svc128=QWAVE"
set "svc129=RasAuto"
set "svc130=RasMan"
set "svc131=refsdedupsvc"
set "svc132=RemoteAccess"
set "svc133=RemoteRegistry"
set "svc134=RetailDemo"
set "svc135=RmSvc"
set "svc136=RpcLocator"
set "svc137=SamSs"
set "svc138=SCardSvr"
set "svc139=ScDeviceEnum"
set "svc140=SCPolicySvc"
set "svc141=SDRSVC"
set "svc142=Schedule"
set "svc143=seclogon"
set "svc144=SecurityHealthService"
set "svc145=SENS"
set "svc146=Sense"
set "svc147=SensorDataService"
set "svc148=SensorService"
set "svc149=SensrSvc"
set "svc150=SEMgrSvc"
set "svc151=SessionEnv"
set "svc152=SgrmBroker"
set "svc153=SharedRealitySvc"
set "svc154=ShellHWDetection"
set "svc155=shpamsvc"
set "svc156=SmsRouter"
set "svc157=smphost"
set "svc158=SNMPTrap"
set "svc159=Spooler"
set "svc160=SSDPSRV"
set "svc161=ssh-agent"
set "svc162=SstpSvc"
set "svc163=stisvc"
set "svc164=StorSvc"
set "svc165=svsvc"
set "svc166=SystemEventsBroker"
set "svc167=SysMain"
set "svc168=TapiSrv"
set "svc169=TermService"
set "svc170=Themes"
set "svc171=TieringEngineService"
set "svc172=TimeBrokerSvc"
set "svc173=TokenBroker"
set "svc174=TrkWks"
set "svc175=TroubleshootingSvc"
set "svc176=TrustedInstaller"
set "svc177=tzautoupdate"
set "svc178=UdkUserSvc"
set "svc179=UevAgentService"
set "svc180=uhssvc"
set "svc181=UmRdpService"
set "svc182=UnistoreSvc"
set "svc183=upnphost"
set "svc184=UserDataSvc"
set "svc185=VacSvc"
set "svc186=VaultSvc"
set "svc187=vds"
set "svc188=vmicguestinterface"
set "svc189=vmicheartbeat"
set "svc190=vmickvpexchange"
set "svc191=vmicrdv"
set "svc192=vmicshutdown"
set "svc193=vmictimesync"
set "svc194=vmicvmsession"
set "svc195=vmicvss"
set "svc196=W32Time"
set "svc197=WalletService"
set "svc198=WarpJITSvc"
set "svc199=wbengine"
set "svc200=WbioSrvc"
set "svc201=Wcmsvc"
set "svc202=wcncsvc"
set "svc203=WdNisSvc"
set "svc204=WdiServiceHost"
set "svc205=WdiSystemHost"
set "svc206=WebClient"
set "svc207=webthreatdefusersvc"
set "svc208=webthreatdefsvc"
set "svc209=Wecsvc"
set "svc210=WEPHOSTSVC"
set "svc211=wercplsupport"
set "svc212=WerSvc"
set "svc213=WFDSConMgrSvc"
set "svc214=whesvc"
set "svc215=WiaRpc"
set "svc216=WinDefend"
set "svc217=WinHttpAutoProxySvc"
set "svc218=WinRM"
set "svc219=wisvc"
set "svc220=WlanSvc"
set "svc221=wlidsvc"
set "svc222=wlpasvc"
set "svc223=WManSvc"
set "svc224=wmiApSrv"
set "svc225=WMPNetworkSvc"
set "svc226=workfolderssvc"
set "svc227=WpcMonSvc"
set "svc228=WPDBusEnum"
set "svc229=WpnUserService"
set "svc230=WpnService"
set "svc231=wuqisvc"
set "svc232=WSAIFabricSvc"
set "svc233=wscsvc"
set "svc234=WSearch"
set "svc235=WwanSvc"
set "svc236=XblAuthManager"
set "svc237=XblGameSave"
set "svc238=XboxGipSvc"
set "svc239=XboxNetApiSvc"

:: Service Delete Loop.
for /L %%i in (1,1,239) do (
    set "svc=!svc%%i!"
    reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" >nul 2>&1
    if !errorlevel! equ 0 (
        set /A "FoundCount+=1"
        echo [%DATE% %TIME%] !FoundCount!: Found !svc!. >> "C:\Oneclick Logs\Extra\Process Destroyer Extreme Log.txt"
        echo ✔  Deleting !svc!.
        reg delete "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /f >nul 2>&1
        reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" >nul 2>&1
        if !errorlevel! equ 0 (
            set /A "DeleteCount+=1"
            echo [%DATE% %TIME%] !DeleteCount!: Failed to delete !svc!. >> "C:\Oneclick Logs\Extra\Process Destroyer Extreme Log.txt"
        ) else (
            set /A "DeleteCount+=1"
            echo [%DATE% %TIME%] !DeleteCount!: Successfully deleted !svc!. >> "C:\Oneclick Logs\Extra\Process Destroyer Extreme Log.txt"
        )
    ) else (
        set /A "NotFoundCount+=1"
        echo [%DATE% %TIME%] !NotFoundCount!: !svc! not found. >> "C:\Oneclick Logs\Extra\Process Destroyer Extreme Log.txt"
    )
)

:: Set Software Protection to Manual.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc" /v "Start" /t REG_DWORD /d "3" /f >nul 2>&1

:: Removing Mpssvc and PolicyAgent. (SC Config, need to disable these services and mpssvc may not delete)
sc delete mpssvc >nul 2>&1
sc delete PolicyAgent >nul 2>&1
sc delete SharedAccess >nul 2>&1

:: Rename Ctfmon, BackgroundTaskHost, and TextInputHost.
taskkill /f /im ctfmon.exe >nul 2>&1
REN "C:\Windows\System32\ctfmon.exe" "ctfmon.exee" >nul 2>&1
taskkill /f /im backgroundTaskHost.exe >nul 2>&1
REN "C:\Windows\System32\backgroundTaskHost.exe" "backgroundTaskHost.exee" >nul 2>&1
taskkill /f /im TextInputHost.exe >nul 2>&1
REN "C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TextInputHost.exe" "TextInputHost.exee" >nul 2>&1

:: Close.
echo ✔  Closing in 3 seconds...
timeout 3 > nul
exit
