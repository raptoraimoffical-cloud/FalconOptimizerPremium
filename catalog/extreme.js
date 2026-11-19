'use strict';
/**
 * Extreme tier: strips Windows down for people who want a dedicated gaming machine.
 * Every item here BREAKS something on purpose; `tradeoff` says exactly what. Nothing here is
 * applied by the Regular presets. All items are reversible from History > Undo all.
 */
const { R, regSet, regDel, service, ps } = require('./_steps');

const svcItem = (id, name, summary, details, tradeoff, services, opts = {}) => ({
  id, category: 'extreme', kind: 'toggle', tier: 'extreme', name, summary, details, tradeoff,
  impact: opts.impact || { latency: 0, fps: 1 }, tags: ['background'], evidence: 'mechanism',
  risk: opts.risk || 'moderate', presets: ['latency', 'fps'], reboot: 'reboot',
  // Revert falls back to these Windows defaults if the journal has no original.
  apply: services.map(([n]) => service(n, 'Disabled')),
  revert: services.map(([n, def]) => service(n, def))
});

const BLOAT = [
  'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.BingSearch', 'Microsoft.GetHelp',
  'Microsoft.Getstarted', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.People',
  'Microsoft.PowerAutomateDesktop', 'Microsoft.Todos', 'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsMaps',
  'Microsoft.ZuneVideo', 'MSTeams', 'MicrosoftTeams', 'Microsoft.OutlookForWindows', 'Microsoft.549981C3F5F10',
  'Microsoft.Copilot', 'Microsoft.Windows.DevHome', 'Microsoft.YourPhone', 'Microsoft.MicrosoftStickyNotes',
  'Microsoft.WindowsSoundRecorder', 'Microsoft.MixedReality.Portal', 'Microsoft.SkypeApp', 'king.com.CandyCrushSaga',
  'king.com.CandyCrushSodaSaga', 'SpotifyAB.SpotifyMusic', 'Disney.37853FA22FB0', 'BytedancePte.Ltd.TikTok'
];
const bloatList = `@(${BLOAT.map((b) => `'${b}'`).join(',')})`;

const UPDATE_UX = R`HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`;

module.exports = (ctx) => [
  svcItem('ext.services_strip', 'Disable non-essential Windows services',
    'Turns off 20 background services a gaming-only PC never needs.',
    'Disables: Print Spooler, Fax, diagnostics (DPS, WDI hosts, error reporting, compatibility assistant), Connected Devices Platform, distributed link tracking, Maps, geolocation, retail demo, wallet/payments, phone service, mobile hotspot, Internet Connection Sharing, parental controls, Windows Insider, Work Folders, AllJoyn router and Windows Media Player network sharing. Each one is small; together they remove a lot of wake-ups, timers and memory.',
    'Breaks: printing and scanning-to-PC, network/audio troubleshooters, Phone Link & Nearby Sharing, mobile hotspot, location services, Windows Insider, error reports to Microsoft.',
    [
      ['Spooler', 'Automatic'], ['Fax', 'Manual'], ['DPS', 'Automatic'], ['WdiServiceHost', 'Manual'], ['WdiSystemHost', 'Manual'],
      ['WerSvc', 'Manual'], ['PcaSvc', 'Automatic'], ['CDPSvc', 'Automatic'], ['TrkWks', 'Automatic'], ['MapsBroker', 'AutomaticDelayed'],
      ['lfsvc', 'Manual'], ['RetailDemo', 'Manual'], ['WalletService', 'Manual'], ['SEMgrSvc', 'Manual'], ['PhoneSvc', 'Manual'],
      ['icssvc', 'Manual'], ['SharedAccess', 'Manual'], ['WpcMonSvc', 'Manual'], ['wisvc', 'Manual'], ['workfolderssvc', 'Manual'],
      ['AJRouter', 'Manual'], ['WMPNetworkSvc', 'Manual']
    ]),
  svcItem('ext.xbox_services_off', 'Disable Xbox services',
    'Stops Xbox Live authentication, cloud-save sync and networking services.',
    'Only do this if you never use the Xbox app, Game Pass or Microsoft Store games. Steam, Epic, Battle.net and Riot games are unaffected. Controllers keep working through their driver.',
    'Breaks: Game Pass / Xbox app sign-in, Xbox cloud saves, Xbox party chat, some Microsoft Store games.',
    [['XblAuthManager', 'Manual'], ['XblGameSave', 'Manual'], ['XboxNetApiSvc', 'Manual']]),
  svcItem('ext.bluetooth_off', 'Disable Bluetooth',
    'Stops the Bluetooth stack and its audio/remote-control services.',
    'The Bluetooth radio and its services generate periodic interrupts and DPCs even when nothing is paired. If you play wired, there is no reason to keep it running.',
    'Breaks: every Bluetooth device — headsets, controllers over Bluetooth, mice, phones.',
    [['bthserv', 'Manual'], ['BTAGService', 'Manual'], ['BthAvctpSvc', 'Manual']], { impact: { latency: 1, fps: 0 } }),
  {
    id: 'ext.pause_updates',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Pause Windows Update (35 days)',
    summary: 'Pauses all Windows updates for the maximum 35 days and blocks automatic install.',
    details: 'Uses Windows Update\'s own pause mechanism (the same as Settings > Windows Update > Pause), which works on every edition and is not undone by the update repair service like disabling the services is. Re-apply to extend; revert to resume updates immediately.',
    tradeoff: 'No security patches while paused. Resume regularly to stay protected.',
    impact: { latency: 0, fps: 1 }, tags: ['background'], evidence: 'documented',
    risk: 'advanced', presets: ['latency', 'fps'], reboot: 'none',
    apply: [
      regSet(R`HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`, 'NoAutoUpdate', 'DWORD', 1),
      ps(R`$k = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
$now = (Get-Date).ToUniversalTime(); $end = $now.AddDays(35)
$f = 'yyyy-MM-ddTHH:mm:ssZ'
foreach ($n in 'PauseFeatureUpdatesStartTime', 'PauseQualityUpdatesStartTime') { Set-ItemProperty $k $n $now.ToString($f) }
foreach ($n in 'PauseFeatureUpdatesEndTime', 'PauseQualityUpdatesEndTime', 'PauseUpdatesExpiryTime') { Set-ItemProperty $k $n $end.ToString($f) }
"Updates paused until $($end.ToLocalTime().ToString('d'))."`,
      R`$v = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -ErrorAction SilentlyContinue).PauseUpdatesExpiryTime
if ($v -and ([datetime]$v) -gt (Get-Date)) { 'true' } else { 'false' }`)
    ],
    revert: [
      regDel(R`HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`, 'NoAutoUpdate'),
      ps(R`$k = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
Remove-ItemProperty $k -Name PauseFeatureUpdatesStartTime, PauseQualityUpdatesStartTime, PauseFeatureUpdatesEndTime, PauseQualityUpdatesEndTime, PauseUpdatesExpiryTime -ErrorAction SilentlyContinue
'Windows Update resumed.'`)
    ]
  },
  {
    id: 'ext.defender_low_impact',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Defender: no scheduled scans, low-priority scanning',
    summary: 'Real-time protection stays on, but full scans never start on their own and scans run at low CPU priority.',
    details: 'Scheduled Defender scans can start in the middle of a session and cause heavy disk/CPU stutter. This limits scans to 5% average CPU, low priority, and disables the scheduled and catch-up full scans. Falcon cannot (and will not) fully disable Defender while Tamper Protection is on — if you want it fully off, turn off Tamper Protection and Real-time protection yourself in Windows Security.',
    tradeoff: 'Malware that slipped past real-time protection is not caught by periodic full scans. Run a manual scan occasionally.',
    impact: { latency: 0, fps: 1 }, tags: ['background'], evidence: 'documented',
    risk: 'moderate', presets: ['latency', 'fps'], reboot: 'none',
    apply: [ps(
      R`Set-MpPreference -ScanAvgCPULoadFactor 5 -EnableLowCpuPriority $true -ScanScheduleDay 8 -DisableCatchupFullScan $true -DisableCatchupQuickScan $true -ScanOnlyIfIdleEnabled $true
'Defender scanning set to low impact.'`,
      R`try { $p = Get-MpPreference -ErrorAction Stop } catch { 'unknown'; return }
if ($p.ScanAvgCPULoadFactor -le 5 -and $p.EnableLowCpuPriority -and [int]$p.ScanScheduleDay -eq 8) { 'true' } else { 'false' }`)],
    revert: [ps(R`Set-MpPreference -ScanAvgCPULoadFactor 50 -EnableLowCpuPriority $false -ScanScheduleDay 0 -DisableCatchupFullScan $true -DisableCatchupQuickScan $false -ScanOnlyIfIdleEnabled $true
'Defender scanning restored to defaults.'`)]
  },
  {
    id: 'ext.remove_bloat_apps',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Remove preinstalled bloat apps',
    summary: `Uninstalls ${BLOAT.length} preinstalled apps (News, Weather, Clipchamp, Teams personal, Copilot, Solitaire, Phone Link, ads) for all users.`,
    details: 'Removes the apps and their provisioned copies so they do not come back for new users. Keeps everything Windows needs: Store, Xbox/Game Bar, Photos, Calculator, Notepad, Terminal, Media Player, Snipping Tool, Settings.',
    tradeoff: 'Removed apps must be reinstalled manually from the Microsoft Store if you want them back — revert cannot restore them.',
    impact: { latency: 0, fps: 0 }, tags: ['background'], evidence: 'documented',
    risk: 'advanced', presets: ['latency', 'fps'], reboot: 'none',
    apply: [ps(
      R`$names = ${bloatList}; $n = 0
foreach ($name in $names) {
  Get-AppxPackage -AllUsers -Name $name -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop; $n++ } catch {} }
  Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -eq $name | ForEach-Object { try { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null } catch {} }
}
"Removed $n app package(s)."`,
      R`$names = ${bloatList}
$left = @(Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $names -contains $_.Name })
if ($left.Count -eq 0) { 'true' } else { 'false' }`)],
    revert: [ps(R`'Removed apps cannot be restored automatically. Reinstall the ones you want from the Microsoft Store.'`)]
  },
  {
    id: 'ext.onedrive_off',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Disable OneDrive',
    summary: 'Stops OneDrive from running and syncing in the background.',
    details: 'Applies the official "Prevent the usage of OneDrive for file storage" policy and closes the client. Sync uploads and file-change scanning during play are a common source of disk and network spikes.',
    tradeoff: 'Breaks: OneDrive sync and Known Folder backup (Desktop/Documents/Pictures). Files already on the PC stay.',
    impact: { latency: 0, fps: 0 }, tags: ['background'], evidence: 'documented',
    risk: 'moderate', presets: ['latency', 'fps'], reboot: 'signout',
    apply: [
      regSet(R`HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive`, 'DisableFileSyncNGSC', 'DWORD', 1),
      ps(R`Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force; 'OneDrive stopped.'`)
    ],
    revert: [regDel(R`HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive`, 'DisableFileSyncNGSC')]
  },
  {
    id: 'ext.notifications_off',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Disable all toast notifications',
    summary: 'No pop-up notifications from any app, ever.',
    details: 'Windows 11 already suppresses notifications in fullscreen games, but borderless games and second monitors still get them, and each toast wakes the notification platform.',
    tradeoff: 'You will not see any app notifications (Discord, mail, calendar reminders, security alerts still appear in Windows Security).',
    impact: { latency: 0, fps: 0 }, tags: ['background'], evidence: 'documented',
    risk: 'moderate', presets: ['latency', 'fps'], reboot: 'signout',
    apply: [regSet(R`HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications`, 'ToastEnabled', 'DWORD', 0)],
    revert: [regSet(R`HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications`, 'ToastEnabled', 'DWORD', 1)]
  },
  {
    id: 'ext.auto_maintenance_off',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Disable automatic maintenance',
    summary: 'Stops Windows running its maintenance window (defrag/TRIM, diagnostics, update cleanup) on its own.',
    details: 'Automatic maintenance starts when the PC looks idle — including in long loading screens and AFK moments — and can spike disk and CPU. With this off, run Maintenance > TRIM all SSDs and Clean temporary files yourself about once a month.',
    tradeoff: 'SSD TRIM and component-store cleanup no longer happen automatically.',
    impact: { latency: 0, fps: 1 }, tags: ['background'], evidence: 'mechanism',
    risk: 'moderate', presets: ['latency', 'fps'], reboot: 'none',
    apply: [regSet(R`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance`, 'MaintenanceDisabled', 'DWORD', 1)],
    revert: [regDel(R`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance`, 'MaintenanceDisabled')]
  },
  {
    id: 'ext.start_web_search_off',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Start menu: no web results or Copilot',
    summary: 'Start/Search only searches your PC — no Bing, no web suggestions.',
    details: 'Every keystroke in Start search otherwise makes a network request to Bing. Also turns off the legacy Copilot sidebar policy.',
    tradeoff: 'No web answers in Start search.',
    impact: { latency: 0, fps: 0 }, tags: ['qol'], evidence: 'documented',
    risk: 'safe', presets: ['latency', 'fps'], reboot: 'signout',
    apply: [
      regSet(R`HKCU\Software\Policies\Microsoft\Windows\Explorer`, 'DisableSearchBoxSuggestions', 'DWORD', 1),
      regSet(R`HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`, 'TurnOffWindowsCopilot', 'DWORD', 1)
    ],
    revert: [
      regDel(R`HKCU\Software\Policies\Microsoft\Windows\Explorer`, 'DisableSearchBoxSuggestions'),
      regDel(R`HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`, 'TurnOffWindowsCopilot')
    ]
  },
  {
    id: 'ext.hibernation_off',
    category: 'extreme', kind: 'toggle', tier: 'extreme',
    name: 'Disable hibernation (delete hiberfil.sys)',
    summary: 'Removes the hibernation file, freeing disk space equal to ~40% of your RAM.',
    details: 'A dedicated gaming desktop never hibernates. Fast Startup also stops working (which Falcon recommends anyway).',
    tradeoff: 'No Hibernate option in the power menu.',
    impact: { latency: 0, fps: 0 }, tags: ['disk'], evidence: 'documented',
    risk: 'safe', presets: ['latency', 'fps'], reboot: 'none',
    when: (c) => (c.isLaptop ? 'Laptops need hibernation to protect against battery drain in sleep.' : null),
    apply: [ps(R`powercfg.exe /hibernate off; 'Hibernation disabled.'`, R`$v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -ErrorAction SilentlyContinue).HibernateEnabled; if ($v -eq 0) { 'true' } else { 'false' }`)],
    revert: [ps(R`powercfg.exe /hibernate on; 'Hibernation enabled.'`)]
  }
];
