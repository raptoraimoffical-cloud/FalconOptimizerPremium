'use strict';
/**
 * Installed-game discovery. Reads launcher metadata instead of guessing paths:
 *   Steam  libraryfolders.vdf + appmanifest_<id>.acf
 *   Epic   %ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item
 *   Riot   %ProgramData%\Riot Games\Metadata\<product>\*.product_settings.yaml
 *   other  known default folders from data/games.json, plus user-added executables
 */
const fs = require('fs');
const path = require('path');
const { run } = require('./ps');

const exists = (p) => { try { return fs.existsSync(p); } catch (_) { return false; } };
const readText = (p) => { try { return fs.readFileSync(p, 'utf8'); } catch (_) { return null; } };
const expandEnv = (s) => String(s).replace(/%([^%]+)%/g, (_, k) => process.env[k] || process.env[k.toUpperCase()] || '');

/**
 * Breadth-first search for any of the exe names (case-insensitive) under root.
 * Async on purpose: a synchronous crawl of big game folders would freeze the Electron main process.
 */
async function findExe(root, exes, maxDepth = 6, maxDirs = 3000) {
  if (!root || !exists(root)) return null;
  const want = new Set(exes.map((e) => e.toLowerCase()));
  const queue = [[root, 0]];
  let visited = 0;
  while (queue.length && visited < maxDirs) {
    const [dir, depth] = queue.shift();
    visited++;
    let entries;
    try { entries = await fs.promises.readdir(dir, { withFileTypes: true }); } catch (_) { continue; }
    for (const e of entries) {
      if (e.isFile() && want.has(e.name.toLowerCase())) return path.join(dir, e.name);
    }
    if (depth < maxDepth) {
      for (const e of entries) {
        if (e.isDirectory() && !/^(\$|redist|_commonredist|directx|vcredist|support|crashreport|easyanticheat|battleye)/i.test(e.name)) queue.push([path.join(dir, e.name), depth + 1]);
      }
    }
  }
  return null;
}

async function steamRoot() {
  const r = await run('reg.exe', ['query', 'HKCU\\Software\\Valve\\Steam', '/v', 'SteamPath'], { timeoutMs: 8000 });
  const m = /SteamPath\s+REG_SZ\s+(.+)/i.exec(r.stdout || '');
  if (m) return m[1].trim().replace(/\//g, '\\');
  for (const c of [path.join(process.env['ProgramFiles(x86)'] || '', 'Steam'), path.join(process.env.ProgramFiles || '', 'Steam')]) if (exists(c)) return c;
  return null;
}

async function steamApps() {
  const root = await steamRoot();
  if (!root) return new Map();
  const libs = new Set([root]);
  const vdf = readText(path.join(root, 'steamapps', 'libraryfolders.vdf')) || '';
  for (const m of vdf.matchAll(/"path"\s+"([^"]+)"/g)) libs.add(m[1].replace(/\\\\/g, '\\'));
  const apps = new Map(); // appid -> install dir
  for (const lib of libs) {
    const sa = path.join(lib, 'steamapps');
    let files = [];
    try { files = fs.readdirSync(sa).filter((f) => /^appmanifest_\d+\.acf$/i.test(f)); } catch (_) { continue; }
    for (const f of files) {
      const acf = readText(path.join(sa, f)) || '';
      const id = /"appid"\s+"(\d+)"/.exec(acf);
      const dir = /"installdir"\s+"([^"]+)"/.exec(acf);
      if (id && dir) apps.set(Number(id[1]), path.join(sa, 'common', dir[1]));
    }
  }
  return apps;
}

function epicApps() {
  const dir = path.join(process.env.ProgramData || 'C:\\ProgramData', 'Epic', 'EpicGamesLauncher', 'Data', 'Manifests');
  const out = [];
  let files = [];
  try { files = fs.readdirSync(dir).filter((f) => f.toLowerCase().endsWith('.item')); } catch (_) { return out; }
  for (const f of files) {
    try {
      const j = JSON.parse(readText(path.join(dir, f)));
      if (j && j.InstallLocation && j.LaunchExecutable) {
        out.push({ appName: j.AppName || '', displayName: j.DisplayName || '', installDir: j.InstallLocation, exe: path.join(j.InstallLocation, j.LaunchExecutable) });
      }
    } catch (_) {}
  }
  return out;
}

function riotInstall(product) {
  const p = path.join(process.env.ProgramData || 'C:\\ProgramData', 'Riot Games', 'Metadata', `${product}.live`, `${product}.live.product_settings.yaml`);
  const y = readText(p);
  const m = y && /product_install_full_path:\s*"?([^"\r\n]+)"?/.exec(y);
  if (m) return m[1].trim().replace(/\//g, '\\');
  const fallback = { valorant: 'C:\\Riot Games\\VALORANT\\live', league_of_legends: 'C:\\Riot Games\\League of Legends' }[product];
  return fallback && exists(fallback) ? fallback : null;
}

const slug = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '').slice(0, 40);

/**
 * @param {string} appRoot
 * @param {{ id:string, name:string, exePath:string }[]} customGames
 */
async function discoverGames(appRoot, customGames = []) {
  const db = JSON.parse(readText(path.join(appRoot, 'data', 'games.json')) || '{"games":[]}').games || [];
  const steam = await steamApps();
  const epic = epicApps();
  const found = new Map();
  const add = (g, exePath, store) => {
    if (!exePath || found.has(g.id)) return;
    found.set(g.id, { id: g.id, name: g.name, exePath, exe: path.basename(exePath), installDir: path.dirname(exePath), store, tips: g.tips || [], known: !!g.known, steamAppId: g.steam || null });
  };

  // Resolve every known game in parallel; each lookup is an async, bounded folder search.
  await Promise.all(db.map(async (g0) => {
    const g = { ...g0, known: true };
    if (g.steam && steam.has(g.steam)) add(g, await findExe(steam.get(g.steam), g.exes), 'Steam');
    if (g.epic) {
      const m = epic.find((e) => e.appName.toLowerCase().includes(g.epic.toLowerCase()) || e.displayName.toLowerCase().includes(g.epic.toLowerCase()));
      if (m) add(g, (await findExe(m.installDir, g.exes)) || (exists(m.exe) ? m.exe : null), 'Epic');
    }
    if (g.riot) { const dir = riotInstall(g.riot); if (dir) add(g, await findExe(dir, g.exes), 'Riot'); }
    for (const d of g.dirs || []) { const dir = expandEnv(d); if (/^[A-Za-z]:\\./.test(dir)) add(g, await findExe(dir, g.exes), 'Local'); }
  }));

  // Every other Epic game is discoverable generically from its manifest.
  for (const e of epic) {
    const id = `epic_${slug(e.appName || e.displayName)}`;
    if ([...found.values()].some((x) => x.exePath.toLowerCase().startsWith(e.installDir.toLowerCase()))) continue;
    if (exists(e.exe) && !/launcher|uninstall/i.test(path.basename(e.exe))) add({ id, name: e.displayName || e.appName, tips: [] }, e.exe, 'Epic');
  }

  for (const c of customGames || []) {
    if (c && c.exePath && exists(c.exePath)) add({ id: c.id || `custom_${slug(path.basename(c.exePath, '.exe'))}`, name: c.name || path.basename(c.exePath, '.exe'), tips: [] }, c.exePath, 'Custom');
  }
  return [...found.values()].sort((a, b) => a.name.localeCompare(b.name));
}

module.exports = { discoverGames, slug };
