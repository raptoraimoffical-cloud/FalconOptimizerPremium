'use strict';
const { R, regSet, ps } = require('./_steps');

const plan = (profile, ac) => ps(
  R`& (Join-Path $FalconRoot 'scripts\powerplan.ps1') -Plan ${profile}${ac ? ' -AcOnly' : ''}`,
  R`& (Join-Path $FalconRoot 'scripts\powerplan.ps1') -Plan ${profile} -Check`
);

module.exports = (ctx) => {
  const ac = ctx.isLaptop;
  const x3d = !!ctx.profile.cpu.x3dDual;
  return [
    {
      id: 'power.plan',
      category: 'power',
      kind: 'choice',
      name: 'Falcon power plan',
      summary: 'Builds a tuned power plan from the High Performance template and activates it.',
      details: [
        'All Falcon plans: no CPU core parking, 100% minimum processor state, aggressive boost, max-performance energy preference, USB selective suspend off, PCIe link power management off, disk never spins down, Wi-Fi adapter at maximum performance.',
        'Latency plan additionally disables processor idle states (C-states) so cores never need to wake up — the lowest and most consistent wake latency, at the cost of heat, power and some single-core boost headroom.',
        'FPS plan keeps C-states enabled so idle cores free up thermal/power budget for higher boost clocks on the cores the game uses.',
        'Dual-CCD Ryzen X3D (7900X3D/7950X3D/9900X3D/9950X3D): AMD\'s driver needs core parking from the Balanced plan to keep games on the V-Cache CCD, so Falcon uses a Balanced-based plan that only changes device power settings.'
      ].join('\n\n'),
      tradeoff: 'Higher idle power draw and temperatures, especially with the Latency plan.',
      impact: { latency: 2, fps: 2 },
      evidence: 'measured',
      risk: 'safe',
      reboot: 'none',
      options: [
        { id: 'latency', label: 'Falcon Latency — C-states off', presets: x3d ? [] : ['latency'], apply: [plan('latency', ac)],
          when: (c) => (c.profile.cpu.x3dDual ? 'Breaks V-Cache core parking on dual-CCD X3D CPUs.' : null) },
        { id: 'fps', label: 'Falcon FPS — boost headroom', presets: x3d ? [] : ['fps'], apply: [plan('fps', ac)],
          when: (c) => (c.profile.cpu.x3dDual ? 'Breaks V-Cache core parking on dual-CCD X3D CPUs.' : null) },
        { id: 'x3d', label: 'Falcon X3D — Balanced-based', presets: x3d ? ['latency', 'fps'] : [], apply: [plan('x3d', ac)] },
        { id: 'default', label: 'Previous / Windows Balanced', isDefault: true, apply: [plan('restore', ac)] }
      ]
    },
    {
      id: 'power.fast_startup_off',
      category: 'power',
      kind: 'toggle',
      name: 'Disable Fast Startup',
      summary: 'Makes "Shut down" a real shutdown instead of a partial hibernation of the kernel and drivers.',
      details: 'Fast Startup restores the previous kernel session on boot, so driver state (and any DPC/latency problem it had) survives shutdowns, and freshly installed drivers or tweaks may not fully apply. Disabling it gives you a clean kernel every boot. Restart was never affected.',
      tags: ['consistency'],
      tradeoff: 'Cold boot takes a few seconds longer.',
      impact: { latency: 0, fps: 0 },
      evidence: 'documented',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'none',
      apply: [regSet(R`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power`, 'HiberbootEnabled', 'DWORD', 0)],
      revert: [regSet(R`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power`, 'HiberbootEnabled', 'DWORD', 1)]
    }
  ];
};
