'use strict';
const { R, regSet, regDel, bcd } = require('./_steps');

const DG = R`HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard`;
const MM = R`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`;

// Extreme tier only: applied by the Extreme presets (after a typed confirmation) or individually.
module.exports = () => [
  {
    id: 'sec.memory_integrity_off',
    category: 'security',
    kind: 'toggle',
    name: 'Disable Memory Integrity (HVCI) & VBS',
    summary: 'Turns off virtualization-based security. Largest single CPU-side FPS gain available in Windows.',
    details: 'Memory Integrity runs kernel code-integrity checks inside a hypervisor, adding overhead to every kernel transition. Independent testing shows roughly 5–10% average FPS (more in CPU-bound titles and 1% lows) when it is off. Anti-cheats such as Vanguard, FACEIT and Ricochet require TPM 2.0 + Secure Boot, which this does not change. If VBS was enabled with a UEFI lock it cannot be turned off from Windows.',
    tradeoff: 'Removes protection against kernel-level exploits and malicious/vulnerable drivers. Some workplaces require it.',
    impact: { latency: 1, fps: 2 },
    tags: ['security'],
    evidence: 'measured',
    risk: 'advanced',
    tier: 'extreme',
    presets: ['latency', 'fps'],
    reboot: 'reboot',
    apply: [
      regSet(`${DG}\\Scenarios\\HypervisorEnforcedCodeIntegrity`, 'Enabled', 'DWORD', 0),
      regSet(DG, 'EnableVirtualizationBasedSecurity', 'DWORD', 0)
    ],
    revert: [
      regSet(`${DG}\\Scenarios\\HypervisorEnforcedCodeIntegrity`, 'Enabled', 'DWORD', 1),
      regDel(DG, 'EnableVirtualizationBasedSecurity')
    ]
  },
  {
    id: 'sec.hypervisor_off',
    category: 'security',
    kind: 'toggle',
    name: 'Disable the Windows hypervisor',
    summary: 'Stops Hyper-V from loading at boot, so Windows runs on bare metal.',
    details: 'With the hypervisor loaded, Windows itself runs as a privileged guest, adding small overhead to timers and interrupts. Required for VBS — disabling it also guarantees VBS/HVCI cannot run.',
    tradeoff: 'Breaks WSL2, Hyper-V VMs, Windows Sandbox, Docker Desktop, WSA and Credential Guard until reverted.',
    impact: { latency: 1, fps: 1 },
    tags: ['security'],
    evidence: 'mechanism',
    risk: 'advanced',
    tier: 'extreme',
    presets: ['latency', 'fps'],
    reboot: 'reboot',
    apply: [bcd('hypervisorlaunchtype', 'Off')],
    revert: [bcd('hypervisorlaunchtype', 'Auto')]
  },
  {
    id: 'sec.cpu_mitigations_off',
    category: 'security',
    kind: 'toggle',
    name: 'Disable Spectre/Meltdown OS mitigations',
    summary: 'Turns off software mitigations for CPU speculative-execution vulnerabilities.',
    details: 'Meaningful gains mainly on older CPUs (Intel 9th gen and earlier, Ryzen 1000/2000) where mitigations are done in software. Ryzen 3000+ and Intel 10th gen+ have most mitigations in hardware, so the gain is usually within margin of error.',
    tradeoff: 'Exposes the system to speculative-execution attacks (including from JavaScript in browsers). Not recommended on a PC you browse with.',
    impact: { latency: 0, fps: 1 },
    tags: ['security'],
    evidence: 'measured',
    risk: 'advanced',
    tier: 'extreme',
    presets: ['latency', 'fps'],
    reboot: 'reboot',
    apply: [
      regSet(MM, 'FeatureSettingsOverride', 'DWORD', 3),
      regSet(MM, 'FeatureSettingsOverrideMask', 'DWORD', 3)
    ],
    revert: [regDel(MM, 'FeatureSettingsOverride'), regDel(MM, 'FeatureSettingsOverrideMask')]
  }
];
