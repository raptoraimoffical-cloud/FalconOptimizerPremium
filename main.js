'use strict';
/**
 * Falcon Optimizer 2 — main process.
 *
 *   catalog/        curated tweak catalog (JS modules, hardware-aware)
 *   scripts/        engine.ps1 (apply/revert/detect + journal), system profile, power plan, timer
 *   src/main/       process helpers, system profile + health checks, game discovery, updater
 *   app/            renderer (vanilla JS, no build step)
 */
const { app, BrowserWindow, ipcMain, shell, dialog, net } = require('electron');
const fs = require('fs');
const path = require('path');

const { buildCatalog, engineItem } = require('./catalog');
const { gameItems } = require('./catalog/games');
const { runEngine, runPowerShellFile, isElevated, psQuote, runPowerShellCommand } = require('./src/main/ps');
const { collectProfile, healthChecks } = require('./src/main/system');
const { discoverGames, slug } = require('./src/main/games');
const updater = require('./src/main/updater');

// Scripts must be real files on disk for powershell.exe, so packaged builds read them from app.asar.unpacked.
const APP_ROOT = app.isPackaged ? path.join(process.resourcesPath, 'app.asar.unpacked') : __dirname;
const DATA_DIR = path.join(process.env.ProgramData || 'C:\\ProgramData', 'FalconOptimizer');

// ------------------------------------------------------------------ persisted state
const DEFAULT_SETTINGS = { mode: 'latency', tier: 'regular', timerResolution: 5000, createRestorePoint: true, dryRun: false, theme: 'dark', accent: 'falcon', customGames: [] };
let settingsFile, stateFile, historyFile;
let settings = { ...DEFAULT_SETTINGS };
let falconState = { applied: {} }; // id -> optionId|true for everything Falcon applied (for "Undo all")
let history = [];

const readJson = (f, fb) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch (_) { return fb; } };
const writeJson = (f, v) => { try { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, JSON.stringify(v, null, 2)); } catch (e) { console.error('write failed', f, e); } };

function loadPersisted() {
  const ud = app.getPath('userData');
  settingsFile = path.join(ud, 'settings.json');
  stateFile = path.join(ud, 'falcon-state.json');
  historyFile = path.join(ud, 'history.json');
  settings = { ...DEFAULT_SETTINGS, ...readJson(settingsFile, {}) };
  falconState = { applied: {}, ...readJson(stateFile, {}) };
  history = readJson(historyFile, []);
  if (!Array.isArray(history)) history = [];
}
const saveSettings = () => writeJson(settingsFile, settings);
const saveState = () => writeJson(stateFile, falconState);
function pushHistory(entry) {
  history.unshift({ ts: new Date().toISOString(), ...entry });
  history = history.slice(0, 200);
  writeJson(historyFile, history);
}

// ------------------------------------------------------------------ profile + catalog cache
let profile = null;
let profilePromise = null;
let catalog = null;
let games = [];

async function getProfile(force = false) {
  if (profile && !force) return profile;
  if (!profilePromise || force) {
    profilePromise = collectProfile(APP_ROOT).then((p) => { profile = p; catalog = null; return p; }).finally(() => { profilePromise = null; });
  }
  return profilePromise;
}

async function getCatalog() {
  if (catalog) return catalog;
  const p = await getProfile();
  catalog = buildCatalog({ profile: p, settings });
  if (catalog.errors.length) console.error('[catalog] validation errors:\n' + catalog.errors.join('\n'));
  return catalog;
}

const findItem = (cat, id) => cat.items.find((i) => i.id === id);

function gameItemIndex() {
  const map = new Map();
  for (const g of games) for (const it of gameItems(g, profile)) map.set(it.id, it);
  return map;
}

/** Resolve an item id (catalog or per-game) */
async function resolveItem(id) {
  const cat = await getCatalog();
  return findItem(cat, id) || gameItemIndex().get(id) || null;
}

// ------------------------------------------------------------------ detection
function detectPayload(items) {
  const out = [];
  for (const it of items) {
    if (it.kind === 'action' || it.applicable === false) continue;
    if (it.kind === 'choice') { for (const o of it.options) if (!o.naReason) out.push(engineItem(it, 'detect', o.id)); }
    else out.push(engineItem(it, 'detect'));
  }
  return out;
}

/** Map engine detect results back to item-level state: toggles -> state, choices -> active option. */
function foldStates(items, res) {
  const raw = new Map((res.items || []).map((r) => [r.id, r.state]));
  const states = {};
  for (const it of items) {
    if (it.kind === 'action') continue;
    if (it.applicable === false) { states[it.id] = { state: 'na' }; continue; }
    if (it.kind === 'choice') {
      const active = it.options.find((o) => raw.get(`${it.id}#${o.id}`) === 'applied' && !o.isDefault)
        || it.options.find((o) => raw.get(`${it.id}#${o.id}`) === 'applied');
      const anyUnknown = it.options.some((o) => raw.get(`${it.id}#${o.id}`) === 'unknown');
      states[it.id] = { state: active ? (active.isDefault ? 'not_applied' : 'applied') : (anyUnknown ? 'unknown' : 'custom'), option: active ? active.id : null };
    } else {
      states[it.id] = { state: raw.get(it.id) || 'unknown' };
    }
  }
  return states;
}

async function detectItems(items) {
  const payload = detectPayload(items);
  if (!payload.length) return {};
  const res = await runEngine(APP_ROOT, { mode: 'detect', items: payload }, { timeoutMs: 120000 });
  if (!res.ok && !res.items.length) throw new Error(res.error || 'Detection failed');
  return foldStates(items, res);
}

// ------------------------------------------------------------------ apply / revert
/**
 * @param {{ id:string, option?:string, action?:'apply'|'revert'|'run' }[]} requests
 */
async function execute(requests, { label, mode } = {}) {
  const applyBatch = [];
  const revertBatch = [];
  const meta = [];
  for (const r of requests) {
    const it = await resolveItem(r.id);
    if (!it) { meta.push({ id: r.id, ok: false, messages: ['Unknown item'] }); continue; }
    if (it.applicable === false) { meta.push({ id: r.id, ok: false, messages: [it.naReason || 'Not applicable on this PC'] }); continue; }
    if (it.kind === 'action') applyBatch.push({ ...engineItem(it), _req: r, _item: it });
    else if (it.kind === 'choice') {
      const optId = r.action === 'revert' ? (it.options.find((o) => o.isDefault) || {}).id : r.option;
      const opt = it.options.find((o) => o.id === optId);
      if (!opt) { meta.push({ id: r.id, ok: false, messages: ['Unknown option'] }); continue; }
      if (opt.naReason) { meta.push({ id: r.id, ok: false, messages: [opt.naReason] }); continue; }
      applyBatch.push({ ...engineItem(it, 'apply', opt.id), _req: { ...r, option: opt.id }, _item: it });
    } else if (r.action === 'revert') revertBatch.push({ ...engineItem(it), _req: r, _item: it });
    else applyBatch.push({ ...engineItem(it), _req: r, _item: it });
  }

  const strip = (b) => b.map(({ _req, _item, ...x }) => x);
  const results = [...meta];
  for (const [batch, engineMode] of [[revertBatch, 'revert'], [applyBatch, 'apply']]) {
    if (!batch.length) continue;
    const res = await runEngine(APP_ROOT, { mode: engineMode, dryRun: !!settings.dryRun, items: strip(batch) });
    if (res.cancelled) return { ok: false, cancelled: true, error: res.error, results };
    const byId = new Map((res.items || []).map((x) => [x.id, x]));
    for (const b of batch) {
      const r = byId.get(b.id) || { ok: false, messages: [res.error || 'No result from engine'] };
      const id = b._item.id;
      results.push({ id, option: b._req.option || null, action: engineMode === 'revert' ? 'revert' : (b._item.kind === 'action' ? 'run' : 'apply'), ok: !!r.ok, messages: r.messages || [], reboot: b._item.reboot });
      if (r.ok && !settings.dryRun && b._item.kind !== 'action') {
        const isDefault = b._item.kind === 'choice' && (b._item.options.find((o) => o.id === b._req.option) || {}).isDefault;
        if (engineMode === 'revert' || isDefault) delete falconState.applied[id];
        else falconState.applied[id] = b._req.option || true;
      }
    }
  }
  saveState();
  const ok = results.every((r) => r.ok);
  const entry = { label: label || (requests.length === 1 ? requests[0].id : `${requests.length} changes`), mode: mode || null, dryRun: !!settings.dryRun, ok, results };
  pushHistory(entry);
  const reboot = results.some((r) => r.ok && r.action !== 'run' && r.reboot === 'reboot') ? 'reboot'
    : results.some((r) => r.ok && r.reboot === 'signout') ? 'signout' : 'none';
  return { ok, results, reboot, dryRun: !!settings.dryRun };
}

/**
 * Items one-click Optimize would apply for a mode (latency|fps) and tier (regular|extreme),
 * skipping what is already in that state. Extreme = every regular item + every extreme item.
 */
async function planOptimize(mode, tier) {
  const cat = await getCatalog();
  const states = await detectItems(cat.items);
  const plan = [];
  for (const it of cat.items) {
    if (!it.applicable || it.kind === 'action') continue;
    const st = states[it.id] || {};
    if (it.kind === 'choice') {
      const opt = it.options.find((o) => o.presets.includes(mode) && !o.naReason);
      if (!opt) continue;
      if (st.option === opt.id) continue;
      plan.push({ id: it.id, option: opt.id, name: it.name, optionLabel: opt.label, category: it.category, risk: it.risk, reboot: it.reboot, impact: it.impact });
    } else {
      const inPreset = it.presets.includes(mode) && (tier === 'extreme' || it.tier !== 'extreme');
      if (!inPreset || st.state === 'applied' || st.state === 'na') continue;
      plan.push({ id: it.id, name: it.name, category: it.category, risk: it.risk, reboot: it.reboot, impact: it.impact, tier: it.tier, tradeoff: it.tradeoff || null });
    }
  }
  return { mode, tier, plan, states };
}

// ------------------------------------------------------------------ game artwork
// Steam header art (cached on disk) for titles with a Steam app id, plus the game's own exe icon
// as the logo for every game. Everything is returned as data: URLs so the renderer CSP stays 'self'.
const artCache = new Map();
async function steamHeader(appId) {
  const dir = path.join(app.getPath('userData'), 'art');
  const file = path.join(dir, `${appId}.jpg`);
  try { if (fs.existsSync(file)) return `data:image/jpeg;base64,${fs.readFileSync(file).toString('base64')}`; } catch (_) {}
  for (const url of [`https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg`, `https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/${appId}/header.jpg`]) {
    try {
      const ctl = new AbortController();
      const t = setTimeout(() => ctl.abort(), 6000);
      const r = await net.fetch(url, { signal: ctl.signal });
      clearTimeout(t);
      if (!r.ok) continue;
      const buf = Buffer.from(await r.arrayBuffer());
      if (buf.length < 1000) continue;
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(file, buf);
      return `data:image/jpeg;base64,${buf.toString('base64')}`;
    } catch (_) {}
  }
  return null;
}
async function gameArt(g) {
  if (artCache.has(g.id)) return artCache.get(g.id);
  let icon = null;
  try { const img = await app.getFileIcon(g.exePath, { size: 'large' }); if (img && !img.isEmpty()) icon = img.toDataURL(); } catch (_) {}
  const art = g.steamAppId ? await steamHeader(g.steamAppId) : null;
  const out = { icon, art };
  artCache.set(g.id, out);
  return out;
}

// ------------------------------------------------------------------ window
let win = null;
function createWindow() {
  win = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 980,
    minHeight: 640,
    backgroundColor: '#0d1016',
    title: 'Falcon Optimizer',
    autoHideMenuBar: true,
    webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, nodeIntegration: false, sandbox: true }
  });
  win.loadFile(path.join(__dirname, 'app', 'index.html'));
  if (process.env.FALCON_SCREENSHOT) {
    win.webContents.on('console-message', (_e, level, message) => console.log(`[renderer:${level}] ${message}`));
    win.webContents.once('did-finish-load', async () => {
      const dir = process.env.FALCON_SCREENSHOT;
      const routes = (process.env.FALCON_SCREENSHOT_ROUTES || 'dashboard,tweaks,games,tools,history,settings').split(',');
      const wait = (ms) => new Promise((r) => setTimeout(r, ms));
      console.log('[shot] page loaded, waiting for detection');
      await wait(Number(process.env.FALCON_SCREENSHOT_WAIT || 12000));
      for (const r of routes) {
        const [route, extra] = r.split(':');
        win.webContents.executeJavaScript(`go(${JSON.stringify(route)})${extra ? `; ${extra}` : ''}`).catch((e) => console.log('[shot] js error', e.message));
        await wait(route === 'games' ? 12000 : route === 'speedboost' ? 22000 : 5000);
        const img = await win.webContents.capturePage();
        fs.writeFileSync(path.join(dir, `${r.replace(/[^a-z0-9]+/gi, '_')}.png`), img.toPNG());
        console.log(`[shot] captured ${r}`);
      }
      app.quit();
    });
  }
  win.webContents.setWindowOpenHandler(({ url }) => { if (/^https:\/\//i.test(url)) shell.openExternal(url); return { action: 'deny' }; });
}

// ------------------------------------------------------------------ IPC
function handle(channel, fn) {
  ipcMain.handle(channel, async (_e, ...args) => {
    try { return await fn(...args); } catch (e) { console.error(channel, e); return { ok: false, error: String(e && e.message ? e.message : e) }; }
  });
}

function registerIpc() {
  handle('app:info', async () => ({ ok: true, version: app.getVersion(), isAdmin: await isElevated(), packaged: app.isPackaged, dataDir: DATA_DIR }));

  handle('settings:get', async () => ({ ok: true, settings }));
  handle('settings:set', async (patch) => {
    const before = settings.timerResolution;
    settings = { ...settings, ...(patch || {}) };
    saveSettings();
    if (patch && 'timerResolution' in patch && patch.timerResolution !== before) catalog = null; // item text + apply args depend on it
    return { ok: true, settings };
  });

  handle('system:profile', async (force) => {
    const p = await getProfile(!!force);
    return { ok: true, profile: p, health: healthChecks(p) };
  });

  handle('catalog:get', async () => {
    const cat = await getCatalog();
    return { ok: true, categories: cat.categories, items: cat.items, errors: cat.errors, applied: falconState.applied };
  });

  handle('catalog:detect', async (ids) => {
    const cat = await getCatalog();
    let items = cat.items;
    if (Array.isArray(ids) && ids.length) {
      const idx = gameItemIndex();
      items = ids.map((id) => findItem(cat, id) || idx.get(id)).filter(Boolean);
    }
    return { ok: true, states: await detectItems(items) };
  });

  handle('engine:execute', async (requests, opts) => execute(Array.isArray(requests) ? requests : [], opts || {}));

  handle('optimize:plan', async (mode, tier) => ({ ok: true, ...(await planOptimize(mode === 'fps' ? 'fps' : 'latency', tier === 'extreme' ? 'extreme' : 'regular')) }));
  handle('optimize:run', async (mode, items, { restorePoint, tier } = {}) => {
    const steps = [];
    if (restorePoint && !settings.dryRun) steps.push({ id: 'act.restore_point', action: 'run' });
    for (const it of items || []) steps.push({ id: it.id, option: it.option, action: 'apply' });
    const res = await execute(steps, { label: `Optimize — ${tier === 'extreme' ? 'Extreme' : 'Regular'} ${mode === 'fps' ? 'FPS' : 'Latency'}`, mode });
    settings.mode = mode; if (tier) settings.tier = tier; saveSettings();
    return res;
  });

  handle('undo:all', async () => {
    const reqs = Object.keys(falconState.applied).map((id) => ({ id, action: 'revert' }));
    if (!reqs.length) return { ok: true, results: [], reboot: 'none' };
    return execute(reqs, { label: 'Undo all Falcon changes' });
  });

  handle('history:get', async () => ({ ok: true, history }));
  handle('history:clear', async () => { history = []; writeJson(historyFile, history); return { ok: true }; });

  handle('games:list', async (rescan) => {
    if (rescan || !games.length) games = await discoverGames(APP_ROOT, settings.customGames);
    await getProfile();
    const withArt = await Promise.all(games.map(async (g) => ({ ...g, ...(await gameArt(g)), items: gameItems(g, profile) })));
    return { ok: true, games: withArt };
  });
  handle('games:addCustom', async () => {
    const r = await dialog.showOpenDialog(win, { title: 'Select the game executable', filters: [{ name: 'Executables', extensions: ['exe'] }], properties: ['openFile'] });
    if (r.canceled || !r.filePaths[0]) return { ok: false, cancelled: true };
    const exePath = r.filePaths[0];
    const name = path.basename(exePath, '.exe');
    settings.customGames = [...(settings.customGames || []).filter((g) => g.exePath !== exePath), { id: `custom_${slug(name)}`, name, exePath }];
    saveSettings();
    games = await discoverGames(APP_ROOT, settings.customGames);
    return { ok: true };
  });
  handle('games:removeCustom', async (id) => {
    settings.customGames = (settings.customGames || []).filter((g) => g.id !== id);
    saveSettings();
    games = await discoverGames(APP_ROOT, settings.customGames);
    return { ok: true };
  });

  // ---- Speed Boost cleaner
  const cleanerTargets = () => readJson(path.join(APP_ROOT, 'data', 'cleaner.json'), { groups: [], targets: [] });
  handle('cleaner:list', async () => ({ ok: true, ...cleanerTargets() }));
  handle('cleaner:run', async (mode, ids) => {
    const all = cleanerTargets().targets;
    const targets = Array.isArray(ids) && ids.length ? all.filter((t) => ids.includes(t.id)) : all;
    const scan = mode !== 'clean';
    if (!scan && settings.dryRun) return { ok: true, dryRun: true, targets: [], freedBytes: 0 };
    const res = await runEngine(APP_ROOT, { mode: scan ? 'scan' : 'clean', targets }, { script: 'cleaner.ps1', timeoutMs: 15 * 60 * 1000 });
    if (res.cancelled) return res;
    res.targets = Array.isArray(res.targets) ? res.targets : (res.targets ? [res.targets] : []);
    if (!scan) {
      const mb = (b) => `${(b / 1048576).toFixed(0)} MB`;
      pushHistory({
        label: `Speed Boost cleanup — freed ${mb(res.freedBytes || 0)}`,
        ok: res.ok !== false,
        results: res.targets.map((t) => ({ id: `clean.${t.id}`, action: 'clean', ok: true, messages: [`${mb(t.freed || 0)} freed${t.skipped ? `, ${t.skipped} in-use file(s) skipped` : ''}`] }))
      });
    }
    return res;
  });

  handle('timer:status', async () => {
    const r = await runPowerShellFile(path.join(APP_ROOT, 'scripts', 'timer.ps1'), ['-Action', 'status'], { timeoutMs: 30000 });
    try { return { ok: true, status: JSON.parse(r.stdout.trim()) }; } catch (_) { return { ok: false, error: (r.stderr || r.stdout).trim() }; }
  });

  handle('tools:list', async () => ({ ok: true, tools: readJson(path.join(APP_ROOT, 'data', 'tools.json'), { tools: [] }).tools }));
  handle('tools:openFolder', async (rel) => {
    const target = path.resolve(APP_ROOT, String(rel || ''));
    if (!target.startsWith(path.resolve(APP_ROOT))) return { ok: false, error: 'Path outside app folder' };
    const err = await shell.openPath(target);
    return { ok: !err, error: err || undefined };
  });
  handle('tools:importNvidiaProfile', async () => {
    const r = await dialog.showOpenDialog(win, { title: 'Locate nvidiaProfileInspector.exe', filters: [{ name: 'NVIDIA Profile Inspector', extensions: ['exe'] }], properties: ['openFile'] });
    if (r.canceled || !r.filePaths[0]) return { ok: false, cancelled: true };
    const nip = path.join(APP_ROOT, 'assets', 'nvidia', 'Falcon-Competitive.nip');
    const cmd = `Start-Process -FilePath ${psQuote(r.filePaths[0])} -ArgumentList ${psQuote(`"${nip}"`)} -Verb RunAs`;
    const res = await runPowerShellCommand(cmd, { timeoutMs: 30000 });
    return { ok: res.code === 0, error: res.code === 0 ? undefined : res.stderr };
  });

  handle('shell:openExternal', async (url) => {
    if (!/^(https:\/\/|ms-settings:)/i.test(String(url))) return { ok: false, error: 'Blocked URL' };
    await shell.openExternal(String(url));
    return { ok: true };
  });
  handle('shell:openLogs', async () => {
    const dir = path.join(DATA_DIR, 'logs');
    fs.mkdirSync(dir, { recursive: true });
    const err = await shell.openPath(dir);
    return { ok: !err, error: err || undefined };
  });

  handle('app:relaunchAsAdmin', async () => {
    const exe = process.execPath;
    const args = app.isPackaged ? [] : [path.resolve(__dirname)];
    const argStr = args.map((a) => `"${a}"`).join(' ');
    const cmd = `Start-Process -FilePath ${psQuote(exe)} ${argStr ? `-ArgumentList ${psQuote(argStr)}` : ''} -Verb RunAs`;
    const r = await runPowerShellCommand(cmd, { timeoutMs: 30000 });
    if (r.code === 0) { setTimeout(() => app.quit(), 300); return { ok: true }; }
    return { ok: false, error: 'Administrator approval was declined.' };
  });

  handle('system:restart', async () => {
    const r = await runPowerShellCommand('shutdown.exe /r /t 5 /c "Falcon Optimizer: restarting to finish applying changes."', { timeoutMs: 15000 });
    return { ok: r.code === 0 };
  });

  updater.registerUpdaterIpc();
}

// ------------------------------------------------------------------ lifecycle
// Dev screenshot mode renders in software so it also works in headless/remote sessions.
if (process.env.FALCON_SCREENSHOT) {
  app.disableHardwareAcceleration();
  // Isolated profile: never touches real settings/history and never collides with a running instance.
  app.setPath('userData', path.join(process.env.FALCON_SCREENSHOT, '.userdata'));
}

if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  app.on('second-instance', () => { if (win) { if (win.isMinimized()) win.restore(); win.focus(); } });
  app.whenReady().then(() => {
    loadPersisted();
    registerIpc();
    createWindow();
    getProfile().catch((e) => console.error('profile', e)); // warm up in the background
    updater.setupAutoUpdater();
  });
  app.on('window-all-closed', () => app.quit());
  app.on('before-quit', () => updater.stopUpdater());
}
