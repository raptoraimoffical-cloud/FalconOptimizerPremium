'use strict';
const path = require('path');
const { runPowerShellFile } = require('./ps');

const vendorOf = (name) => {
  const n = String(name || '').toLowerCase();
  if (/nvidia|geforce|rtx|gtx|quadro/.test(n)) return 'nvidia';
  if (/amd|radeon/.test(n)) return 'amd';
  if (/intel|arc|iris|uhd/.test(n)) return 'intel';
  return 'unknown';
};

/** Fill derived fields the catalog relies on (primary GPU, defaults for missing sections). */
function normalizeProfile(p) {
  const profile = p && typeof p === 'object' ? p : {};
  profile.os = profile.os || { build: 0 };
  profile.cpu = profile.cpu || { vendor: 'unknown' };
  profile.ram = profile.ram || {};
  profile.state = profile.state || {};
  profile.net = profile.net || {};
  profile.displays = Array.isArray(profile.displays) ? profile.displays : (profile.displays ? [profile.displays] : []);
  profile.gpus = (Array.isArray(profile.gpus) ? profile.gpus : (profile.gpus ? [profile.gpus] : [])).map((g) => ({ ...g, vendor: vendorOf(g.name) }));
  // Primary = the discrete GPU if there is one (NVIDIA/AMD, or Intel Arc), else the first adapter.
  const discrete = profile.gpus.find((g) => g.vendor === 'nvidia' || g.vendor === 'amd' || /arc/i.test(g.name || ''));
  const primary = discrete || profile.gpus[0] || { name: 'Unknown GPU', vendor: 'unknown' };
  profile.gpu = { name: primary.name, vendor: primary.vendor, vramGb: primary.vramGb, driverDate: primary.driverDate, driverVersion: primary.driverVersion };
  profile.hybridGraphics = profile.gpus.length > 1 && !!discrete;
  if (!profile.formFactor) profile.formFactor = 'desktop';
  return profile;
}

async function collectProfile(appRoot) {
  const res = await runPowerShellFile(path.join(appRoot, 'scripts', 'system-profile.ps1'), [], { timeoutMs: 60000 });
  let raw = null;
  try { raw = JSON.parse(String(res.stdout || '').trim()); } catch (_) { raw = null; }
  if (!raw) {
    return normalizeProfile({ error: (res.stderr || 'System profile failed').slice(0, 500), os: { build: 0 }, formFactor: 'desktop' });
  }
  return normalizeProfile(raw);
}

/**
 * Health checks: things that cost FPS or latency that Falcon cannot (or should not) change with a
 * registry write — BIOS settings, wrong refresh rate, outdated drivers, etc. Each check gives a
 * status (good | warn | bad | info) and a concrete fix.
 */
function healthChecks(p) {
  const out = [];
  const add = (id, status, title, detail, fix) => out.push({ id, status, title, detail, fix: fix || null });
  const s = p.state || {};
  const desktop = p.formFactor !== 'laptop';

  // Windows version
  const b = p.os.build || 0;
  if (b && b < 22000) add('os', 'warn', 'Windows 10 is out of support', `Build ${b}. Windows 10 stopped receiving security updates in October 2025, and Windows 11 adds the windowed-game flip model, better hybrid-CPU scheduling and global timer resolution control.`, 'Upgrade to Windows 11 24H2 or newer.');
  else if (b) add('os', 'good', `Windows ${p.os.displayVersion || ''} (build ${b}.${p.os.ubr || 0})`.replace('  ', ' '), 'Modern Windows 11 build.', null);

  // Refresh rate: the single most common "free latency" mistake
  for (const d of p.displays || []) {
    if (d.maxRefreshHz && d.refreshHz && d.refreshHz < d.maxRefreshHz - 1) {
      add(`refresh-${d.device}`, 'bad', `Display running at ${d.refreshHz} Hz — supports ${d.maxRefreshHz} Hz`, `${d.resolution} on ${d.adapter}. Lower refresh rate adds up to ${(1000 / d.refreshHz - 1000 / d.maxRefreshHz).toFixed(1)} ms of display latency per frame and caps visible FPS.`, 'Settings > System > Display > Advanced display > Choose a refresh rate. Use a DisplayPort/HDMI 2.1 cable that supports it.');
    } else if (d.refreshHz) {
      add(`refresh-${d.device}`, 'good', `Display at ${d.refreshHz} Hz (max)`, `${d.resolution} on ${d.adapter}.`, null);
    }
  }

  // RAM: XMP/EXPO and dual channel (desktop only — laptop RAM speed is usually CPU-limited)
  const r = p.ram || {};
  if (desktop && r.ratedMTs && r.configuredMTs && r.configuredMTs < r.ratedMTs * 0.85) {
    add('xmp', 'bad', `RAM running at ${r.configuredMTs} MT/s — rated ${r.ratedMTs} MT/s`, 'Memory is at JEDEC fallback speed. XMP/EXPO off typically costs 5–15% FPS in CPU-bound games and hurts 1% lows the most.', 'Enable XMP (Intel) or EXPO/DOCP (AMD) in BIOS, then test stability.');
  } else if (r.configuredMTs) {
    add('xmp', 'good', `RAM at ${r.configuredMTs} MT/s`, r.ratedMTs ? `Module rating ${r.ratedMTs} MT/s.` : '', null);
  }
  if (r.modules === 1) add('channels', 'warn', 'Single RAM stick (single channel)', 'One module halves memory bandwidth, which noticeably lowers FPS on CPUs and especially on integrated graphics.', 'Install a matching second module (dual channel).');
  if (r.totalGb && r.totalGb < 16) add('ram-size', 'warn', `${r.totalGb} GB RAM`, 'Many current games use 12+ GB; with less than 16 GB Windows pages to disk mid-game, causing stutter.', 'Upgrade to 32 GB (2×16 GB).');

  // VBS / HVCI
  if (s.hvciRunning || s.vbsRunning) {
    add('vbs', 'info', s.hvciRunning ? 'Memory Integrity (HVCI) is running' : 'Virtualization-based security is running', 'VBS/HVCI typically costs about 5–10% average FPS in CPU-bound games. It is a real security feature — disabling it is your call.', 'Turned off by the Extreme presets, or individually under Tweaks > Security Trade-offs.');
  } else {
    add('vbs', 'good', 'VBS / Memory Integrity off', 'No hypervisor-enforced code integrity overhead.', null);
  }

  // Power plan
  if (s.powerPlan && /saver|eco/i.test(s.powerPlan)) add('powerplan', 'bad', `"${s.powerPlan}" power plan is active`, 'Power saver caps CPU frequency and aggressively parks cores — a large FPS and latency penalty.', 'Apply a Falcon power plan (Tweaks > Power & CPU).');
  else if (s.powerPlan) add('powerplan', /falcon/i.test(s.powerPlan) ? 'good' : 'info', `Power plan: ${s.powerPlan}`, /falcon/i.test(s.powerPlan) ? 'Falcon tuned plan active.' : 'Not using a Falcon tuned plan.', null);

  // Forced HPET
  if (s.forcedPlatformClock) add('hpet', 'bad', 'HPET is forced as the system clock', 'bcdedit useplatformclock is set (usually by an old optimizer). This makes every timing call slower and measurably lowers FPS.', 'Apply "Remove forced HPET / platform tick overrides" (Scheduler & Timers).');

  // Game DVR / Game Mode / mouse accel
  if (s.gameDvr === 1) add('dvr', 'warn', 'Game Bar background recording is on', 'Costs GPU encoder time and adds frametime variance.', 'Apply "Disable Xbox Game Bar background recording".');
  if (s.gameMode === 0) add('gamemode', 'warn', 'Game Mode is off', 'Game Mode blocks update restarts/driver installs during play and is required for X3D CCD steering.', 'Apply "Windows Game Mode on".');
  if (s.mouseAccel) add('mouse', 'warn', 'Enhance Pointer Precision is on', 'Mouse acceleration makes cursor/aim distance depend on speed in non-raw-input games and menus.', 'Apply "Disable Enhance Pointer Precision".');

  // HAGS
  if (p.gpu.vendor !== 'unknown' && s.hags !== 2 && b >= 19041) add('hags', 'info', 'Hardware-accelerated GPU scheduling is off', 'Needed for DLSS Frame Generation; slightly lowers CPU overhead.', 'Apply "Hardware-accelerated GPU scheduling".');

  // ReBAR (NVIDIA only via nvidia-smi)
  if (s.resizableBar === false && desktop) add('rebar', 'warn', 'Resizable BAR is off', 'ReBAR lets the CPU access all of VRAM at once; worth a few % in many modern titles.', 'Enable "Above 4G Decoding" and "Re-Size BAR Support" in BIOS (requires UEFI boot / CSM off).');
  else if (s.resizableBar === true) add('rebar', 'good', 'Resizable BAR enabled', '', null);

  // GPU driver age
  if (p.gpu.driverDate) {
    const ageDays = (Date.now() - new Date(p.gpu.driverDate).getTime()) / 86400000;
    if (ageDays > 240) add('driver', 'warn', `${p.gpu.name} driver is ${Math.round(ageDays / 30)} months old`, `Driver ${p.gpu.driverVersion || ''} from ${p.gpu.driverDate}. New games get performance fixes in recent drivers.`, 'Update from NVIDIA/AMD/Intel directly (consider a clean install with DDU if you have issues).');
    else add('driver', 'good', `${p.gpu.name} driver is recent`, `${p.gpu.driverVersion || ''} (${p.gpu.driverDate}).`, null);
  }

  // X3D dual CCD needs AMD's driver + Balanced-based plan
  if (p.cpu.x3dDual && !p.cpu.x3dDriver) add('x3d', 'bad', 'AMD 3D V-Cache driver not detected', 'Dual-CCD X3D CPUs need the AMD chipset driver\'s 3D V-Cache Performance Optimizer so games run on the cache CCD.', 'Install the latest AMD chipset driver, keep Game Mode on, and use the Falcon X3D plan.');

  // Disk space / pagefile
  if (s.systemDriveFreeGb != null && s.systemDriveFreeGb < 20) add('disk', 'bad', `Only ${s.systemDriveFreeGb} GB free on the system drive`, 'Low free space slows the page file, shader caches and updates, and SSDs lose write performance when nearly full.', 'Run Speed Boost to clear caches and leftovers, then uninstall games you no longer play. Aim for 20–30 GB free.');
  if (s.pagefileMb === 0) add('pagefile', 'bad', 'Page file is disabled', 'Many games and drivers crash or stutter without a page file even with lots of RAM. Disabling it is an outdated tweak.', 'System Properties > Advanced > Performance > Virtual memory > "Automatically manage".');

  // Network
  if (p.net.wifiUp && !p.net.wiredUp) add('wifi', 'info', 'Playing over Wi-Fi', 'Wi-Fi adds jitter and periodic latency spikes no software tweak fully removes.', 'Use Ethernet for competitive play; otherwise see "Stop Wi-Fi background scanning".');


  const order = { bad: 0, warn: 1, info: 2, good: 3 };
  return out.sort((a, b2) => order[a.status] - order[b2.status]);
}

module.exports = { collectProfile, normalizeProfile, healthChecks };
