'use strict';
// Run with: npm test   (node:test, no extra dependencies)
const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { buildCatalog } = require('../catalog');
const { gameItems } = require('../catalog/games');
const { normalizeProfile, healthChecks } = require('../src/main/system');
const fx = require('./fixtures');

const build = (p, settings = {}) => buildCatalog({ profile: normalizeProfile(structuredClone(p)), settings });
const allSteps = (it) => [...(it.apply || []), ...(it.revert || []), ...(it.run || []), ...((it.options || []).flatMap((o) => o.apply))];

test('catalog builds cleanly for every hardware fixture', () => {
  for (const [name, p] of Object.entries(fx)) {
    const c = build(p);
    assert.deepEqual(c.errors, [], `${name}: ${c.errors.join('; ')}`);
    assert.ok(c.items.length >= 40, `${name}: catalog unexpectedly small`);
  }
});

test('every toggle can be undone (explicit revert, or a fix whose journal restores the original)', () => {
  for (const it of build(fx.desktopNvidia).items.filter((i) => i.kind === 'toggle')) {
    if ((it.revert || []).length === 0) assert.ok(it.tags.includes('fix'), `${it.id} has no revert steps and is not tagged fix`);
  }
});

test('choices: exactly one default; each mode picks at most one option', () => {
  for (const it of build(fx.desktopNvidia).items.filter((i) => i.kind === 'choice')) {
    assert.equal(it.options.filter((o) => o.isDefault).length, 1, it.id);
    for (const m of ['latency', 'fps']) assert.ok(it.options.filter((o) => o.presets.includes(m)).length <= 1, `${it.id}/${m}`);
  }
});

test('latency mode always has an answer where FPS mode does (input delay is never skipped)', () => {
  for (const p of Object.values(fx)) {
    for (const it of build(p).items) {
      if (it.kind === 'choice') {
        const fps = it.options.find((o) => o.presets.includes('fps'));
        const lat = it.options.find((o) => o.presets.includes('latency'));
        if (fps) assert.ok(lat, `${it.id}: FPS preset has an option but Latency does not`);
      } else if (it.presets.includes('fps') && !it.presets.includes('latency')) {
        assert.fail(`${it.id} is FPS-only — latency mode must include every tweak that costs no input delay`);
      }
    }
  }
});

test('Regular presets never include security trade-offs, advanced items or extreme strip-downs', () => {
  for (const it of build(fx.desktopNvidia).items) {
    if (it.category === 'security' || it.category === 'extreme') assert.equal(it.tier, 'extreme', `${it.id} must be extreme tier`);
    if (it.risk === 'advanced' && it.presets.length) assert.equal(it.tier, 'extreme', `${it.id}: advanced item in a Regular preset`);
    if (it.tier === 'extreme' && it.kind === 'toggle') assert.ok(it.tradeoff, `${it.id}: extreme items must say what breaks`);
  }
});

test('Regular presets keep Windows working the same (no feature removals)', () => {
  const removals = ['win.widgets_off', 'win.visual_effects_performance', 'win.background_apps_off', 'win.search_indexer_off', 'ext.services_strip', 'ext.remove_bloat_apps'];
  for (const id of removals) assert.equal(build(fx.desktopNvidia).items.find((i) => i.id === id).tier, 'extreme', id);
});

test('dual-CCD X3D keeps AMD core parking (Balanced-based plan in both modes)', () => {
  const plan = build(fx.desktopX3dDual).items.find((i) => i.id === 'power.plan');
  const pick = (m) => plan.options.find((o) => o.presets.includes(m));
  assert.equal(pick('latency').id, 'x3d');
  assert.equal(pick('fps').id, 'x3d');
  assert.ok(plan.options.find((o) => o.id === 'latency').naReason, 'latency plan must be marked N/A on dual-CCD X3D');
});

test('single-CCD / non-X3D desktops: latency plan disables C-states, FPS plan keeps them', () => {
  const plan = build(fx.desktopNvidia).items.find((i) => i.id === 'power.plan');
  assert.equal(plan.options.find((o) => o.presets.includes('latency')).id, 'latency');
  assert.equal(plan.options.find((o) => o.presets.includes('fps')).id, 'fps');
  const script = fs.readFileSync(path.join(__dirname, '..', 'scripts', 'powerplan.ps1'), 'utf8');
  assert.match(script, /\$Plan -eq 'latency' -and -not \$isLaptop\) \{ 1 \}/, 'idle disable must be latency-only and desktop-only');
});

test('laptops: battery-sensitive changes only touch "plugged in"', () => {
  const c = build(fx.laptopHybrid);
  assert.equal(c.items.find((i) => i.id === 'sched.dynamic_tick_off').applicable, false);
  assert.equal(c.items.find((i) => i.id === 'input.usb_selective_suspend_off').apply[0].scope, 'ac');
  for (const o of c.items.find((i) => i.id === 'power.plan').options) assert.match(o.apply[0].script, /-AcOnly/, o.id);
});

test('Windows 10: Windows 11-only items are N/A with a reason', () => {
  const c = build(fx.win10Desktop);
  for (const id of ['sched.global_timer_requests', 'sched.timer_service', 'gpu.windowed_flip_model', 'win.widgets_off', 'win.recall_off']) {
    const it = c.items.find((i) => i.id === id);
    assert.equal(it.applicable, false, id);
    assert.ok(it.naReason, id);
  }
});

test('no placebo / harmful legacy tweaks can creep back in', () => {
  const banned = [
    [/OptimizeNVIDIA|OptimizeGPUIdle/i, 'invented NVIDIA registry values'],
    [/\\kernel$/i, 'TscSyncPolicy', 'registry TscSyncPolicy is not read by Windows'],
    [/Memory Management$/i, 'DisablePagingExecutive', 'placebo'],
    [/Memory Management$/i, 'LargeSystemCache', 'hurts gaming workloads'],
    [/Psched$/i, 'NonBestEffortLimit', 'QoS 20% reservation myth'],
    [/(mouclass|kbdclass)\\Parameters$/i, /DataQueueSize/, 'can drop input events'],
    [/Tcpip6\\Parameters$/i, 'DisabledComponents', 'disabling IPv6 breaks things, gains nothing'],
    [/GameConfigStore$/i, 'GameDVR_FSEBehaviorMode', 'global FSO disable is outdated'],
    [/Windows Defender$/i, 'DisableAntiSpyware', 'ignored since 2020']
  ];
  for (const it of build(fx.desktopNvidia).items) {
    for (const s of allSteps(it)) {
      if (s.type === 'reg' && !s.delete) {
        for (const rule of banned) {
          const [pathRe, nameRule] = rule.length === 3 ? rule : [rule[0], null];
          const nameOk = nameRule == null ? true : (nameRule instanceof RegExp ? nameRule.test(s.name) : s.name === nameRule);
          const hit = nameRule == null ? (pathRe.test(s.path) || pathRe.test(s.name)) : (pathRe.test(s.path) && nameOk);
          assert.ok(!hit, `${it.id}: ${s.path}\\${s.name} (${rule[rule.length - 1]})`);
        }
      }
      if (s.type === 'ps') {
        assert.doesNotMatch(s.script, /autotuninglevel=disabled/i, `${it.id}: disabling TCP auto-tuning`);
        assert.doesNotMatch(s.script, /useplatformclock\s+(yes|true)/i, `${it.id}: forcing HPET`);
      }
      if (s.type === 'bcd') assert.ok(!(s.name === 'useplatformclock' && !s.delete), `${it.id}: forcing HPET`);
    }
  }
});

test('per-game items: GPU preference only on hybrid-graphics systems', () => {
  const game = { id: 'cs2', name: 'CS2', exe: 'cs2.exe', exePath: 'C:\\Games\\cs2\\game\\bin\\win64\\cs2.exe', installDir: 'C:\\Games\\cs2\\game\\bin\\win64' };
  const desk = gameItems(game, normalizeProfile(structuredClone(fx.desktopNvidia)));
  const lap = gameItems(game, normalizeProfile(structuredClone(fx.laptopHybrid)));
  assert.ok(!desk.some((i) => i.id.endsWith('gpu_high_perf')));
  assert.ok(lap.some((i) => i.id.endsWith('gpu_high_perf')));
  for (const it of lap) assert.ok(it.revert.length > 0, it.id);
});

test('health checks flag the classic misconfigurations', () => {
  const p = normalizeProfile(structuredClone(fx.desktopNvidia));
  p.displays = [{ device: 'D1', adapter: 'GPU', resolution: '2560x1440', refreshHz: 60, maxRefreshHz: 240 }];
  p.ram = { totalGb: 32, modules: 2, ratedMTs: 6000, configuredMTs: 4800 };
  p.state = { ...p.state, powerPlan: 'Power saver', forcedPlatformClock: true, pagefileMb: 0 };
  const ids = healthChecks(p).filter((h) => h.status === 'bad').map((h) => h.id);
  for (const want of ['refresh-D1', 'xmp', 'powerplan', 'hpet', 'pagefile']) assert.ok(ids.includes(want), `missing ${want}`);
});

test('Speed Boost cleaner only targets rebuildable caches/logs', () => {
  const { targets, groups } = require('../data/cleaner.json');
  assert.ok(targets.length >= 30, 'expected ~30 cleaners');
  const ids = new Set();
  for (const t of targets) {
    assert.ok(!ids.has(t.id), `duplicate ${t.id}`); ids.add(t.id);
    assert.ok(groups.includes(t.group), `${t.id}: unknown group`);
    if (t.special) continue;
    for (const p of t.paths) {
      assert.doesNotMatch(p, /prefetch|tdata|\\Documents|\\Desktop|\\Pictures|\\Saved\\SaveGames|OfficeFileCache/i, `${t.id}: ${p}`);
      if (p !== '%TEMP%') assert.match(p, /\\./, `${t.id}: path must point inside a folder: ${p}`);
      assert.ok(!/^%(WINDIR|SystemDrive|USERPROFILE|APPDATA|LOCALAPPDATA|ProgramData)%\\?$/i.test(p), `${t.id}: bare root ${p}`);
    }
  }
});

test('every embedded PowerShell snippet parses', { skip: process.platform !== 'win32' }, () => {
  const c = build(fx.desktopNvidia);
  const scripts = [];
  for (const it of c.items) for (const s of allSteps(it)) if (s.type === 'ps') { scripts.push({ id: it.id, code: s.script }); if (s.check) scripts.push({ id: `${it.id} (check)`, code: s.check }); }
  const g = { id: 'x', name: 'X', exe: "it's.exe", exePath: "C:\\it's\\it's.exe", installDir: "C:\\it's" };
  for (const it of gameItems(g, normalizeProfile(structuredClone(fx.laptopHybrid)))) for (const s of allSteps(it)) if (s.type === 'ps') { scripts.push({ id: it.id, code: s.script }); if (s.check) scripts.push({ id: `${it.id} (check)`, code: s.check }); }
  const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'falcon-test-')), 'scripts.json');
  fs.writeFileSync(file, JSON.stringify(scripts));
  const ps = `$s = Get-Content -Raw '${file}' | ConvertFrom-Json; $bad = @(); foreach ($x in $s) { $e = $null; [void][System.Management.Automation.Language.Parser]::ParseInput($x.code, [ref]$null, [ref]$e); if ($e) { $bad += ($x.id + ': ' + $e[0].Message) } }; $bad -join [Environment]::NewLine`;
  const out = execFileSync('powershell.exe', ['-NoProfile', '-Command', ps], { encoding: 'utf8' }).trim();
  assert.equal(out, '', out);
  assert.ok(scripts.length > 20);
});

test('engine and helper scripts parse', { skip: process.platform !== 'win32' }, () => {
  const dir = path.join(__dirname, '..', 'scripts');
  for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.ps1'))) {
    const ps = `$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile('${path.join(dir, f)}', [ref]$null, [ref]$e); ($e | ForEach-Object { $_.Message + ' @' + $_.Extent.StartLineNumber }) -join '; '`;
    assert.equal(execFileSync('powershell.exe', ['-NoProfile', '-Command', ps], { encoding: 'utf8' }).trim(), '', f);
  }
});
