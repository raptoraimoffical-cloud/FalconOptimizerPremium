@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Imported tweak
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s ^| findstr "HKEY"') do (
    for /f %%i in ('reg query "%%a" /v "*ReceiveBuffers" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*ReceiveBuffers" /t REG_SZ /d "2048" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TransmitBuffers" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TransmitBuffers" /t REG_SZ /d "1024" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnablePME" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePME" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*DeviceSleepOnDisconnect" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*DeviceSleepOnDisconnect" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*EEE" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*EEE" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*ModernStandbyWoLMagicPacket" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*ModernStandbyWoLMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*SelectiveSuspend" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*SelectiveSuspend" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*WakeOnMagicPacket" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*WakeOnMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*WakeOnPattern" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*WakeOnPattern" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "AutoPowerSaveModeEnabled" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EEELinkAdvertisement" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EEELinkAdvertisement" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EeePhyEnable" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EeePhyEnable" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnableGreenEthernet" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnableModernStandby" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableModernStandby" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "GigaLite" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "GigaLite" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "PnPCapabilities" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "PnPCapabilities" /t REG_DWORD /d "24" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "PowerDownPll" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "PowerDownPll" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "PowerSavingMode" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "PowerSavingMode" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "ReduceSpeedOnPowerDown" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "S5WakeOnLan" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "S5WakeOnLan" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "SavePowerNowEnabled" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "SavePowerNowEnabled" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "ULPMode" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ULPMode" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeOnLink" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOnLink" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeOnSlot" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOnSlot" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeUpModeCap" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeUpModeCap" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WaitAutoNegComplete" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WaitAutoNegComplete" /t REG_SZ /d "0" /f
    for /f %%i in ('reg query "%%a" /v "*FlowControl" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*FlowControl" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WolShutdownLinkSpeed" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeOnMagicPacketFromS5" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOnMagicPacketFromS5" /t REG_SZ /d "2" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*PMNSOffload" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*PMNSOffload" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*PMARPOffload" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*PMARPOffload" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*NicAutoPowerSaver" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*NicAutoPowerSaver" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*PMWiFiRekeyOffload" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*PMWiFiRekeyOffload" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnablePowerManagement" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePowerManagement" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "ForceWakeFromMagicPacketOnModernStandby" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ForceWakeFromMagicPacketOnModernStandby" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeFromS5" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeFromS5" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeOn" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeOn" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "OBFFEnabled" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "OBFFEnabled" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "DMACoalescing" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "DMACoalescing" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnableSavePowerNow" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnableD0PHYFlexibleSpeed" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableD0PHYFlexibleSpeed" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnablePHYWakeUp" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePHYWakeUp" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnablePHYFlexibleSpeed" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnablePHYFlexibleSpeed" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "AllowAllSpeedsLPLU" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "AllowAllSpeedsLPLU" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*EnableDynamicPowerGating" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*EnableDynamicPowerGating" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnableD3ColdInS0" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableD3ColdInS0" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "LatencyToleranceReporting" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "LatencyToleranceReporting" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "EnableAspm" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "EnableAspm" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "LTROBFF" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "LTROBFF" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "S0MgcPkt" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "S0MgcPkt" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TCPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TCPChecksumOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TCPConnectionOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPConnectionOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TCPConnectionOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPConnectionOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TCPUDPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPUDPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*TCPUDPChecksumOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*TCPUDPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*UDPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UDPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*UDPChecksumOffloadIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UDPChecksumOffloadIPv6" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*UdpRsc" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UdpRsc" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*UsoIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UsoIPv4" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*UsoIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*UsoIPv6" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*RscIPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*RscIPv6" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*RscIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*RscIPv4" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*IPsecOffloadV2IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPsecOffloadV2IPv4" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*IPsecOffloadV2" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPsecOffloadV2" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*IPsecOffloadV1IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPsecOffloadV1IPv4" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*LsoV1IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*LsoV1IPv4" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*LsoV2IPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*LsoV2IPv4" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*LsoV2IPv6" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*LsoV2IPv6" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*IPChecksumOffloadIPv4" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*IPChecksumOffloadIPv4" /t REG_SZ /d "3" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "WakeFromPowerOff" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "WakeFromPowerOff" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "LogLinkStateEvent" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "LogLinkStateEvent" /t REG_SZ /d "16" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "*InterruptModeration" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "*InterruptModeration" /t REG_SZ /d "0" /f >nul 2>&1
    for /f %%i in ('reg query "%%a" /v "ITR" 2^>nul ^| findstr "HKEY"') do (
        reg add "%%i" /v "ITR" /t REG_SZ /d "0" /f >nul 2>&1
endlocal
