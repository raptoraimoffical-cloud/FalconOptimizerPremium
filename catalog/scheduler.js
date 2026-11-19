'use strict';
const { R, regSet, regDel, bcd, bcdDel, ps } = require('./_steps');

const PRIO = R`HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl`;
const KERNEL = R`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`;
const MMCSS = R`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`;

module.exports = (ctx) => {
  const timerRes = Number(ctx.settings.timerResolution) || 5000; // 100ns units
  const timerMs = (timerRes / 10000).toFixed(3).replace(/0+$/, '').replace(/\.$/, '');
  return [
    {
      id: 'sched.priority_separation',
      category: 'scheduler',
      kind: 'choice',
      name: 'Foreground scheduling (Win32PrioritySeparation)',
      summary: 'Controls CPU time-slice length and how much the focused game is favored over background work.',
      details: 'Bits encode quantum length (short/long), fixed vs variable quanta, and the foreground boost ratio. The Windows client default (2) already behaves like 0x26. Latency profile uses short, fixed quanta with maximum foreground boost so the game thread is preempted less and rescheduled sooner. Effects are small and game-dependent — verify with your own frametime/latency capture.',
      impact: { latency: 1, fps: 1 },
      evidence: 'mechanism',
      risk: 'safe',
      reboot: 'none',
      options: [
        { id: 'latency', label: 'Latency — 0x2A (short, fixed, 3:1)', presets: ['latency'], apply: [regSet(PRIO, 'Win32PrioritySeparation', 'DWORD', 0x2a)] },
        { id: 'fps', label: 'FPS — 0x26 (short, variable, 3:1)', presets: ['fps'], apply: [regSet(PRIO, 'Win32PrioritySeparation', 'DWORD', 0x26)] },
        { id: 'default', label: 'Windows default (2)', isDefault: true, apply: [regSet(PRIO, 'Win32PrioritySeparation', 'DWORD', 2)] }
      ]
    },
    {
      id: 'sched.global_timer_requests',
      category: 'scheduler',
      kind: 'toggle',
      name: 'Allow system-wide timer resolution (Windows 11)',
      summary: 'Restores pre-2004 behavior so a timer-resolution request from one process applies to the whole system.',
      details: 'Since Windows 10 2004, timer resolution is per-process, and Windows 11 can ignore requests from background processes. GlobalTimerResolutionRequests=1 (honored on Windows 11 / Server 2022+) makes the Falcon timer service effective for every game, including those that only request 1 ms or nothing at all.',
      impact: { latency: 2, fps: 0 },
      evidence: 'documented',
      risk: 'safe',
      presets: ['latency'],
      reboot: 'reboot',
      when: (c) => (c.profile.os.build < 22000 ? 'Requires Windows 11 (build 22000+). On Windows 10 2004+ timer requests are per-process only.' : null),
      apply: [regSet(KERNEL, 'GlobalTimerResolutionRequests', 'DWORD', 1)],
      revert: [regDel(KERNEL, 'GlobalTimerResolutionRequests')]
    },
    {
      id: 'sched.timer_service',
      category: 'scheduler',
      kind: 'toggle',
      name: `Timer resolution service (${timerMs} ms)`,
      summary: 'Installs a tiny background service that holds the system timer at a high resolution from boot.',
      details: 'A 2 KB native helper (compiled locally, no download) runs as SYSTEM at startup and calls NtSetTimerResolution, opting out of Windows 11 timer throttling. Higher resolution tightens Sleep()/wait precision used by frame limiters and input polling loops. Change the value on the Tools page — 0.5 ms is typical; 0.507 ms can give better Sleep(1) precision on some systems. Needs "Allow system-wide timer resolution" on Windows 11.',
      tradeoff: 'More frequent timer interrupts: slightly higher idle power draw.',
      impact: { latency: 2, fps: 0 },
      evidence: 'measured',
      risk: 'safe',
      presets: ['latency'],
      reboot: 'none',
      when: (c) => (c.profile.os.build < 22000 ? 'Only effective system-wide on Windows 11. On Windows 10 2004+ games control their own timer resolution.' : null),
      apply: [ps(
        R`& (Join-Path $FalconRoot 'scripts\timer.ps1') -Action install -Resolution ${timerRes}`,
        R`$s = & (Join-Path $FalconRoot 'scripts\timer.ps1') -Action status | ConvertFrom-Json; if ($s.installed) { 'true' } else { 'false' }`
      )],
      revert: [ps(R`& (Join-Path $FalconRoot 'scripts\timer.ps1') -Action remove`)]
    },
    {
      id: 'sched.dynamic_tick_off',
      category: 'scheduler',
      kind: 'toggle',
      name: 'Disable dynamic tick',
      summary: 'Keeps the periodic system tick running instead of letting Windows skip ticks when idle.',
      details: 'Dynamic tick saves power by coalescing timer interrupts on idle cores. Disabling it removes tick-skipping jitter, which can tighten timer-driven latency. The benefit is small on modern Windows 11 builds; it is a pure latency-over-power trade.',
      tradeoff: 'Higher idle power and temperature. Not recommended for laptops.',
      impact: { latency: 1, fps: 0 },
      evidence: 'mechanism',
      risk: 'safe',
      presets: ['latency'],
      reboot: 'reboot',
      when: (c) => (c.isLaptop ? 'Skipped on laptops (battery and thermals).' : null),
      apply: [bcd('disabledynamictick', 'yes')],
      revert: [bcdDel('disabledynamictick')]
    },
    {
      id: 'sched.reset_forced_clocks',
      category: 'scheduler',
      kind: 'toggle',
      name: 'Remove forced HPET / platform tick overrides',
      summary: 'Deletes old bcdedit "useplatformclock", "useplatformtick" and "tscsyncpolicy" overrides.',
      details: 'Older optimizers forced HPET as the system clock (useplatformclock true). On modern CPUs the invariant TSC is far cheaper to read; forcing HPET adds overhead to every QueryPerformanceCounter call, measurably lowering FPS and adding latency. This restores the Windows default clock selection. If nothing was set, this is already "applied".',
      tags: ['fix'],
      impact: { latency: 1, fps: 1 },
      evidence: 'measured',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'reboot',
      apply: [bcdDel('useplatformclock'), bcdDel('useplatformtick'), bcdDel('tscsyncpolicy')],
      revert: []
    },
    {
      id: 'sched.mmcss_responsiveness',
      category: 'scheduler',
      kind: 'toggle',
      name: 'MMCSS: reserve less CPU for background tasks',
      summary: 'Lowers SystemResponsiveness from 20% to 10% (the minimum Windows honors).',
      details: 'The Multimedia Class Scheduler reserves a share of CPU for low-priority work whenever multimedia threads (audio engines, some games, Discord) are active. 10 is the documented minimum — 0 is treated as 10, so guides that set 0 do nothing extra.',
      impact: { latency: 1, fps: 0 },
      evidence: 'documented',
      risk: 'safe',
      presets: ['latency', 'fps'],
      reboot: 'reboot',
      apply: [regSet(MMCSS, 'SystemResponsiveness', 'DWORD', 10)],
      revert: [regSet(MMCSS, 'SystemResponsiveness', 'DWORD', 20)]
    }
  ];
};
