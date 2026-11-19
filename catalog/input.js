'use strict';
const { R, regSet, powercfg, ps } = require('./_steps');

const SPI_MOUSE = (t1, t2, accel) => R`
if (-not ('Falcon.Spi' -as [type])) { Add-Type -Namespace Falcon -Name Spi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, int[] c, uint d);' }
[void][Falcon.Spi]::SystemParametersInfo(0x0004, 0, [int[]]@(${t1}, ${t2}, ${accel}), 3)
'Pointer settings applied live.'`;

const USB_HID_FILTER = R`$_.InstanceName -match '^(USB|HID)\\'`;

module.exports = (ctx) => [
  {
    id: 'input.pointer_precision_off',
    category: 'input',
    kind: 'toggle',
    name: 'Disable Enhance Pointer Precision',
    summary: 'Turns off Windows mouse acceleration so cursor movement is 1:1 with hand movement.',
    details: 'Windows applies an acceleration curve to the desktop cursor and to games that do not use raw input. Disabling it gives consistent, muscle-memory friendly aim in menus, launchers and older/non-raw-input games. Games using raw input (most modern shooters) already bypass it. Applied live — no sign-out needed.',
    impact: { latency: 0, fps: 0 },
    tags: ['aim-consistency'],
    evidence: 'documented',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [
      regSet(R`HKCU\Control Panel\Mouse`, 'MouseSpeed', 'SZ', '0'),
      regSet(R`HKCU\Control Panel\Mouse`, 'MouseThreshold1', 'SZ', '0'),
      regSet(R`HKCU\Control Panel\Mouse`, 'MouseThreshold2', 'SZ', '0'),
      ps(SPI_MOUSE(0, 0, 0))
    ],
    revert: [
      regSet(R`HKCU\Control Panel\Mouse`, 'MouseSpeed', 'SZ', '1'),
      regSet(R`HKCU\Control Panel\Mouse`, 'MouseThreshold1', 'SZ', '6'),
      regSet(R`HKCU\Control Panel\Mouse`, 'MouseThreshold2', 'SZ', '10'),
      ps(SPI_MOUSE(6, 10, 1))
    ]
  },
  {
    id: 'input.usb_device_power_off',
    category: 'input',
    kind: 'toggle',
    name: 'Stop Windows powering down USB/HID devices',
    summary: 'Unticks "Allow the computer to turn off this device to save power" on every USB controller, hub, mouse and keyboard.',
    details: 'When a USB device or hub is allowed to idle, the first input after a pause can be delayed while the link wakes up, and some mice/keyboards/DACs drop out entirely. This writes the same flag as the Device Manager Power Management checkbox (MSPower_DeviceEnable). Devices plugged in later get Windows defaults again — re-run after adding new peripherals.',
    tradeoff: 'Slightly higher idle power draw (negligible on desktops).',
    impact: { latency: 2, fps: 0 },
    evidence: 'mechanism',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [ps(
      R`$n = 0
Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction Stop | Where-Object { ${USB_HID_FILTER} -and $_.Enable } | ForEach-Object { Set-CimInstance -InputObject $_ -Property @{ Enable = $false }; $n++ }
"Disabled power saving on $n USB/HID device(s)."`,
      R`$all = @(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue | Where-Object { ${USB_HID_FILTER} })
if ($all.Count -eq 0) { 'na' } elseif (@($all | Where-Object { $_.Enable }).Count -eq 0) { 'true' } else { 'false' }`
    )],
    revert: [ps(
      R`Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction Stop | Where-Object { ${USB_HID_FILTER} -and -not $_.Enable } | ForEach-Object { Set-CimInstance -InputObject $_ -Property @{ Enable = $true } }
'Restored Windows default device power management.'`
    )]
  },
  {
    id: 'input.usb_selective_suspend_off',
    category: 'input',
    kind: 'toggle',
    name: 'Disable USB selective suspend',
    summary: 'Power-plan setting that lets Windows suspend idle USB ports. Off = ports stay awake.',
    details: 'Complements the per-device setting above at the power-plan level. Prevents wake-up delay and dropouts on USB mice, keyboards, controllers and audio interfaces. On laptops this is only changed for "plugged in" so battery life is unaffected.',
    tradeoff: 'Marginally higher idle power on battery-less systems.',
    impact: { latency: 1, fps: 0 },
    evidence: 'mechanism',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'none',
    apply: [powercfg('2a737441-1930-4402-8d77-b2bebba308a3', '48e6b7a6-50f5-4782-a5d4-53bb8f07e226', 0, ctx.isLaptop ? 'ac' : 'both')],
    revert: [powercfg('2a737441-1930-4402-8d77-b2bebba308a3', '48e6b7a6-50f5-4782-a5d4-53bb8f07e226', 1, ctx.isLaptop ? 'ac' : 'both')]
  },
  {
    id: 'input.accessibility_hotkeys_off',
    category: 'input',
    kind: 'toggle',
    name: 'Disable Sticky/Filter/Toggle Keys hotkeys',
    summary: 'Stops the "Press Shift 5 times" and "hold Shift 8 seconds" popups from minimizing your game.',
    details: 'Only removes the keyboard shortcuts that trigger these accessibility prompts. The features themselves can still be enabled from Settings > Accessibility.',
    impact: { latency: 0, fps: 0 },
    tags: ['qol'],
    evidence: 'documented',
    risk: 'safe',
    presets: ['latency', 'fps'],
    reboot: 'signout',
    apply: [
      regSet(R`HKCU\Control Panel\Accessibility\StickyKeys`, 'Flags', 'SZ', '506'),
      regSet(R`HKCU\Control Panel\Accessibility\Keyboard Response`, 'Flags', 'SZ', '122'),
      regSet(R`HKCU\Control Panel\Accessibility\ToggleKeys`, 'Flags', 'SZ', '58')
    ],
    revert: [
      regSet(R`HKCU\Control Panel\Accessibility\StickyKeys`, 'Flags', 'SZ', '510'),
      regSet(R`HKCU\Control Panel\Accessibility\Keyboard Response`, 'Flags', 'SZ', '126'),
      regSet(R`HKCU\Control Panel\Accessibility\ToggleKeys`, 'Flags', 'SZ', '62')
    ]
  }
];
