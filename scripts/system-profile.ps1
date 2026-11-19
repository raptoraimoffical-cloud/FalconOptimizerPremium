<#
  Collects hardware + configuration facts as JSON for the catalog (applicability) and the
  dashboard health checks. Read-only. Works unelevated (a few fields need admin: bcd).
#>
$ErrorActionPreference = 'SilentlyContinue'

function Try-Get([scriptblock]$sb, $default = $null) { try { $v = & $sb; if ($null -eq $v) { $default } else { $v } } catch { $default } }

$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

# ---- GPUs (Win32_VideoController.AdapterRAM caps at 4 GB; use the driver's qwMemorySize instead)
$gpus = @()
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
foreach ($vc in Get-CimInstance Win32_VideoController) {
  if (-not $vc.PNPDeviceID -or $vc.PNPDeviceID -notmatch '^PCI\\') { continue }
  $vram = $null
  foreach ($k in Get-ChildItem $classKey -ErrorAction SilentlyContinue) {
    $p = Get-ItemProperty $k.PSPath
    if ($p.MatchingDeviceId -and $vc.PNPDeviceID -like ("*" + ($p.MatchingDeviceId -replace '^pci\\', '') + "*")) {
      if ($p.'HardwareInformation.qwMemorySize') { $vram = [math]::Round([double]$p.'HardwareInformation.qwMemorySize' / 1GB) }
    }
  }
  if (-not $vram -and $vc.AdapterRAM) { $vram = [math]::Round($vc.AdapterRAM / 1GB) }
  $msi = Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Enum\{0}\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" -f $vc.PNPDeviceID)
  $gpus += [pscustomobject]@{
    name = $vc.Name
    pnp = $vc.PNPDeviceID
    driverVersion = $vc.DriverVersion
    driverDate = $(if ($vc.DriverDate) { $vc.DriverDate.ToString('yyyy-MM-dd') } else { $null })
    vramGb = $vram
    refreshHz = $vc.CurrentRefreshRate
    maxRefreshHz = $vc.MaxRefreshRate
    resolution = $(if ($vc.CurrentHorizontalResolution) { "$($vc.CurrentHorizontalResolution)x$($vc.CurrentVerticalResolution)" } else { $null })
    msi = $(if ($msi -and $null -ne $msi.MSISupported) { [int]$msi.MSISupported } else { $null })
  }
}

# ---- Displays: real per-monitor refresh capabilities via EnumDisplaySettings (done in C# so
# struct marshalling never goes through PowerShell [ref] boxing).
$displays = @()
try {
  if (-not ('FalconDisplays' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class FalconDisplays {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
    public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra; public int dmFields;
    public int dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
    public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
    public short dmLogPixels; public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
    public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
  }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct DISPLAY_DEVICE {
    public int cb;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
    public int StateFlags;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
  }
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplayDevicesW(string dev, int i, ref DISPLAY_DEVICE dd, int flags);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplaySettingsW(string dev, int mode, ref DEVMODE dm);

  // Each entry: device|adapter|width|height|currentHz|maxHzAtCurrentResolution|primary
  public static string[] List() {
    var res = new List<string>();
    for (int i = 0; i < 16; i++) {
      var dd = new DISPLAY_DEVICE(); dd.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
      if (!EnumDisplayDevicesW(null, i, ref dd, 0)) break;
      if ((dd.StateFlags & 1) == 0) continue;
      var dm = new DEVMODE(); dm.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
      if (!EnumDisplaySettingsW(dd.DeviceName, -1, ref dm)) continue;
      int w = dm.dmPelsWidth, h = dm.dmPelsHeight, cur = dm.dmDisplayFrequency, best = cur;
      for (int j = 0; j < 4000; j++) {
        var m = new DEVMODE(); m.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        if (!EnumDisplaySettingsW(dd.DeviceName, j, ref m)) break;
        if (m.dmPelsWidth == w && m.dmPelsHeight == h && m.dmDisplayFrequency > best) best = m.dmDisplayFrequency;
      }
      res.Add(string.Join("|", new string[] { dd.DeviceName, dd.DeviceString, w.ToString(), h.ToString(), cur.ToString(), best.ToString(), ((dd.StateFlags & 4) != 0).ToString() }));
    }
    return res.ToArray();
  }
}
'@
  }
  foreach ($line in [FalconDisplays]::List()) {
    $f = $line.Split('|')
    $displays += [pscustomobject]@{ device = $f[0]; adapter = $f[1]; resolution = "$($f[2])x$($f[3])"; refreshHz = [int]$f[4]; maxRefreshHz = [int]$f[5]; primary = ($f[6] -eq 'True') }
  }
} catch {}

# ---- RAM
$dimms = @(Get-CimInstance Win32_PhysicalMemory)
$ramSpeed = ($dimms | Measure-Object -Property Speed -Maximum).Maximum
$ramConfigured = ($dimms | Measure-Object -Property ConfiguredClockSpeed -Maximum).Maximum

# ---- Security state
$dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard
$vbsRunning = ($dg -and $dg.VirtualizationBasedSecurityStatus -eq 2)
$hvciRunning = ($dg -and @($dg.SecurityServicesRunning) -contains 2)
$secureBoot = Try-Get { Confirm-SecureBootUEFI } $null

# ---- Misc state
$hags = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers').HwSchMode
$gameMode = (Get-ItemProperty 'HKCU:\Software\Microsoft\GameBar').AutoGameModeEnabled
$dvr = (Get-ItemProperty 'HKCU:\System\GameConfigStore').GameDVR_Enabled
$mouse = Get-ItemProperty 'HKCU:\Control Panel\Mouse'
$scheme = (& powercfg.exe /getactivescheme) | Out-String
$schemeName = $(if ($scheme -match '\((.+)\)') { $Matches[1] } else { $null })
$schemeGuid = $(if ($scheme -match '([0-9a-fA-F-]{36})') { $Matches[1] } else { $null })
$bcdRaw = (& bcdedit.exe /enum '{current}' 2>$null) | Out-String
$bcdReadable = ($LASTEXITCODE -eq 0)
$pf = Get-CimInstance Win32_PageFileUsage
$sysDrive = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $env:SystemDrive)
$adapters = @(Get-NetAdapter -Physical | Where-Object { $_.Status -ne 'Not Present' })
$isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$x3dDriver = [bool](Get-Service -Name 'amd3dvcache' -ErrorAction SilentlyContinue)

# NVIDIA Resizable BAR: BAR1 aperture equal to VRAM means ReBAR is active.
$rebar = $null
$smi = Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'
if (Test-Path $smi) {
  $q = (& $smi -q -d MEMORY 2>$null) | Out-String
  if ($q -match 'FB Memory Usage\s+Total\s*:\s*(\d+)' ) { $fb = [int]$Matches[1] }
  if ($q -match 'BAR1 Memory Usage\s+Total\s*:\s*(\d+)') { $bar = [int]$Matches[1] }
  if ($fb -and $bar) { $rebar = ($bar -ge ($fb * 0.9)) }
}

$cpuName = ([string]$cpu.Name).Trim()
[pscustomobject]@{
  collectedAt = (Get-Date).ToString('s')
  isAdmin = $isAdmin
  os = [pscustomobject]@{
    caption = $os.Caption
    build = [int]$cv.CurrentBuildNumber
    ubr = [int]$cv.UBR
    displayVersion = $cv.DisplayVersion
    edition = $cv.EditionID
  }
  # PCSystemType 2 = mobile; chassis types 8-14/30-32 = portable/laptop/notebook/tablet.
  # (Win32_Battery alone is unreliable: a desktop on a USB UPS reports a battery.)
  formFactor = $(if ($cs.PCSystemType -eq 2 -or (@((Get-CimInstance Win32_SystemEnclosure).ChassisTypes) | Where-Object { $_ -in 8, 9, 10, 11, 12, 14, 30, 31, 32 })) { 'laptop' } else { 'desktop' })
  cpu = [pscustomobject]@{
    name = $cpuName
    vendor = $(if ($cpuName -match 'Intel') { 'intel' } elseif ($cpuName -match 'AMD|Ryzen') { 'amd' } else { 'unknown' })
    cores = [int]$cpu.NumberOfCores
    threads = [int]$cpu.NumberOfLogicalProcessors
    x3d = ($cpuName -match 'X3D')
    x3dDual = ($cpuName -match '(7900|7950|9900|9950)X3D')
    hybrid = ($cpuName -match 'i[3579]-1[2-4]\d{3}|Core\(TM\) Ultra|Core Ultra')
    x3dDriver = $x3dDriver
    maxClockMHz = [int]$cpu.MaxClockSpeed
  }
  gpus = $gpus
  displays = $displays
  ram = [pscustomobject]@{
    totalGb = [math]::Round($cs.TotalPhysicalMemory / 1GB)
    modules = $dimms.Count
    ratedMTs = $ramSpeed
    configuredMTs = $ramConfigured
  }
  state = [pscustomobject]@{
    vbsRunning = $vbsRunning
    hvciRunning = $hvciRunning
    secureBoot = $secureBoot
    hags = $hags
    gameMode = $gameMode
    gameDvr = $dvr
    mouseAccel = ([string]$mouse.MouseSpeed -ne '0')
    powerPlan = $schemeName
    powerPlanGuid = $schemeGuid
    bcdReadable = $bcdReadable
    forcedPlatformClock = ($bcdReadable -and $bcdRaw -match '(?im)^useplatformclock\s+(yes|true|on)')
    pagefileMb = $(if ($pf) { ($pf | Measure-Object -Property AllocatedBaseSize -Sum).Sum } else { 0 })
    systemDriveFreeGb = $(if ($sysDrive) { [math]::Round($sysDrive.FreeSpace / 1GB) } else { $null })
    resizableBar = $rebar
  }
  net = [pscustomobject]@{
    hasWifi = [bool]($adapters | Where-Object { $_.PhysicalMediaType -match '802\.11' })
    wiredUp = [bool]($adapters | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -match '802\.3' })
    wifiUp = [bool]($adapters | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -match '802\.11' })
  }
} | ConvertTo-Json -Depth 5 -Compress
