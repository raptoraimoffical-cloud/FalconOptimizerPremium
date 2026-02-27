const { app, BrowserWindow, ipcMain, shell } = require("electron");
const os = require("os");
const path = require("path");
const fs = require("fs");
const { spawn } = require("child_process");

function runCommand(command, args = [], options = {}) {
  return new Promise((resolve) => {
    const p = spawn(command, args, { windowsHide: true, ...options });
    let stdout = "";
    let stderr = "";
    if (p.stdout) p.stdout.on("data", (d) => (stdout += d.toString()));
    if (p.stderr) p.stderr.on("data", (d) => (stderr += d.toString()));
    p.on("error", (e) => resolve({ code: -1, stdout, stderr: String(e) }));
    p.on("close", (code) => resolve({ code: typeof code === "number" ? code : -1, stdout, stderr }));
  });
}

async function runPowerShell(script) {
  return await runCommand("powershell.exe", [
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command", script
  ]);
}

async function isProcessElevatedAsync() {
  const r = await runCommand("net", ["session"], { stdio: "ignore" });
  return r && typeof r.code === "number" && r.code === 0;
}

const { JobManager } = require("./core/jobManager");
const { ActionRunner } = require("./core/actionRunner");
const { validateCatalogs } = require("./core/validator");
const securityHealth = require("./modules/security/healthCheck");
const { isProtected: isProtectedService } = require("./modules/security/protectedServices");

let stateFile = null;
let toggleState = {};

let historyFile = null;
let historyState = { version: 1, sessions: [] };
let jobManager = null;
let actionRunner = null;
let currentSessionId = null;
let _fileReaderIpcRegistered = false;

function nowIso() { return new Date().toISOString(); }

function safeJsonRead(filePath, fallback) {
  try {
    if (filePath && fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, "utf8") || "null") || fallback;
    }
  } catch (_) {}
  return fallback;
}

function safeJsonWrite(filePath, obj) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(obj, null, 2), "utf8");
    return true;
  } catch (_) {
    return false;
  }
}

function loadState() {
  toggleState = safeJsonRead(stateFile, {});
}

function saveState() {
  safeJsonWrite(stateFile, toggleState || {});
}

function loadHistory() {
  historyState = safeJsonRead(historyFile, { version: 1, sessions: [] });
  if (!historyState || typeof historyState !== "object") historyState = { version: 1, sessions: [] };
}

function saveHistory() {
  safeJsonWrite(historyFile, historyState);
}

function ensureSession() {
  if (!currentSessionId) currentSessionId = "session_" + Date.now();
  let s = (historyState.sessions || []).find(x => x && x.id === currentSessionId);
  if (!s) {
    s = { id: currentSessionId, startedAt: nowIso(), entries: [] };
    historyState.sessions = historyState.sessions || [];
    historyState.sessions.push(s);
    saveHistory();
  }
  return s;
}


function __cleanLabel(s){
  try{
    s = String(s||"").trim();
    if(!s) return s;
    // Remove internal/import tags from UI labels
    s = s.replace(/\bOneclick\b/ig, "").replace(/\bone\s*click\b/ig,"");
    s = s.replace(/\bimported\b/ig, "").replace(/\bprocess\s*destroyer\b/ig,"");
    s = s.replace(/[_\.]+/g," ").replace(/\s{2,}/g," ").trim();
    return s || String(s||"").trim();
  }catch(_){ return String(s||""); }
}

function __readTail(filePath, maxBytes=16384){
  try{
    if(!filePath) return "";
    if(!fs.existsSync(filePath)) return "";
    const st = fs.statSync(filePath);
    const size = st.size || 0;
    const start = Math.max(0, size - maxBytes);
    const fd = fs.openSync(filePath, "r");
    try{
      const buf = Buffer.alloc(size-start);
      fs.readSync(fd, buf, 0, buf.length, start);
      return buf.toString("utf8").trim();
    } finally {
      try{ fs.closeSync(fd);}catch(_){}
    }
  }catch(_){ return ""; }
}
function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 760,
    backgroundColor: "#0b0f14",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

// --- Local file readers for renderer (fixes file:// fetch issues) ---
function getProjectRoot(){
  return app.isPackaged
    ? path.join(process.resourcesPath, "app.asar.unpacked")
    : __dirname;
}

function resolveRelPath(rel){
  const p = String(rel || "").replace(/\\/g, "/").trim();
  if (!p) throw new Error("Missing path.");
  if (p.includes("..")) throw new Error("Blocked path traversal.");
  if (p.startsWith("/") || /^[a-zA-Z]:\//.test(p)) throw new Error("Absolute paths are not allowed.");
  if (p.startsWith("file:") || p.startsWith("http:") || p.startsWith("https:")) throw new Error("Protocol paths are not allowed.");

  // Allow only known asset folders
  const allowedRoots = ["tweaks/", "themesystem/", "assets/", "data/"];
  const ok = allowedRoots.some(r => p.toLowerCase().startsWith(r));
  if (!ok) throw new Error("Path not allowed: " + p);

  const root = getProjectRoot();
  const abs = path.join(root, p);
  const normRoot = path.resolve(root) + path.sep;
  const normAbs = path.resolve(abs);
  if (!normAbs.startsWith(normRoot)) throw new Error("Resolved path escaped root.");
  return normAbs;
}

if (!_fileReaderIpcRegistered) {
ipcMain.handle("falcon:readText", async (_evt, payload) => {
  try {
    const abs = resolveRelPath(payload && payload.path);
    const txt = fs.readFileSync(abs, "utf8");
    return { ok: true, text: txt };
  } catch (e) {
    return { ok: false, error: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:readJson", async (_evt, payload) => {
  try {
    const abs = resolveRelPath(payload && payload.path);
    const raw = fs.readFileSync(abs, "utf8");
    const obj = JSON.parse(raw);
    return { ok: true, json: obj };
  } catch (e) {
    return { ok: false, error: String(e && e.message ? e.message : e) };
  }
});
  _fileReaderIpcRegistered = true;
}

  win.loadFile(path.join(__dirname, "index.html"));
}


async function runPsSteps(payload) {
  const projectRoot = app.isPackaged
    ? path.join(process.resourcesPath, "app.asar.unpacked")
    : __dirname;

  const ps1 = path.join(projectRoot, "scripts", "run-action.ps1");
  const elevatePs1 = path.join(projectRoot, "scripts", "elevate-run.ps1");

  // Write payload to a temp file and pass the path.
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "FalconSteps-"));
  const jsonPath = path.join(tempDir, "steps.json");
  const resultPath = path.join(tempDir, "result.json");

  try {
    fs.writeFileSync(jsonPath, JSON.stringify(payload || { steps: [] }), "utf8");
  } catch (e) {
    return Promise.resolve({ ok: false, rawStdout: "", rawStderr: "Failed to write temp payload: " + String(e), logFile: null });
  }

  const elevated = await isProcessElevatedAsync();

  return new Promise((resolve) => {
    const args = elevated
      ? [
          "-NoProfile",
          "-ExecutionPolicy", "Bypass",
          "-File", ps1,
          "-JsonFile", jsonPath,
          "-ResultFile", resultPath
        ]
      : [
          "-NoProfile",
          "-ExecutionPolicy", "Bypass",
          "-File", elevatePs1,
          "-Script", ps1,
          "-JsonFile", jsonPath,
          "-ResultFile", resultPath
        ];

    const p = spawn("powershell.exe", args, { cwd: projectRoot, windowsHide: true });

    let stdout = "";
    let stderr = "";
    let finished = false;

    function cleanupTemp() {
      try { fs.unlinkSync(jsonPath); } catch (_) {}
      try { fs.unlinkSync(resultPath); } catch (_) {}
      try { fs.rmdirSync(tempDir); } catch (_) {}
    }

    function finish(fromTimeout) {
      if (finished) return;
      finished = true;

      let parsed = null;

      // Prefer result file (works for elevated runs).
      try {
        if (fs.existsSync(resultPath)) {
          const txt = fs.readFileSync(resultPath, "utf8").trim();
          parsed = txt ? JSON.parse(txt) : null;
        }
      } catch (_) { parsed = null; }

      // Fallback to stdout JSON (non-elevated legacy behavior).
      if (!parsed) {
        const out = (stdout || "").trim();
        try { parsed = out ? JSON.parse(out) : null; } catch (_) { parsed = null; }
      }

      cleanupTemp();

      if (fromTimeout) {
        return resolve({ ok: false, rawStdout: stdout, rawStderr: (stderr || "") + "\nTIMEOUT", logFile: null });
      }

      if (parsed && typeof parsed === "object") {
        parsed.rawStdout = stdout;
        parsed.rawStderr = stderr;
        try{
          // If elevated run produced only a logFile, attach log tail as stdout so History has output.
          if ((!parsed.stdout || String(parsed.stdout).trim()==="") && parsed.logFile) {
            const tail = __readTail(parsed.logFile, 20000);
            if (tail) parsed.stdout = tail;
          }
          if ((!parsed.stderr || String(parsed.stderr).trim()==="") && stderr) {
            parsed.stderr = stderr;
          }
        }catch(_e){}

        return resolve(parsed);
      }

      resolve({ ok: (p.exitCode === 0), rawStdout: stdout, rawStderr: stderr, logFile: null });
    }

    const timer = setTimeout(() => {
      try { p.kill(); } catch (_) {}
      finish(true);
    }, 600000);

    p.stdout.on("data", (d) => (stdout += d.toString()));
    p.stderr.on("data", (d) => (stderr += d.toString()));
    p.on("close", (_code) => {
      clearTimeout(timer);
      finish(false);
    });
  });
}


// Run a PowerShell script directly (used for utilities like timer manager)
function runPsScript(scriptPath, args = []) {
  return new Promise((resolve) => {
    const projectRoot = app.isPackaged
      ? path.join(process.resourcesPath, "app.asar.unpacked")
      : __dirname;

    const p = spawn("powershell.exe", [
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", scriptPath,
      ...args
    ], { cwd: projectRoot, windowsHide: true });

    let stdout = "";
    let stderr = "";

    p.stdout.on("data", (d) => (stdout += d.toString()));
    p.stderr.on("data", (d) => (stderr += d.toString()));
    p.on("close", (code) => {
      resolve({ ok: code === 0, rawStdout: stdout, rawStderr: stderr });
    });
  });
}



function runPsFile(scriptRelPath, args = []) {
  const projectRoot = app.isPackaged
    ? path.join(process.resourcesPath, "app.asar.unpacked")
    : __dirname;

  const ps1 = path.join(projectRoot, scriptRelPath);
  return new Promise((resolve) => {
    const p = spawn("powershell.exe",
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps1, ...args],
      { cwd: projectRoot, windowsHide: true }
    );

    let stdout = "";
    let stderr = "";
    let finished = false;

    const finish = (code, fromTimeout) => {
      if (finished) return;
      finished = true;
      const out = (stdout || "").trim();
      const err = (stderr || "").trim();
      const ok = (code === 0) && !fromTimeout;
      resolve({
        ok,
        code,
        stdout: out,
        stderr: fromTimeout
          ? [err, "Timed out while running PowerShell helper."].filter(Boolean).join(" | ")
          : err
      });
    };

    // Global safety timeout so a hung PS script can't freeze navigation forever
    const timeoutMs = 600000; // 10 minutes
    const timer = setTimeout(() => {
      try { p.kill(); } catch (_) {}
      finish(-1, true);
    }, timeoutMs);

    p.stdout.on("data", (d) => (stdout += d.toString()));
    p.stderr.on("data", (d) => (stderr += d.toString()));
    p.on("close", (code) => {
      clearTimeout(timer);
      finish(code || 0, false);
    });
  });
}
// --- IPC: Run raw steps (legacy) ---
ipcMain.handle("falcon:runSteps", async (_evt, payload) => {
  const steps = (payload && Array.isArray(payload.steps)) ? payload.steps : [];
  const meta = (payload && payload.meta && typeof payload.meta === "object") ? payload.meta : {};
  const id = (meta && (meta.id || meta.name || meta.title)) ? String(meta.id || meta.name || meta.title) : "rawSteps";
  const runner = async () => {
    if (!actionRunner) return await runPsSteps({ steps, meta });
    return await actionRunner.runSteps({ steps, meta });
  };

  if (!jobManager) {
    try {
      const res = await runner();
      // Best-effort history fallback
      try {
        const session = ensureSession();
        session.entries.push({ ts: nowIso(), id, mode: "apply", ok: !!res.ok, logFile: res.logFile || null, meta, label: __cleanLabel((meta && (meta.title || meta.name)) ? (meta.title || meta.name) : id), stdout: (res.rawStdout && String(res.rawStdout).trim()) ? res.rawStdout : ((res.stdout && String(res.stdout).trim()) ? res.stdout : (__readTail(res.logFile, 20000) || "")), stderr: (res.rawStderr && String(res.rawStderr).trim()) ? res.rawStderr : ((res.stderr && String(res.stderr).trim()) ? res.stderr : "") });
        saveHistory();
      } catch (_) {}
      return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "", logFile: res.logFile || null };
    } catch (e) {
      return { ok: false, stdout: "", stderr: String(e && e.message ? e.message : e), logFile: null };
    }
  }

  const res = await jobManager.enqueue({ id, mode: "apply", stepsCount: steps.length, meta }, runner);
  // Sync legacy references
  historyState = jobManager.getHistory();
  currentSessionId = jobManager.currentSessionId || currentSessionId;

  return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "", logFile: res.logFile || null };
});

// --- IPC: Run a tweak (records history, supports simulation in UI via separate endpoint) ---
ipcMain.handle("falcon:runTweak", async (_evt, payload) => {
  const id = payload && payload.id ? String(payload.id) : "";
  const mode = payload && payload.mode ? String(payload.mode) : "apply";
  const steps = payload && Array.isArray(payload.steps) ? payload.steps : [];
  const revertSteps = payload && Array.isArray(payload.revertSteps) ? payload.revertSteps : [];
  const meta = (payload && payload.meta && typeof payload.meta === "object") ? payload.meta : {};

  const runner = async () => {
    if (!actionRunner) return await runPsSteps({ steps, meta });
    const r = await actionRunner.runTweak({ id, mode, steps, meta, revertSteps });
    return r;
  };

  if (!id) return { ok: false, stdout: "", stderr: "Missing id.", logFile: null };
  if (!steps.length) return { ok: false, stdout: "", stderr: "No runnable steps.", logFile: null };

  if (!jobManager) {
    const res = await runner();
    // legacy history
    const session = ensureSession();
    session.entries.push({ ts: nowIso(), id, mode, ok: !!res.ok, logFile: res.logFile || null, meta, label: __cleanLabel((meta && (meta.title || meta.name)) ? (meta.title || meta.name) : id), stdout: (res.rawStdout && String(res.rawStdout).trim()) ? res.rawStdout : ((res.stdout && String(res.stdout).trim()) ? res.stdout : (__readTail(res.logFile, 20000) || "")), stderr: (res.rawStderr && String(res.rawStderr).trim()) ? res.rawStderr : ((res.stderr && String(res.stderr).trim()) ? res.stderr : ""), revertSteps: (mode === "apply") ? revertSteps : undefined });
    saveHistory();
    return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "", logFile: res.logFile || null };
  }

  const res = await jobManager.enqueue(
    { id, mode, stepsCount: steps.length, meta, entryExtra: { revertSteps: (mode === "apply") ? revertSteps : undefined } },
    runner
  );

  historyState = jobManager.getHistory();
  currentSessionId = jobManager.currentSessionId || currentSessionId;

  return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "", logFile: res.logFile || null };
});

ipcMain.handle("falcon:dryRunSteps", async (_evt, payload) => {
  const steps = (payload && Array.isArray(payload.steps)) ? payload.steps : [];
  return {
    ok: true,
    plan: steps.map((s, i) => ({ i, type: s.type, step: s }))
  };
});

// --- IPC: Backups ---
ipcMain.handle("falcon:createBackup", async () => {
  return await runPsFile(path.join("scripts", "snapshot.ps1"));
});

ipcMain.handle("falcon:restoreBackup", async () => {
  return await runPsFile(path.join("scripts", "restore.ps1"));
});

// --- IPC: Undo ---
ipcMain.handle("falcon:getHistory", async () => {
  if (jobManager) {
    historyState = jobManager.getHistory();
    currentSessionId = jobManager.currentSessionId || currentSessionId;
  }
  return historyState || { version: 1, sessions: [] };
});

ipcMain.handle("falcon:undoLastSession", async () => {
  const s = (historyState.sessions || []).find(x => x && x.id === currentSessionId);
  if (!s || !Array.isArray(s.entries) || !s.entries.length) {
    return { ok: false, stdout: "", stderr: "No entries in current session.", logFile: null };
  }
  // Revert applied entries in reverse order (only apply entries with stored revertSteps)
  const rev = s.entries.filter(e => e && e.mode === "apply" && Array.isArray(e.revertSteps) && e.revertSteps.length).reverse();
  let combined = "";
  let allOk = true;
  for (const e of rev) {
    const r = await runPsSteps({ steps: e.revertSteps });
    allOk = allOk && !!r.ok;
    combined += (r.rawStdout || "") + "\n" + (r.rawStderr || "") + "\n";
  }
  return { ok: allOk, stdout: combined.trim(), stderr: "", logFile: null };
});

ipcMain.handle("falcon:undoAll", async () => {
  const sessions = Array.isArray(historyState.sessions) ? historyState.sessions : [];
  const entries = [];
  for (const s of sessions) {
    if (s && Array.isArray(s.entries)) entries.push(...s.entries);
  }
  const rev = entries.filter(e => e && e.mode === "apply" && Array.isArray(e.revertSteps) && e.revertSteps.length).reverse();
  if (!rev.length) return { ok: false, stdout: "", stderr: "No applied entries with revert steps.", logFile: null };

  let combined = "";
  let allOk = true;
  for (const e of rev) {
    const r = await runPsSteps({ steps: e.revertSteps });
    allOk = allOk && !!r.ok;
    combined += (r.rawStdout || "") + "\n" + (r.rawStderr || "") + "\n";
  }
  return { ok: allOk, stdout: combined.trim(), stderr: "", logFile: null };
});

// --- IPC: Toggle state persistence ---

ipcMain.handle("falcon:listProcesses", async () => {
  try {
    const res = await runCommand("tasklist", ["/FO", "CSV", "/NH"]);
    const stdout = res && res.stdout ? res.stdout.toString() : "";
    const lines = stdout.split(/\r?\n/).filter(Boolean);
    const processes = [];
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      const parts = trimmed.split('","').map(s => s.replace(/^"|"$/g, ''));
      if (parts.length >= 2) {
        const name = parts[0].trim();
        const pid = parseInt(parts[1], 10) || 0;
        if (name) processes.push({ name, pid });
      }
    }
    return { ok: true, processes };
  } catch (e) {
    return { ok: false, processes: [], error: String(e && e.message ? e.message : e) };
  }
});



ipcMain.handle("falcon:runProcessPreset", async (_evt, payload) => {
  const modeRaw = payload && payload.mode ? String(payload.mode) : 'safe';
  const mode = String(modeRaw || 'safe').toLowerCase();

  let effectiveMode = 'safe';
  if (mode === 'competitive') {
    effectiveMode = 'competitive';
  } else if (mode === 'extreme' || mode === 'full' || mode === 'fullgame') {
    effectiveMode = 'extreme';
  }

  const scriptRel = path.join('scripts', 'processlab-run.ps1');
  const args = ['-Mode', effectiveMode];
  return await runPsFile(scriptRel, args);
});




ipcMain.handle("falcon:runProcessCustomPreset", async (_evt, payload) => {
  try {
    const baseModeRaw = payload && payload.baseMode ? String(payload.baseMode) : 'competitive';
    const baseMode = String(baseModeRaw || 'competitive').toLowerCase();
    const overrides = (payload && payload.overrides && typeof payload.overrides === 'object')
      ? payload.overrides
      : {};

    const userDataDir = app.getPath('userData');
    const overridesPath = path.join(userDataDir, 'processlab-custom-overrides.json');

    const filePayload = { overrides };
    fs.writeFileSync(overridesPath, JSON.stringify(filePayload, null, 2), 'utf8');

    let effectiveMode = 'competitive';
    if (baseMode === 'extreme') {
      effectiveMode = 'extreme';
    } else if (baseMode === 'safe') {
      effectiveMode = 'safe';
    }

    const scriptRel = path.join('scripts', 'processlab-run.ps1');
    const args = ['-Mode', effectiveMode, '-OverridesPath', overridesPath];
    return await runPsFile(scriptRel, args);
  } catch (e) {
    return { ok: false, error: e && e.message ? e.message : String(e) };
  }
});
ipcMain.handle("falcon:restoreProcessLab", async () => {
  const scriptRel = path.join('scripts', 'processlab-restore.ps1');
  return await runPsFile(scriptRel);
});

ipcMain.handle("falcon:terminateProcesses", async (_evt, payload) => {
  try {
    const items = payload && Array.isArray(payload.processes) ? payload.processes : [];
    const results = [];
    for (const it of items) {
      const pid = it && it.pid ? parseInt(it.pid, 10) : 0;
      const name = it && it.name ? String(it.name) : '';
      if (!pid || pid <= 0) continue;
      try {
        const r = await runCommand("taskkill", ["/PID", String(pid), "/T", "/F"]);




        const stdout = r && r.stdout ? r.stdout.toString().trim() : "";
        const stderr = r && r.stderr ? r.stderr.toString().trim() : "";
        const ok = (r && (r.status === 0 || r.exitCode === 0));
        results.push({ pid, name, ok, stdout, stderr });
      } catch (e) {
        results.push({ pid, name, ok: false, stdout: "", stderr: String(e && e.message ? e.message : e) });
      }
    }
    return { ok: true, results };
  } catch (e) {
    return { ok: false, results: [], error: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:getState", async () => {
  return toggleState || {};
});

ipcMain.handle("falcon:setState", async (_evt, payload) => {
  const id = payload && payload.id ? String(payload.id) : "";
  const on = !!(payload && payload.on);
  if (id) {
    toggleState[id] = on;
    saveState();
  }
  return toggleState || {};
});


// --- IPC: System info (CPU / GPU / RAM / OS) ---

ipcMain.handle("falcon:getSystemInfo", async () => {
  const osmod = require("os");

  const cpus = (osmod.cpus && osmod.cpus()) || [];
  const cpu0 = cpus[0] || {};
  const cpuName = cpu0.model || "Unknown CPU";
  const cpuThreads = cpus.length || 0;
  const ramBytes = osmod.totalmem ? osmod.totalmem() : 0;
  const osType = osmod.type ? osmod.type() : "Windows";
  const osRel = osmod.release ? osmod.release() : "";
  let osVer = "";
  try {
    if (typeof osmod.version === "function") {
      osVer = osmod.version();
    }
  } catch (_) {}

  const baseInfo = {
    CPU: cpuName,
    CPUCores: cpuThreads,
    CPUThreads: cpuThreads,
    RAMBytes: ramBytes,
    OS: (osType + " " + osRel).trim(),
    OSVersion: osVer,
    Build: ""
  };

  // Motherboard detection (vendor + product)
  let motherboard = { manufacturer: null, product: null, label: null };
  try {
    const psBoard = await runPowerShell("Get-CimInstance Win32_BaseBoard | Select-Object -First 1 Manufacturer,Product | ConvertTo-Json -Compress"
    );
    const rawBoard = (psBoard && psBoard.stdout ? psBoard.stdout.toString() : "").trim();
    if (rawBoard) {
      try {
        const js = JSON.parse(rawBoard);
        const man = (js.Manufacturer || '').trim();
        const prod = (js.Product || '').trim();
        const label = (man + ' ' + prod).trim();
        motherboard = { manufacturer: man || null, product: prod || null, label: label || null };
      } catch (_e) {
        // ignore baseboard parse errors
      }
    }
  } catch (_e) {
    // ignore baseboard detection errors
  }

  // GPU + VRAM detection using PowerShell only (WMIC is deprecated on many systems)
  try {
    const ps = await runPowerShell(
      "Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1 Name,AdapterRAM | ConvertTo-Json -Compress"
    );

      const raw = (ps && ps.stdout ? ps.stdout.toString() : "").trim();
      let gpuName = "Unknown GPU";
      let vramGb = null;
      let stderr = (ps && ps.stderr ? ps.stderr.toString() : "").trim();

      if (raw) {
        try {
          const js = JSON.parse(raw);
          if (typeof js === "string") {
            gpuName = js.trim() || gpuName;
          } else if (js) {
            if (js.Name || js.name) {
              gpuName = String(js.Name || js.name || "").trim() || gpuName;
            }
            let bytes = 0;
            if (typeof js === "number") {
              bytes = js;
            } else if (js.AdapterRAM || js.adapterRam) {
              bytes = js.AdapterRAM || js.adapterRam || 0;
            }
            if (bytes && bytes > 0) {
              vramGb = Math.round(bytes / (1024 * 1024 * 1024));
            }
          }
        } catch (e) {
          stderr = [stderr, String(e || "")].filter(Boolean).join(" | ");
        }
      }

      let vendor = "unknown";
      const lower = String(gpuName || "").toLowerCase();
      if (lower.includes("nvidia") || lower.includes("geforce") || lower.includes("rtx") || lower.includes("gtx")) {
        vendor = "nvidia";
      } else if (lower.includes("amd") || lower.includes("radeon") || lower.includes("rx ")) {
        vendor = "amd";
      } else if (lower.includes("intel") || lower.includes("uhd") || lower.includes("iris")) {
        vendor = "intel";
      }

      const merged = {
        ...baseInfo,
        GPUN: gpuName || "Unknown GPU",
        GPUVRAM: vramGb,
        GPUVendor: vendor,
        MotherboardManufacturer: motherboard.manufacturer,
        MotherboardProduct: motherboard.product,
        MotherboardLabel: motherboard.label
      };

    return { ok: true, info: merged, stderr };
  } catch (e) {
    const merged = {
      ...baseInfo,
      GPUN: "Unknown GPU",
      GPUVRAM: null,
      GPUVendor: "unknown",
      MotherboardManufacturer: motherboard.manufacturer,
      MotherboardProduct: motherboard.product,
      MotherboardLabel: motherboard.label
    };
    return { ok: true, info: merged, stderr: String(e || "") };
  }
});

// --- IPC: BIOS / firmware info (best-effort; many settings require manual BIOS changes) ---
ipcMain.handle("falcon:getBiosInfo", async () => {
  try {
    // IMPORTANT: avoid spawn(sync) here (it blocks Electron main process and makes the UI "snap" back to Home).
    const psScript = `
      $ErrorActionPreference = 'SilentlyContinue'
      $info = [ordered]@{
        motherboard = [ordered]@{ manufacturer=$null; product=$null; label=$null }
        bios        = [ordered]@{ vendor=$null; version=$null; smbios=$null; releaseDate=$null }
        secureBoot  = [ordered]@{ supported=$null; enabled=$null }
        tpm         = [ordered]@{ present=$null; ready=$null; enabled=$null }
        virtualization = [ordered]@{ firmwareEnabled=$null; hyperV=$null }
        resizableBar = [ordered]@{ enabled=$null; note='Detection is vendor/driver-specific; Falcon shows best-effort status.' }
      }

      try {
        $bb = Get-CimInstance Win32_BaseBoard | Select-Object -First 1 Manufacturer,Product
        if($bb){
          $m = ($bb.Manufacturer | ForEach-Object { $_.ToString().Trim() })
          $p = ($bb.Product | ForEach-Object { $_.ToString().Trim() })
          $info.motherboard.manufacturer = $m
          $info.motherboard.product = $p
          $info.motherboard.label = (($m + ' ' + $p).Trim())
        }
      } catch {}

      try {
        $b = Get-CimInstance Win32_BIOS | Select-Object -First 1 Manufacturer,SMBIOSBIOSVersion,Version,ReleaseDate
        if($b){
          $info.bios.vendor = ($b.Manufacturer | ForEach-Object { $_.ToString().Trim() })
          $info.bios.smbios = ($b.SMBIOSBIOSVersion | ForEach-Object { $_.ToString().Trim() })
          $info.bios.version = ($b.Version | ForEach-Object { $_.ToString().Trim() })
          $rel = ($b.ReleaseDate | ForEach-Object { $_.ToString().Trim() })
          if($rel -match '^\d{14}\.'){ $rel = $rel.Substring(0,8) }
          $info.bios.releaseDate = $rel
        }
      } catch {}

      try {
        $sb = $null
        try { $sb = [bool](Confirm-SecureBootUEFI) } catch { $sb = $null }
        if($null -ne $sb){ $info.secureBoot.supported = $true; $info.secureBoot.enabled = $sb }
      } catch {}

      try {
        $t = $null
        try { $t = Get-Tpm } catch { $t = $null }
        if($t){
          $info.tpm.present = $t.TpmPresent
          $info.tpm.ready = $t.TpmReady
          $info.tpm.enabled = $t.TpmEnabled
        }
      } catch {}

      try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 VirtualizationFirmwareEnabled
        if($cpu){ $info.virtualization.firmwareEnabled = $cpu.VirtualizationFirmwareEnabled }
      } catch {}
      try {
        $hv = $null
        try { $hv = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State } catch { $hv = $null }
        if($hv){ $info.virtualization.hyperV = $hv.ToString().Trim() }
      } catch {}

      try {
        $paths = Get-ChildItem 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Video' -ErrorAction SilentlyContinue | ForEach-Object { $_.PSPath }
        $vals = @()
        foreach($p in $paths){
          try {
            $k = Join-Path $p '0000'
            $v = (Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).EnableResizableBar
            if($null -ne $v){ $vals += $v }
          } catch {}
        }
        if($vals.Count -gt 0){
          $v = $vals | Select-Object -First 1
          if($v -eq 1 -or ($v -is [string] -and $v -match 'true')){ $info.resizableBar.enabled = $true }
          if($v -eq 0 -or ($v -is [string] -and $v -match 'false')){ $info.resizableBar.enabled = $false }
        }
      } catch {}

      $info | ConvertTo-Json -Compress
    `;

    const info = await new Promise((resolve, reject) => {
      const p = spawn("powershell.exe", [
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command",
        psScript
      ]);
      let stdout = "";
      let stderr = "";
      p.stdout.on("data", d => stdout += d.toString());
      p.stderr.on("data", d => stderr += d.toString());
      p.on("close", (code) => {
        const out = (stdout || "").trim();
        if (code !== 0 || !out) {
          return reject(new Error((stderr || "").trim() || "Failed to query BIOS info."));
        }
        try { resolve(JSON.parse(out)); } catch (e) { reject(e); }
      });
    });

    return { ok: true, info };
  } catch (e) {
    return { ok: false, error: e && e.message ? e.message : String(e) };
  }
});

// --- IPC: save text file (used for BIOS checklist exports) ---
ipcMain.handle("falcon:saveTextFile", async (_evt, payload) => {
  try {
    const name = payload && payload.name ? String(payload.name) : "falcon_export.txt";
    const text = payload && payload.text ? String(payload.text) : "";
    const ts = new Date().toISOString().replace(/[:.]/g, "-");
    const safeName = name.replace(/[\\/:*?"<>|]+/g, "_");
    const outDir = path.join(__dirname, "logs");
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const outPath = path.join(outDir, ts + "_" + safeName);
    fs.writeFileSync(outPath, text, "utf-8");
    return { ok: true, path: outPath };
  } catch (e) {
    return { ok: false, error: e && e.message ? e.message : String(e) };
  }
});



// --- IPC: Thermals (best-effort) ---
ipcMain.handle("falcon:getThermals", async () => {
  const { execFile } = require("child_process");

  const ps = `
  $out = New-Object System.Collections.Generic.List[object]

  function Add-Sensor([string]$name, [double]$tempC){
    try { $out.Add([pscustomobject]@{ name=$name; tempC=[math]::Round($tempC,1) }) | Out-Null } catch {}
  }

  # ACPI thermal zones (often available on laptops; may be blank on desktops)
  try {
    $zones = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if($zones){
      $i=0
      foreach($z in $zones){
        $i++
        $c = ($z.CurrentTemperature / 10.0) - 273.15
        if($c -gt -50 -and $c -lt 150){ Add-Sensor ("ThermalZone"+$i) $c }
      }
    }
  } catch {}

  # CPU "estimate" from PerformanceCounter if present (rare)
  # We do not rely on vendor APIs here; fan control is handled via FanControl integration.
  $out | ConvertTo-Json -Depth 4
  `;
  return await new Promise((resolve) => {
    const args = ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps];
    execFile("powershell.exe", args, { windowsHide: true, maxBuffer: 1024 * 1024 }, (err, stdout, stderr) => {
      if (err) {
        resolve({ ok: false, sensors: [], error: String(stderr || err.message || err) });
        return;
      }
      try {
        const sensors = JSON.parse(stdout || "[]");
        resolve({ ok: true, sensors: Array.isArray(sensors) ? sensors : [] });
      } catch (e) {
        resolve({ ok: false, sensors: [], error: "Failed to parse sensor JSON." });
      }
    });
  });
});

// --- IPC: Timer Resolution Manager ---
ipcMain.handle("falcon:timerStatus", async () => {
  try {
    const projectRoot = app.isPackaged ? path.join(process.resourcesPath, "app.asar.unpacked") : __dirname;
    const script = path.join(projectRoot, "scripts", "timer-control.ps1");
    const res = await runPsScript(script, ["-Action", "status"]);
    const line = (res.rawStdout || "").trim().split(/\r?\n/).filter(Boolean).pop() || "STOPPED|";
    const parts = line.split("|");
    const status = (parts[0] || "STOPPED").toUpperCase();
    const pid = parts[1] ? Number(parts[1]) : null;
    return { ok: true, running: status === "RUNNING", pid };
  } catch (e) {
    return { ok: false, running: false, pid: null, error: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:timerStart", async (_evt, payload) => {
  try {
    const resolution = payload && payload.resolution ? String(payload.resolution) : "5000";
    const projectRoot = app.isPackaged ? path.join(process.resourcesPath, "app.asar.unpacked") : __dirname;
    const script = path.join(projectRoot, "scripts", "timer-control.ps1");
    const res = await runPsScript(script, ["-Action", "start", "-Resolution", resolution]);
    return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "" };
  } catch (e) {
    return { ok: false, stdout: "", stderr: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:timerStop", async () => {
  try {
    const projectRoot = app.isPackaged ? path.join(process.resourcesPath, "app.asar.unpacked") : __dirname;
    const script = path.join(projectRoot, "scripts", "timer-control.ps1");
    const res = await runPsScript(script, ["-Action", "stop"]);
    return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "" };
  } catch (e) {
    return { ok: false, stdout: "", stderr: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:timerInstallStartup", async (_evt, payload) => {
  try {
    const resolution = payload && payload.resolution ? String(payload.resolution) : "5000";
    const projectRoot = app.isPackaged ? path.join(process.resourcesPath, "app.asar.unpacked") : __dirname;
    const script = path.join(projectRoot, "scripts", "timer-control.ps1");
    const res = await runPsScript(script, ["-Action", "installTask", "-Resolution", resolution]);
    return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "" };
  } catch (e) {
    return { ok: false, stdout: "", stderr: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:timerRemoveStartup", async () => {
  try {
    const projectRoot = app.isPackaged ? path.join(process.resourcesPath, "app.asar.unpacked") : __dirname;
    const script = path.join(projectRoot, "scripts", "timer-control.ps1");
    const res = await runPsScript(script, ["-Action", "removeTask"]);
    return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "" };
  } catch (e) {
    return { ok: false, stdout: "", stderr: String(e && e.message ? e.message : e) };
  }
});


ipcMain.handle("falcon:detectXmpStatus", async () => {
  try {
    const res = await runPowerShell("Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1 Speed,ConfiguredClockSpeed | ConvertTo-Json -Compress"
    );
    const raw = (res && res.stdout ? res.stdout.toString() : "").trim();
    if (!raw) return { ok: true, status: "Unknown" };
    let speed = 0, base = 0;
    try {
      const js = JSON.parse(raw);
      if (js) {
        speed = parseInt(js.Speed || js.speed || "0", 10) || 0;
        base = parseInt(js.ConfiguredClockSpeed || js.configuredClockSpeed || "0", 10) || 0;
      }
    } catch (_) {}
    if (!speed || !base) return { ok: true, status: "Unknown" };
    const ratio = base ? (speed / base) : 0;
    let status = "Unknown";
    if (ratio >= 1.15) status = "Enabled";
    else if (ratio <= 1.02) status = "Disabled";
    else status = "Unknown";
    return { ok: true, status, speed, base };
  } catch (e) {
    return { ok: false, status: "Unknown", error: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:getRebarStatus", async () => {
  try {
    const script = `
      $result = @{ Status = 'Unknown' }
      $paths = Get-ChildItem 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Video' -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.PsPath '0000' }
      foreach($p in $paths){
        try{
          $props = Get-ItemProperty -Path $p -ErrorAction SilentlyContinue
          if($props -and ($props.EnableReBar -ne $null)){
            if($props.EnableReBar -eq 1){ $result.Status='Enabled'; break }
            elseif($props.EnableReBar -eq 0){ $result.Status='Disabled' }
          }
        }catch{}
      }
      $result | ConvertTo-Json -Compress
    `;
    const res = await runPowerShell(script
    );
    const raw = (res && res.stdout ? res.stdout.toString() : "").trim();
    if (!raw) return { ok: true, status: "Unknown" };
    let status = "Unknown";
    try {
      const js = JSON.parse(raw);
      if (js && (js.Status || js.status)) status = js.Status || js.status;
    } catch (_) {}
    if (status !== "Enabled" && status !== "Disabled") status = "Unknown";
    return { ok: true, status };
  } catch (e) {
    return { ok: false, status: "Unknown", error: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:openExternal", async (_evt, payload) => {
  const url = payload && payload.url ? String(payload.url) : "";
  if (!url) return { ok: false };
  await shell.openExternal(url);
  return { ok: true };
});

ipcMain.handle("falcon:openPath", async (_evt, payload) => {
  const pRaw = payload && payload.path ? String(payload.path) : "";
  if (!pRaw) return { ok: false, error: "Missing path" };

  // Resolve relative paths against the app root so buttons like "tools/..." work.
  let target = pRaw;
  try {
    const base = app.isPackaged ? path.dirname(process.execPath) : app.getAppPath();
    if (!path.isAbsolute(target)) target = path.join(base, target);
    const res = await shell.openPath(target);
    // shell.openPath returns an empty string on success, otherwise an error message
    if (res) return { ok: false, error: res, path: target };
    return { ok: true, path: target };
  } catch (e) {
    return { ok: false, error: String(e && e.message ? e.message : e), path: target };
  }
});

// --- IPC: Latency overrides (ProgramData\FalconOptimizer\latency_overrides.json) ---
ipcMain.handle("falcon:getLatencyOverrides", async () => {
  try {
    const dir = path.join(process.env.ProgramData || "C:\\ProgramData", "FalconOptimizer");
    const fn = path.join(dir, "latency_overrides.json");
    if (!fs.existsSync(fn)) return { ok: true, overrides: null };
    const raw = fs.readFileSync(fn, "utf-8");
    return { ok: true, overrides: JSON.parse(raw) };
  } catch (e) {
    return { ok: false, overrides: null, error: String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:setLatencyOverrides", async (_evt, payload) => {
  try {
    const dir = path.join(process.env.ProgramData || "C:\\ProgramData", "FalconOptimizer");
    fs.mkdirSync(dir, { recursive: true });
    const fn = path.join(dir, "latency_overrides.json");

    let cur = {};
    if (fs.existsSync(fn)) {
      try { cur = JSON.parse(fs.readFileSync(fn, "utf-8")); } catch(_e) { cur = {}; }
    }

    const next = Object.assign({}, cur);
    if (!next.scheduler) next.scheduler = {};
    if (!next.timer) next.timer = {};
    if (!next.bcdedit) next.bcdedit = {};

    // timer
    if (payload && payload.timer && (payload.timer.resolution_us !== undefined && payload.timer.resolution_us !== null)) {
      const v = Number(payload.timer.resolution_us);
      if (!Number.isFinite(v) || v <= 0) throw new Error("Invalid timer.resolution_us");
      next.timer.resolution_us = Math.round(v);
    }

    // scheduler
    if (payload && payload.scheduler && payload.scheduler.Win32PrioritySeparation) {
      next.scheduler.Win32PrioritySeparation = String(payload.scheduler.Win32PrioritySeparation);
    }

    // bcdedit flags (string "yes"/"no")
    if (payload && payload.bcdedit) {
      for (const k of ["disabledynamictick","useplatformtick","useplatformclock"]) {
        if (payload.bcdedit[k] !== undefined && payload.bcdedit[k] !== null) {
          next.bcdedit[k] = String(payload.bcdedit[k]);
        }
      }
    }

    fs.writeFileSync(fn, JSON.stringify(next, null, 2), "utf-8");
    return { ok: true, path: fn, overrides: next };
  } catch (e) {
    return { ok: false, error: String(e && e.message ? e.message : e) };
  }
});


// --- IPC: Scan installed games (best-effort) ---
ipcMain.handle("falcon:scanInstalledGames", async () => {
  try {
    const pf = process.env.ProgramFiles || "";
    const pfx86 = process.env["ProgramFiles(x86)"] || "";
    const lad = process.env.LOCALAPPDATA || "";

    function uniq(arr){ return Array.from(new Set((arr||[]).filter(Boolean))); }

    function getSteamCommonDirs(){
      const dirs = [];
      for (const base of [pfx86, pf]) {
        if (!base) continue;
        const cand = path.join(base, "Steam", "steamapps", "common");
        try { if (fs.existsSync(cand)) dirs.push(cand); } catch(_) {}
      }
      return uniq(dirs);
    }

    const steamCommons = getSteamCommonDirs();

    const games = [
      { id:"fortnite", name:"Fortnite", paths:[
        path.join(pf, "Epic Games","Fortnite","FortniteGame","Binaries","Win64","FortniteClient-Win64-Shipping.exe"),
        path.join(pfx86, "Epic Games","Fortnite","FortniteGame","Binaries","Win64","FortniteClient-Win64-Shipping.exe"),
      ]},
      { id:"valorant", name:"VALORANT", paths:[
        path.join(pf, "Riot Games","VALORANT","live","ShooterGame","Binaries","Win64","VALORANT-Win64-Shipping.exe"),
        path.join(pfx86, "Riot Games","VALORANT","live","ShooterGame","Binaries","Win64","VALORANT-Win64-Shipping.exe"),
      ]},
      { id:"cs2", name:"Counter-Strike 2", paths: steamCommons.flatMap(sc => ([
        path.join(sc, "Counter-Strike Global Offensive","game","bin","win64","cs2.exe"),
        path.join(sc, "Counter-Strike 2","game","bin","win64","cs2.exe"),
      ]))},
      { id:"apex", name:"Apex Legends", paths:[
        ...steamCommons.map(sc => path.join(sc, "Apex Legends","r5apex.exe")),
        path.join(pf, "EA Games","Apex Legends","r5apex.exe"),
        path.join(pfx86, "EA Games","Apex Legends","r5apex.exe"),
        path.join(pf, "Origin Games","Apex","r5apex.exe"),
        path.join(pfx86, "Origin Games","Apex","r5apex.exe"),
      ]},
      { id:"overwatch2", name:"Overwatch 2", paths:[
        path.join(pf, "Overwatch","_retail_","Overwatch.exe"),
        path.join(pfx86, "Overwatch","_retail_","Overwatch.exe"),
      ]},
      { id:"rocketleague", name:"Rocket League", paths:[
        ...steamCommons.map(sc => path.join(sc, "rocketleague","Binaries","Win64","RocketLeague.exe")),
        ...steamCommons.map(sc => path.join(sc, "Rocket League","Binaries","Win64","RocketLeague.exe")),
        path.join(pf, "Epic Games","rocketleague","Binaries","Win64","RocketLeague.exe"),
      ]},
      { id:"gta5", name:"GTA V", paths:[
        ...steamCommons.map(sc => path.join(sc, "Grand Theft Auto V","GTA5.exe")),
        path.join(pf, "Rockstar Games","Grand Theft Auto V","GTA5.exe"),
      ]},
      { id:"league", name:"League of Legends", paths:[
        path.join(pf, "Riot Games","League of Legends","LeagueClient.exe"),
        path.join(pfx86, "Riot Games","League of Legends","LeagueClient.exe"),
      ]},
      { id:"geforcenow", name:"GeForce NOW", paths:[
        path.join(lad, "NVIDIA Corporation","GeForceNOW","CEF","GeForceNOW.exe"),
        path.join(pf, "NVIDIA Corporation","GeForceNOW","CEF","GeForceNOW.exe"),
      ]},
      { id:"cod", name:"Call of Duty", paths:[
        ...steamCommons.map(sc => path.join(sc, "Call of Duty HQ","cod.exe")),
        ...steamCommons.map(sc => path.join(sc, "Call of Duty","cod.exe")),
      ]},
    ];

    const found = [];
    for (const g of games) {
      const exe = (g.paths || []).find(p => {
        try { return p && fs.existsSync(p); } catch(_) { return false; }
      });
      if (exe) found.push({ id: g.id, name: g.name, exePath: exe });
    }

    return found;
  } catch (e) {
    return [];
  }
});

// --- IPC: Run per-game pack actions (uses scripts/games/falcon-gamepack.ps1) ---
ipcMain.handle("falcon:runGamePack", async (_evt, payload) => {
  try {
    const gameId = payload && payload.gameId ? String(payload.gameId) : "";
    const action = payload && payload.action ? String(payload.action) : "";
    if (!gameId || !action) return { ok:false, stdout:"", stderr:"Missing gameId/action" };
    // route to PS helper
    return await runPsFile(path.join("scripts","games","falcon-gamepack.ps1"), ["-Game", gameId, "-Action", action]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

// --- IPC: Power plans ---
ipcMain.handle("falcon:applyPowerPlan", async (_evt, payload) => {
  try {
    const mode = payload && payload.mode ? String(payload.mode).toLowerCase() : "";
    if (!mode) return { ok:false, stdout:"", stderr:"Missing mode" };

    const psRel = path.join("scripts","powerplans","falcon-powerplans.ps1");

    // Ensure plans exist (idempotent)
    const installRes = await runPsFile(psRel, ["-Action", "install"]);
    if (!installRes.ok) return installRes;

    const action = (mode === "desktop") ? "apply_desktop"
                 : (mode === "laptop") ? "apply_laptop"
                 : null;
    if (!action) return { ok:false, stdout:"", stderr:"Unknown mode: " + mode };

    return await runPsFile(psRel, ["-Action", action]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:removePowerPlans", async () => {
  try {
    // Restore the user's previously active power plan (if saved)
    return await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", "restore_previous"]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

// --- IPC: Power plans v2 ---
ipcMain.handle("falcon:powerPlansInstallAll", async () => {
  try {
    return await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", "install_all"]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:powerPlansApply", async (_evt, payload) => {
  try {
    const plan = payload && payload.plan ? String(payload.plan).toLowerCase() : "";
    if (!plan) return { ok:false, stdout:"", stderr:"Missing plan" };

    const map = {
      extreme: "apply_extreme",
      sustain: "apply_sustain",
      competitive: "apply_competitive",
      balanced: "apply_balanced",
      laptop: "apply_laptop"
    };
    const action = map[plan];
    if (!action) return { ok:false, stdout:"", stderr:"Unknown plan: " + plan };

    // ensure installed
    const installRes = await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", "install_all"]);
    if (!installRes.ok) return installRes;

    return await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", action]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:powerPlansApplyWindows", async (_evt, payload) => {
  try {
    const which = payload && payload.which ? String(payload.which).toLowerCase() : "";
    if (!which) return { ok:false, stdout:"", stderr:"Missing which" };

    const map = {
      balanced: "apply_windows_balanced",
      high: "apply_windows_high",
      ultimate: "apply_windows_ultimate"
    };
    const action = map[which];
    if (!action) return { ok:false, stdout:"", stderr:"Unknown which: " + which };

    return await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", action]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

ipcMain.handle("falcon:powerPlansRestorePrevious", async () => {
  try {
    return await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", "restore_previous"]);
  } catch (e) {
    return { ok:false, stdout:"", stderr:String(e && e.message ? e.message : e) };
  }
});

// --- IPC: Thermals / CPU status ---
ipcMain.handle("falcon:getSystemVitals", async () => {
  try {
    // CPU load & clocks
    let cpuInfo = { loadPercent: null, currentMHz: null, maxMHz: null, name: null };
    try {
      const { stdout } = await runCmd("wmic cpu get Name,LoadPercentage,CurrentClockSpeed,MaxClockSpeed /value");
      const lines = String(stdout||"").split(/\r?\n/).map(l=>l.trim()).filter(Boolean);
      for (const ln of lines) {
        const [k,v]=ln.split("=");
        if (!v) continue;
        if (k==="Name") cpuInfo.name=v;
        if (k==="LoadPercentage") cpuInfo.loadPercent=Number(v);
        if (k==="CurrentClockSpeed") cpuInfo.currentMHz=Number(v);
        if (k==="MaxClockSpeed") cpuInfo.maxMHz=Number(v);
      }
    } catch {}

    // CPU temperature (often unavailable on desktops)
    let cpuTempC = null;
    try {
      const ps = `Get-WmiObject -Namespace "root/wmi" -Class MSAcpi_ThermalZoneTemperature | Select-Object -First 1 CurrentTemperature | ConvertTo-Json`;
      const res = await runPs(ps);
      if (res && res.ok && res.stdout) {
        const obj = JSON.parse(res.stdout.trim());
        const ct = obj && obj.CurrentTemperature ? Number(obj.CurrentTemperature) : null;
        if (ct && !Number.isNaN(ct)) cpuTempC = Math.round((ct/10.0) - 273.15);
      }
    } catch {}

    // basic "C-state-ish" counters if available
    let residency = null;
    try {
      const ps = `try { (Get-Counter -Counter "\\Processor Information(_Total)\\% C1 Time","\\Processor Information(_Total)\\% C2 Time","\\Processor Information(_Total)\\% C3 Time" -ErrorAction Stop).CounterSamples | Select Path,CookedValue | ConvertTo-Json -Depth 4 } catch { "[]" }`;
      const res = await runPs(ps);
      if (res && res.ok) {
        const arr = JSON.parse((res.stdout||"[]").trim() || "[]");
        residency = {};
        for (const it of arr) {
          if (!it || !it.Path) continue;
          const pv = Number(it.CookedValue);
          if (it.Path.includes("% C1 Time")) residency.c1 = Math.round(pv*10)/10;
          if (it.Path.includes("% C2 Time")) residency.c2 = Math.round(pv*10)/10;
          if (it.Path.includes("% C3 Time")) residency.c3 = Math.round(pv*10)/10;
        }
      }
    } catch {}

    return { ok:true, cpu: cpuInfo, cpuTempC, residency };
  } catch (e) {
    return { ok:false, error:String(e && e.message ? e.message : e) };
  }
});

// --- IPC: Latency benchmark ---
ipcMain.handle("falcon:runLatencyBenchmark", async (_evt, payload) => {
  try {
    const seconds = payload && payload.seconds ? Number(payload.seconds) : 5;
    const s = (Number.isFinite(seconds) && seconds >= 2 && seconds <= 30) ? String(Math.floor(seconds)) : "5";
    const res = await runPsFile(path.join("scripts","benchmarks","latency-benchmark.ps1"), ["-Seconds", s]);
    if (!res.ok) return res;
    let jsonOut = null;
    try { jsonOut = JSON.parse((res.stdout||"").trim()); } catch {}
    return { ok:true, result: jsonOut, raw: res.stdout||"" };
  } catch (e) {
    return { ok:false, error:String(e && e.message ? e.message : e) };
  }
});

// --- Auto-switch power plan when gaming ---
const autoSwitchPath = path.join(app.getPath("userData"), "auto_switch_powerplan.json");
let autoSwitchTimer = null;
let autoSwitchState = { enabled:false, plan:"competitive", fallback:"balanced", exes:["FortniteClient-Win64-Shipping.exe","Valorant.exe","Overwatch.exe","r5apex.exe","cs2.exe","RocketLeague.exe"] };
try {
  if (fs.existsSync(autoSwitchPath)) autoSwitchState = { ...autoSwitchState, ...JSON.parse(fs.readFileSync(autoSwitchPath,"utf8")) };
} catch {}

function saveAutoSwitch(){
  try { fs.writeFileSync(autoSwitchPath, JSON.stringify(autoSwitchState,null,2),"utf8"); } catch {}
}

async function checkAutoSwitchTick(){
  if (!autoSwitchState.enabled) return;
  try {
    const { stdout } = await runCmd('tasklist /FO CSV /NH');
    const names = new Set();
    String(stdout||"").split(/\r?\n/).forEach(line=>{
      line=line.trim();
      if (!line) return;
      // CSV: "Image Name","PID",...
      const m = line.match(/^"([^"]+)"/);
      if (m) names.add(m[1].toLowerCase());
    });

    const anyGame = (autoSwitchState.exes||[]).some(ex => names.has(String(ex).toLowerCase()));
    if (anyGame && !autoSwitchState._applied) {
      autoSwitchState._applied = true;
      await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action","install_all"]);
      const map = { extreme:"apply_extreme", sustain:"apply_sustain", competitive:"apply_competitive", balanced:"apply_balanced", laptop:"apply_laptop" };
      const act = map[String(autoSwitchState.plan||"competitive").toLowerCase()] || "apply_competitive";
      await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", act]);
    }
    if (!anyGame && autoSwitchState._applied) {
      autoSwitchState._applied = false;
      // fallback to previous if available, else selected fallback
      const mapW = { balanced:"apply_windows_balanced", windows_balanced:"apply_windows_balanced", high:"apply_windows_high", ultimate:"apply_windows_ultimate" };
      const fb = String(autoSwitchState.fallback||"balanced").toLowerCase();
      if (fb === "previous") {
        await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action","restore_previous"]);
      } else if (mapW[fb]) {
        await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", mapW[fb]]);
      } else {
        const map = { extreme:"apply_extreme", sustain:"apply_sustain", competitive:"apply_competitive", balanced:"apply_balanced", laptop:"apply_laptop" };
        const act = map[fb] || "apply_balanced";
        await runPsFile(path.join("scripts","powerplans","falcon-powerplans.ps1"), ["-Action", act]);
      }
    }
  } catch {}
}

function ensureAutoSwitchTimer(){
  if (autoSwitchTimer) clearInterval(autoSwitchTimer);
  autoSwitchTimer = setInterval(()=>{ checkAutoSwitchTick(); }, 2500);
}
ensureAutoSwitchTimer();

ipcMain.handle("falcon:getAutoSwitchPowerPlan", async ()=> {
  return { ok:true, state: { enabled: !!autoSwitchState.enabled, plan:autoSwitchState.plan, fallback:autoSwitchState.fallback, exes:autoSwitchState.exes } };
});

ipcMain.handle("falcon:setAutoSwitchPowerPlan", async (_evt, payload)=> {
  try {
    autoSwitchState.enabled = !!(payload && payload.enabled);
    if (payload && payload.plan) autoSwitchState.plan = String(payload.plan);
    if (payload && payload.fallback) autoSwitchState.fallback = String(payload.fallback);
    if (payload && Array.isArray(payload.exes)) autoSwitchState.exes = payload.exes.map(String).filter(Boolean).slice(0,50);
    saveAutoSwitch();
    return { ok:true };
  } catch (e) {
    return { ok:false, error:String(e && e.message ? e.message : e) };
  }
});



// --- IPC: Validate tweaks (runs schema-validator.js) ---
ipcMain.handle("falcon:validateTweaks", async () => {
  const projectRoot = app.isPackaged
    ? path.join(process.resourcesPath, "app.asar.unpacked")
    : __dirname;

  try {
    const report = validateCatalogs(projectRoot);
    const outPath = path.join(app.getPath("userData"), "tweak-validation-report.json");
    try { fs.writeFileSync(outPath, JSON.stringify(report, null, 2), "utf8"); } catch (_) {}
    return { ok: report.problems.length === 0, report, reportFile: outPath };
  } catch (e) {
    return { ok: false, error: String(e && e.message ? e.message : e) };
  }
});


// --- IPC: Security Health Check (Home panel) ---
ipcMain.handle("falcon:securityHealthCheck", async () => {
  try {
    return securityHealth.healthCheck();
  } catch (e) {
    return { ok: false, error: String(e && e.message ? e.message : e) };
  }
});

// --- IPC: Self-test ---

ipcMain.handle("falcon:performanceLibraryApply", async (_evt, args) => {
  try {
    const scope = args && args.scope ? String(args.scope) : "all";
    const updateSafe = args && (args.updateSafe === false) ? false : true;
    const allowCritical = args && (args.allowCritical === true) ? true : false;
    const mode = args && args.mode ? String(args.mode).toLowerCase() : "falcon";

    const catalogPath = path.join(__dirname, "tweaks", "_performance_library", "imported_catalog.json");
    const raw = fs.readFileSync(catalogPath, "utf-8");
    const catalog = JSON.parse(raw);

    const actions = [];
    const allowed = new Set(["reg_add","reg_delete","service","powercfg","bcdedit","schtasks","netsh","cleanup"]);
    const pushFrom = (arr) => {
      for (const a of arr) {
        if (!a || !allowed.has(a.type)) continue;
        const cmd = String(a.raw || "").trim();
        if (!cmd) continue;
        actions.push(cmd);
      }
    };
    if (catalog && catalog.actions) {
      if (catalog.actions.optimizer_pack) pushFrom(catalog.actions.optimizer_pack);
      if (catalog.actions.service_pack) pushFrom(catalog.actions.service_pack);
    }

    
    // Update-safe filtering: skip high-risk removals/blocks that commonly break Windows Update, Store, drivers, or core UI.
    const CRITICAL_UPDATE_SVCS = new Set(["BITS","TrustedInstaller","DeviceInstall","DsmSvc","UsoSvc","wuauserv","InstallService","DoSvc","WaaSMedicSvc"]);

// Always-protected services: never allow disabling via imported packs.
const ALWAYS_PROTECTED_SVCS = new Set(["MSISERVER","TRUSTEDINSTALLER","EVENTLOG","RPCSS","DCOMLAUNCH","SECURITYHEALTHSERVICE"]);
const isProtectedServiceDisableCmd = (c) => {
  const lc = c.toLowerCase();
  if (!lc.startsWith("sc ")) return false;
  const m = lc.match(/sc\s+config\s+\"?([^\"]+)\"?\s+start=\s*(\w+)/);
  if (!m) return false;
  const svc = String(m[1] || "").replace(/\s+/g,"").toUpperCase();
  const start = String(m[2] || "").toLowerCase();
  if (!ALWAYS_PROTECTED_SVCS.has(svc)) return false;
  return (start === "disabled" || start === "disable");
};

    const isUpdateCriticalServiceCmd = (c) => {
      const lc = c.toLowerCase();
      if (!lc.startsWith("sc ")) return false;
      // sc config "<svc>" start= disabled|demand|auto
      const m = lc.match(/sc\s+config\s+\"?([^\"]+)\"?\s+start=\s*(\w+)/);
      if (!m) return false;
      const svc = String(m[1] || "").replace(/\s+/g,"").toUpperCase();
      const start = String(m[2] || "").toLowerCase();
      if (!CRITICAL_UPDATE_SVCS.has(svc)) return false;
      return (start === "disabled" || start === "disable");
    };

    const isAggressiveRemoval = (c) => {
      const lc = c.toLowerCase();
      // Edge / Store / Defender / core servicing removals
      if (lc.includes("program files (x86)\\microsoft\\edge")) return true;
      if (lc.includes("edgeupdate") || lc.includes("edgecore")) return true;
      if (lc.includes("windefend") || lc.includes("securityhealthservice") || lc.includes("defender")) return true;
      if (lc.includes("\\windowsupdate") || lc.includes("\\updateorchestrator") || lc.includes("waasmedic")) return true;
      if (lc.includes("image file execution options\\wuauclt")) return true;
      return false;
    };

    const isWallpaperRelated = (c) => {
      const lc = c.toLowerCase();
      return (lc.includes("control panel\\desktop") && (lc.includes("wallpaper") || lc.includes("wallpaperstyle") || lc.includes("transcodedimagecache")));
    };

    const filteredActions = [];
    for (const c of actions) {
      const lc = String(c || "");
      if (!lc) continue;
      if (isWallpaperRelated(lc)) continue;
      if (isProtectedServiceDisableCmd(lc)) continue;

      if (updateSafe) {
        if (isUpdateCriticalServiceCmd(lc) && !allowCritical) continue;
        if (isAggressiveRemoval(lc)) continue;
      }
      filteredActions.push(lc);
    }
// Mode-based scheduler override (ensures the chosen profile is applied even if the imported script is menu-driven)
    const schedMap = { falcon: 0x26, fps: 0x2A, latency: 0x24, balanced: 0x1A, extreme: 0x2A };
    const sched = (mode in schedMap) ? schedMap[mode] : 0x26;

    const steps = [];
    steps.push({
      type: "registry.set",
      path: "HKLM\\SYSTEM\\CurrentControlSet\\Control\\PriorityControl",
      name: "Win32PrioritySeparation",
      valueType: "DWORD",
      value: sched
    });

    // Update/driver-safe exclusions
    const criticalSvcs = (catalog && catalog.summaries && catalog.summaries.services && Array.isArray(catalog.summaries.services.updateCriticalDisabledBySource))
      ? catalog.summaries.services.updateCriticalDisabledBySource
      : ["BITS","TrustedInstaller","DeviceInstall","DsmSvc","UsoSvc","wuauserv","InstallService"];

    const isCriticalSvcCmd = (cmd) => {
      const c = cmd.toLowerCase();
      for (const svc of criticalSvcs) {
        const s = String(svc).toLowerCase();
        if (!s) continue;
        // Match common patterns: sc config <svc> start= disabled ; sc stop <svc> ; net stop <svc>
        if (c.includes("sc config") && c.includes(s) && c.includes("disabled")) return true;
        if (c.includes("sc stop") && c.includes(s)) return true;
        if (c.includes("net stop") && c.includes(s)) return true;
      }
      // Also exclude IFEO blocks that break update tools
      if (c.includes("image file execution options") && c.includes("wuauclt.exe")) return true;
      return false;
    };

    // Scope filtering (best-effort)
    const scopeMatch = (cmd) => {
      const c = cmd.toLowerCase();
      if (scope === "all") return true;
      if (scope === "restore_updates") return false;
      if (scope === "gpu") return c.includes("\\control\\video") || c.includes("nvidia") || c.includes("amd") || c.includes("display") || c.includes("mpo");
      if (scope === "scheduler") return c.includes("prioritycontrol") || c.includes("win32priorityseparation");
      if (scope === "services") return c.startsWith("sc ") || c.includes("sc config") || c.includes("sc stop") || c.includes("schtasks");
      if (scope === "power") return c.includes("powercfg") || c.includes("\\power");
      if (scope === "boot") return c.includes("bcdedit") || c.includes("useplatform") || c.includes("dynamictick") || c.includes("platformtick");
      if (scope === "network") return c.includes("netsh") || c.includes("\\tcpip") || c.includes("iphlpsvc");
      if (scope === "ui") return c.includes("\\explorer") || c.includes("\\desktop") || c.includes("\\dwm") || c.includes("visual");
      if (scope === "cleanup") return c.startsWith("del ") || c.startsWith("rd ") || c.includes("temp") || c.includes("prefetch");
      return true;
    };

    if (scope === "restore_updates") {
      const restoreSteps = [];
      // restore essential services for updates/drivers
      const toRestore = ["BITS","TrustedInstaller","DeviceInstall","DsmSvc","UsoSvc","wuauserv","InstallService"];
      for (const svc of toRestore) {
        restoreSteps.push({ type: "cmd.run", command: `sc config "${svc}" start= demand >nul 2>&1` });
        restoreSteps.push({ type: "cmd.run", command: `sc start "${svc}" >nul 2>&1` });
      }
      // remove IFEO blocks for wuauclt
      restoreSteps.push({ type: "cmd.run", command: 'reg delete "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options\\wuauclt.exe" /f >nul 2>&1' });
      const res = await runPsSteps({ steps: restoreSteps });
      return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "", logFile: res.logFile || null };
    }

    for (const cmd of filteredActions) {
      if (!scopeMatch(cmd)) continue;
      if (!allowCritical && isCriticalSvcCmd(cmd)) continue;
      steps.push({ type: "cmd.run", command: cmd });
    }

    if (steps.length < 2) {
      return { ok: false, stdout: "", stderr: "No actions matched the selected scope.", logFile: null };
    }

    const res = await runPsSteps({ steps });
    return { ok: !!res.ok, stdout: res.rawStdout || "", stderr: res.rawStderr || "", logFile: res.logFile || null };
  } catch (e) {
    return { ok: false, stdout: "", stderr: String(e && e.stack ? e.stack : e), logFile: null };
  }
});


ipcMain.handle("falcon:selfTest", async () => {
  const res = await runPsSteps({
    steps: [
      { type: "ps.run", command: 'Write-Output "=== Falcon Self-Test ==="' },
      { type: "ps.run", command: 'Write-Output ("PSVersion=" + $PSVersionTable.PSVersion.ToString())' },
      { type: "ps.run", command: 'Write-Output ("IsAdmin=" + ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))' },
      { type: "ps.run", command: 'Write-Output ("User=" + (whoami))' },
      { type: "ps.run", command: 'Write-Output ("CWD=" + (Get-Location).Path)' }
    ]
  });

  return {
    ok: res && res.ok === true,
    logFile: res ? res.logFile : null,
    output: [
      "---- STDOUT ----",
      (res && res.rawStdout ? res.rawStdout : "(empty)"),
      "---- STDERR ----",
      (res && res.rawStderr ? res.rawStderr : "(empty)")
    ]
  };
});



// Tool Manager (download/launch helpers)
ipcMain.handle('falcon:toolStatus', async (event, { toolId }) => {
  try {
    const ps = path.join(__dirname, 'scripts', 'tools', 'falcon-tool-manager.ps1');
    const res = await runPowerShellJson(ps, ['-Command','status','-ToolId', toolId]);
    return res;
  } catch (e) { return { ok:false, error:String(e) }; }
});
ipcMain.handle('falcon:toolEnsure', async (event, { toolId }) => {
  try {
    const ps = path.join(__dirname, 'scripts', 'tools', 'falcon-tool-manager.ps1');
    const res = await runPowerShellJson(ps, ['-Command','ensure','-ToolId', toolId]);
    return res;
  } catch (e) { return { ok:false, error:String(e) }; }
});
ipcMain.handle('falcon:toolLaunch', async (event, { toolId }) => {
  try {
    const ps = path.join(__dirname, 'scripts', 'tools', 'falcon-tool-manager.ps1');
    const res = await runPowerShellJson(ps, ['-Command','launch','-ToolId', toolId]);
    return res;
  } catch (e) { return { ok:false, error:String(e) }; }
});

app.whenReady().then(() => {
  stateFile = path.join(app.getPath("userData"), "toggle-state.json");
  historyFile = path.join(app.getPath("userData"), "applied-history.json");
  currentSessionId = "session_" + Date.now();
  loadState();
  loadHistory();
  ensureSession();

  // Phase 3: centralized job manager + action runner
  try {
    jobManager = new JobManager({ historyFilePath: historyFile });
    // Keep backward-compatible references
    jobManager.historyState = historyState;
    jobManager.currentSessionId = currentSessionId;
  } catch (_) { jobManager = null; }
  try {
    actionRunner = new ActionRunner({ runPsSteps });
  } catch (_) { actionRunner = null; }

  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});