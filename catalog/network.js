'use strict';
const { R, regSet, netadapter, ps } = require('./_steps');

const MMCSS = R`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`;
const IFACES = R`HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces`;

// Interfaces that actually carry IPv4 (DHCP or static) — avoids touching dormant virtual adapters.
const ACTIVE_IFACES = R`Get-ChildItem '${IFACES}' | Where-Object { $p = Get-ItemProperty $_.PSPath; ($p.PSObject.Properties.Name -contains 'DhcpIPAddress' -and $p.DhcpIPAddress -and $p.DhcpIPAddress -ne '0.0.0.0') -or ($p.PSObject.Properties.Name -contains 'IPAddress' -and ($p.IPAddress -join '') -match '\d') }`;

module.exports = (ctx) => [
  {
    id: 'net.throttling_off',
    category: 'network',
    kind: 'toggle',
    name: 'Disable multimedia network throttling',
    summary: 'Removes the MMCSS cap that limits non-multimedia packet processing while audio/video is playing.',
    details: 'When an MMCSS-registered stream is active (music, Discord voice, video), Windows throttles other network packet processing to ~10 packets/ms by default. Setting NetworkThrottlingIndex to 0xFFFFFFFF disables that cap so game traffic is never deferred while you have voice chat or music open.',
    impact: { latency: 1, fps: 0 },
    evidence: 'documented',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'reboot',
    apply: [regSet(MMCSS, 'NetworkThrottlingIndex', 'DWORD', '0xFFFFFFFF')],
    revert: [regSet(MMCSS, 'NetworkThrottlingIndex', 'DWORD', 10)]
  },
  {
    id: 'net.nagle_off',
    category: 'network',
    kind: 'toggle',
    name: 'Disable Nagle / delayed ACK (TCP games)',
    summary: 'Sends small TCP packets immediately and acknowledges every packet instantly.',
    details: 'Nagle\'s algorithm batches small TCP writes and delayed ACK waits up to 200 ms. This only matters for games that use TCP (League of Legends, World of Warcraft and most MMOs, Minecraft Java, many browser/launcher games). UDP shooters (Valorant, CS2, Fortnite, Apex, CoD) are unaffected either way, so this is harmless to apply.',
    impact: { latency: 1, fps: 0 },
    evidence: 'documented',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [ps(
      R`$n = 0
${ACTIVE_IFACES} | ForEach-Object { Set-ItemProperty $_.PSPath TcpAckFrequency 1 -Type DWord; Set-ItemProperty $_.PSPath TCPNoDelay 1 -Type DWord; $n++ }
"Applied to $n active interface(s)."`,
      R`$i = @(${ACTIVE_IFACES})
if ($i.Count -eq 0) { 'na' } else { $bad = @($i | Where-Object { $p = Get-ItemProperty $_.PSPath; -not ($p.PSObject.Properties.Name -contains 'TcpAckFrequency' -and $p.TcpAckFrequency -eq 1 -and $p.PSObject.Properties.Name -contains 'TCPNoDelay' -and $p.TCPNoDelay -eq 1) }); if ($bad.Count -eq 0) { 'true' } else { 'false' } }`
    )],
    revert: [ps(R`Get-ChildItem '${IFACES}' | ForEach-Object { Remove-ItemProperty $_.PSPath -Name TcpAckFrequency, TCPNoDelay -ErrorAction SilentlyContinue }
'Removed TcpAckFrequency/TCPNoDelay overrides.'`)]
  },
  {
    id: 'net.interrupt_moderation_off',
    category: 'network',
    kind: 'toggle',
    name: 'NIC interrupt moderation off',
    summary: 'The network card raises an interrupt for every packet instead of batching them.',
    details: 'Interrupt moderation holds received packets for a short window (tens to hundreds of microseconds) to reduce CPU interrupts. Turning it off delivers each game packet to the OS immediately — a direct latency win at the cost of more CPU interrupts under heavy traffic (large downloads). This is a latency-over-throughput trade, so it is only in the Latency preset. The adapter briefly reconnects when applied.',
    tradeoff: 'More CPU time spent on interrupts during big downloads/streams.',
    impact: { latency: 1, fps: 0 },
    evidence: 'measured',
    risk: 'moderate',
    presets: ['latency'],
    reboot: 'none',
    apply: [netadapter('*InterruptModeration', 0)],
    revert: [netadapter('*InterruptModeration', 1)]
  },
  {
    id: 'net.power_saving_off',
    category: 'network',
    kind: 'toggle',
    name: 'Disable Ethernet power saving (EEE / Green Ethernet)',
    summary: 'Stops the network link from dropping into low-power states between packets.',
    details: 'Energy Efficient Ethernet (802.3az) and vendor "Green Ethernet"/"Power Saving Mode" put the link to sleep between packets; waking adds latency and some NIC/switch combinations cause micro-disconnects and ping spikes. Applies the standard *EEE keyword plus Intel and Realtek vendor equivalents where present. The adapter briefly reconnects when applied.',
    impact: { latency: 1, fps: 0 },
    evidence: 'mechanism',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [
      netadapter('*EEE', 0),
      netadapter('EEELinkAdvertisement', 0),
      netadapter('EnableGreenEthernet', 0),
      netadapter('AdvancedEEE', 0),
      netadapter('PowerSavingMode', 0),
      netadapter('ULPMode', 0)
    ],
    revert: [
      netadapter('*EEE', 1),
      netadapter('EEELinkAdvertisement', 1),
      netadapter('EnableGreenEthernet', 1),
      netadapter('AdvancedEEE', 1),
      netadapter('PowerSavingMode', 1),
      netadapter('ULPMode', 1)
    ]
  },
  {
    id: 'net.rss_on',
    category: 'network',
    kind: 'toggle',
    name: 'Receive Side Scaling enabled',
    summary: 'Spreads network processing across CPU cores. Undoes old optimizers that turned it off.',
    details: 'With RSS disabled every packet is processed on a single core, which can collide with the game\'s main thread. RSS is the Windows default; this item restores it if something disabled it.',
    tags: ['fix'],
    impact: { latency: 1, fps: 0 },
    evidence: 'documented',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [netadapter('*RSS', 1)],
    revert: []
  },
  {
    id: 'net.autotuning_normal',
    category: 'network',
    kind: 'toggle',
    name: 'TCP receive window auto-tuning: normal',
    summary: 'Restores Windows default auto-tuning. Undoes old "disable autotuning" tweaks that cripple download speed.',
    details: 'Disabling auto-tuning caps the TCP receive window at 64 KB, which limits downloads to a fraction of a fast connection and makes updates/patches take longer — with no benefit to game latency (games use UDP or small TCP messages).',
    tags: ['fix'],
    impact: { latency: 0, fps: 0 },
    evidence: 'documented',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [ps(
      R`netsh int tcp set global autotuninglevel=normal | Out-Null; 'Auto-tuning set to normal.'`,
      R`$s = Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue; if (-not $s) { 'na' } elseif ([string]$s.AutoTuningLevelLocal -eq 'Normal') { 'true' } else { 'false' }`
    )],
    revert: []
  },
  {
    id: 'net.wifi_scan_off',
    category: 'network',
    kind: 'toggle',
    name: 'Stop Wi-Fi background scanning (while gaming on Wi-Fi)',
    summary: 'Prevents the periodic Wi-Fi scan that causes a ping spike roughly every 60 seconds.',
    details: 'Windows periodically scans for networks even while connected, briefly taking the radio off-channel — the classic "lag spike every minute" on Wi-Fi. Turning off WLAN auto-configuration stops it. Use a wired connection if you can; otherwise apply this before playing and revert afterwards.',
    tradeoff: 'Wi-Fi will not auto-connect or roam to other networks until reverted.',
    impact: { latency: 2, fps: 0 },
    evidence: 'measured',
    risk: 'advanced',
    presets: [],
    reboot: 'none',
    when: (c) => (c.profile.net && c.profile.net.hasWifi ? null : 'No Wi-Fi adapter detected.'),
    apply: [ps(R`Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match '802\.11|Native 802' } | ForEach-Object { netsh wlan set autoconfig enabled=no interface="$($_.Name)" | Out-Null; "Auto-config off: $($_.Name)" }`)],
    revert: [ps(R`Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match '802\.11|Native 802' } | ForEach-Object { netsh wlan set autoconfig enabled=yes interface="$($_.Name)" | Out-Null; "Auto-config on: $($_.Name)" }`)]
  }
];
