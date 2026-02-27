function splitToolSteps(steps){
  const toolSteps = [];
  const runSteps = [];
  for(const st of (steps||[])){
    if(st && typeof st.type === 'string' && st.type.startsWith('tool.')) toolSteps.push(st);
    else runSteps.push(st);
  }
  return { toolSteps, runSteps };
}

async function executeToolSteps(steps){
  let last = { ok:true };
  for (const st of (steps||[])){
    if(!st || !st.type) continue;
    try{
      if(st.type === 'tool.ensure'){
        last = await window.falcon.toolEnsure({ toolId: st.toolId });
        if(typeof renderResult === 'function') renderResult(last);
        if(last && last.ok === false) return last;
      } else if(st.type === 'tool.launch'){
        last = await window.falcon.toolLaunch({ toolId: st.toolId });
        if(typeof renderResult === 'function') renderResult(last);
        if(last && last.ok === false) return last;
      } else if(st.type === 'tool.status'){
        last = await window.falcon.toolStatus({ toolId: st.toolId });
        if(typeof renderResult === 'function') renderResult(last);
      } else if(st.type === 'open.url' && st.url){
        await window.falcon.openExternal(st.url);
      } else if(st.type === 'open.path' && st.path){
        await window.falcon.openPath(st.path);
      }
    }catch(e){
      last = { ok:false, error: String(e && e.message ? e.message : e) };
      try{ if(typeof renderResult==='function') renderResult(last); }catch(_){}
      return last;
    }
  }
  return last;
}


let lastLog = '';
let lastLogFile = null;

let gameModePhotoOptimizations = [];


function getStepsFor(item, mode) {
  // mode: "apply" or "revert"
  if (!item) return [];
  // Some items store apply/revert as {steps:[...]} already.
  if (mode === "apply") {
    if (item.apply && item.apply.steps) return item.apply.steps;
    if (item.action && item.action.steps) return item.action.steps;
  } else {
    if (item.revert && item.revert.steps) return item.revert.steps;
  }
  // Legacy: apply/revert as arrays
  const v = item[mode];
  if (Array.isArray(v)) return v;
  return [];
}


// Build apply steps + optional verify steps (avoids recursive self-call bug).
function getApplyStepsWithVerify(item){
  const base = getStepsFor(item, 'apply') || [];
  const verify = (item && (item.__verifySteps || (item.verify && item.verify.steps) || item.verifySteps)) || [];
  return base.concat(Array.isArray(verify) ? verify : []);
}


// Phase 1: Run History + Global Search
const __runHistory = [];

function __ensureRunHistoryModal(){
  if(document.getElementById('runHistoryModal')) return;
  const wrap = document.createElement('div');
  wrap.id = 'runHistoryModal';
  wrap.className = 'modal';
  wrap.style.display = 'none';
  wrap.innerHTML = `
    <div class="modal-backdrop"></div>
    <div class="modal-card">
      <div class="modal-header">
        <div class="modal-title">Run Log</div>
        <button id="runHistoryModalClose" class="btn btn-ghost btn-sm" type="button">Close</button>
      </div>
      <pre id="runHistoryModalLog" class="log" style="max-height:70vh;overflow:auto;"></pre>
    </div>
  `;
  document.body.appendChild(wrap);
  const close = () => { wrap.style.display = 'none'; };
  wrap.querySelector('.modal-backdrop').onclick = close;
  wrap.querySelector('#runHistoryModalClose').onclick = close;
}
function __eh(v){
  try{ return (typeof escapeHtml==='function') ? escapeHtml(v) : String(v===null||v===undefined?'':v).replace(/[&<>"\']/g,(ch)=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch])); }catch(e){ return ''; }
}
function __pushRunHistory(entry){
  try{
    __runHistory.unshift(entry);
    while(__runHistory.length>50) __runHistory.pop();
    __renderRunHistory();
  }catch(e){}
}
function __fmtTime(ts){
  try{
    const d = new Date(ts);
    return d.toLocaleString();
  }catch(e){ return ''; }
}
async function __renderRunHistory(){
  const list = document.getElementById('runHistoryList');
  if(!list) return;
  list.innerHTML = '';

  // Prefer persisted history from main process (survives reloads)
  let items = [];
  try{
    const h = await window.falcon.getHistory();
    const sessions = Array.isArray(h && h.sessions) ? h.sessions : [];
    for(const s of sessions.slice().reverse()){
      const entries = Array.isArray(s.entries) ? s.entries : [];
      for(const e of entries){
        if(!e) continue;
        items.push({
          ts: e.ts || e.at || s.startedAt || Date.now(),
          label: e.label || e.name || e.id || 'Run',
          ok: (e.ok !== false),
          note: e.note || e.risk || '',
          stdout: e.stdout || '',
          stderr: e.stderr || '',
          logFile: e.logFile || null
        });
      }
    }
    items = items.slice(0, 50);
  }catch(_){
    items = Array.isArray(__runHistory) ? __runHistory.slice(0,50) : [];
  }

  for(const it of items){
    const div = document.createElement('div');
    div.className = 'rh-item';
    div.tabIndex = 0;
    div.innerHTML = `
      <div class="rh-top">
        <div class="rh-label">${__eh(it.label || 'Run')}</div>
        <div class="rh-status ${it.ok ? 'ok' : 'fail'}">${__eh(it.ok ? 'OK' : 'FAIL')}</div>
      </div>
      <div class="rh-meta">${__eh(__fmtTime(it.ts))}${it.note ? (' • ' + __eh(it.note)) : ''}</div>
    `;
    div.onclick = () => { __ensureRunHistoryModal();
      const out = ((it.stdout||'') + '\n' + (it.stderr||'')).trim();
      const modal = document.getElementById('runHistoryModal');
      const pre = document.getElementById('runHistoryModalLog');
      if(pre) pre.textContent = out || '(no output captured)';
      if(modal){ modal.style.display='block'; }
    };
    list.appendChild(div);
  }
}
function __setRunning(on){
  const ind = document.getElementById('globalRunIndicator');
  if(!ind) return;
  ind.style.display = on ? '' : 'none';
}

// Toast notification helper for optimization + theme status
let toastHost = null;

function escapeHtml(value){
  const s = value === null || value === undefined ? '' : String(value);
  return s.replace(/[&<>"']/g, (ch) => ({
    '&':'&amp;',
    '<':'&lt;',
    '>':'&gt;',
    '"':'&quot;',
    "'":'&#39;'
  }[ch]));
}

function showToast(message, kind) {
  try {
    if (!toastHost) {
      toastHost = document.getElementById('themeFxToastHost');
    }
    const host = toastHost;
    if (!host || !message) return;
    const el = document.createElement('div');
    el.className = 'fx-toast' + (kind ? (' fx-toast-' + kind) : '');
    el.textContent = String(message);
    host.appendChild(el);
    // Trigger enter animation
    requestAnimationFrame(() => {
      el.classList.add('show');
    });
    // Auto-dismiss
    const lifetime = kind === 'error' ? 7000 : 4500;
    setTimeout(() => {
      el.classList.remove('show');
      setTimeout(() => {
        if (el.parentNode === host) host.removeChild(el);
      }, 350);
    }, lifetime);
  } catch (e) {
    console && console.warn && console.warn('showToast failed', e);
  }
}


function toastRunResult(label, res){
  try{
    const ok = !!(res && res.ok);
    const err = (res && (res.error || res.message)) ? String(res.error || res.message) : '';
    if(ok){
      showToast((label ? (label + ': ') : '') + 'Success', 'success');
    } else {
      showToast((label ? (label + ': ') : '') + (err || 'Failed'), 'error');
    }
  }catch(_e){}
}

function humanizeUpdateStatus(payload){
  const status = payload && payload.status ? String(payload.status) : "";
  if (status === "checking") return { text: "Checking for updates…", kind: "info" };
  if (status === "available") return { text: "Update available. Downloading now…", kind: "info" };
  if (status === "not-available") return { text: "You are on the latest version.", kind: "success" };
  if (status === "download-progress") {
    const percent = payload && Number.isFinite(payload.percent) ? Math.round(payload.percent) : 0;
    return { text: `Downloading update… ${percent}%`, kind: "info" };
  }
  if (status === "downloaded") return { text: "Update downloaded. Restarting to install…", kind: "success" };
  if (status === "error") return { text: `Update check failed: ${payload && payload.message ? payload.message : "Unknown error"}`, kind: "error" };
  return null;
}

if (window.falconUpdates && typeof window.falconUpdates.onStatus === "function") {
  window.falconUpdates.onStatus((payload) => {
    const info = humanizeUpdateStatus(payload);
    if (!info) return;
    showToast(info.text, info.kind);
  });
}


function bindHorizontalWheelScroll(root=document){
  const nodes = root && root.querySelectorAll ? root.querySelectorAll('.hscroll-wheel') : [];
  nodes.forEach(el=>{
    if(el.dataset && el.dataset.hscrollBound) return;
    if(el.dataset) el.dataset.hscrollBound = '1';
    el.addEventListener('wheel', (e)=>{
      if(!e.shiftKey && Math.abs(e.deltaY) > Math.abs(e.deltaX)){
        el.scrollLeft += e.deltaY;
        e.preventDefault();
      }
    }, { passive:false });
  });
}




// Optional per-item latency tuning overrides based on hardware profile.
// This lets us choose more aggressive values on high-end GPUs/CPUs while
// staying conservative on low-end systems.

// High-detail theme FX particles (snow, galaxy stars, blocky overlays, etc.)
function updateThemeFxParticles(themeId) {
  try {
    const host = document.getElementById('themeFxOverlay');
    if (!host) return;

    // Clear previous particles but keep overlay itself
    host.innerHTML = "";

    const level = (typeof fxIntensity === "string" ? fxIntensity : "full");
    if (level === "off") {
      return;
    }

    const winterThemes = new Set([
      "christmasFrosted",
      "frostedWinterAurora",
      "arcticIce",
      "snowfallMinimal"
    ]);
    const galaxyThemes = new Set([
      "nebulaSpaceGamer",
      "deepGalaxy"
    ]);
    const desertThemes = new Set([
      "sunsetHorizon"
    ]);
    const mcOverworldThemes = new Set([
      "minecraftOverworld"
    ]);
    const mcNetherThemes = new Set([
      "minecraftNether"
    ]);
    const mcEndThemes = new Set([
      "minecraftEnd"
    ]);

    // Helper to create N elements with a class + random positions
    function spawnParticles(count, className, options) {
      const width = host.clientWidth || window.innerWidth || 1280;
      const height = host.clientHeight || window.innerHeight || 720;
      for (let i = 0; i < count; i++) {
        const el = document.createElement("div");
        el.className = className;
        const x = Math.random() * width;
        const y = Math.random() * height;
        el.style.left = x + "px";
        el.style.top = y + "px";
        el.style.setProperty('--drift', ((Math.random()*120)-60).toFixed(0) + 'px');
        el.style.setProperty('--twist', ((Math.random()*80)-40).toFixed(0) + 'deg');
        if (options && options.sizeJitter) {
          const base = options.sizeJitter.base || 6;
          const spread = options.sizeJitter.spread || 8;
          const size = base + Math.random() * spread;
          el.style.width = size + "px";
          el.style.height = size + "px";
        }
        if (options && options.delay) {
          el.style.animationDelay = (Math.random() * options.delay) + "s";
        }
        if (options && options.durationJitter) {
          const d0 = options.durationJitter.min || 8;
          const d1 = options.durationJitter.max || 14;
          const dur = d0 + Math.random() * Math.max(0.1,(d1-d0));
          el.style.animationDuration = dur + 's';
        }
        host.appendChild(el);
      }
    }

    if (winterThemes.has(themeId)) {
      // Christmas / winter snow blocks drifting down
      const n = level === "subtle" ? 22 : 36;
      spawnParticles(n, "fx-snow-dot", {
        sizeJitter: { base: 1.5, spread: 2.2 },
        delay: 14,
        durationJitter: { min: 12, max: 20 }
      });
    } else if (galaxyThemes.has(themeId)) {
      // Stars + slow drifting nebula specks
      const nStars = level === "subtle" ? 45 : 90;
      spawnParticles(nStars, "fx-star", {
        sizeJitter: { base: 1.5, spread: 2.2 },
        delay: 30
      });
      const nSpecks = level === "subtle" ? 15 : 30;
      spawnParticles(nSpecks, "fx-nebula-speck", {
        sizeJitter: { base: 10, spread: 24 },
        delay: 40
      });
    } else if (desertThemes.has(themeId)) {
      // Dusty particles sweeping sideways
      const nDust = level === "subtle" ? 35 : 70;
      spawnParticles(nDust, "fx-dust-grain", {
        sizeJitter: { base: 3, spread: 4 },
        delay: 20
      });
    } else if (mcOverworldThemes.has(themeId)) {
      // Overworld: grass/dirt style blocks drifting at mid-speed
      const nOver = level === "subtle" ? 35 : 70;
      spawnParticles(nOver, "fx-mc-block-overworld", {
        sizeJitter: { base: 10, spread: 16 },
        delay: 16
      });
    } else if (mcNetherThemes.has(themeId)) {
      // Nether: lava embers rising upward
      const nNether = level === "subtle" ? 45 : 90;
      spawnParticles(nNether, "fx-mc-ember-nether", {
        sizeJitter: { base: 4, spread: 6 },
        delay: 14
      });
    } else if (mcEndThemes.has(themeId)) {
      // End: void shards floating slowly
      const nEnd = level === "subtle" ? 30 : 60;
      spawnParticles(nEnd, "fx-mc-end-shard", {
        sizeJitter: { base: 8, spread: 14 },
        delay: 30
      });
    } else {
      // For other themes, keep it subtle or empty to avoid clutter.
    }
  } catch (e) {
    console && console.warn && console.warn('updateThemeFxParticles global error', e);
  }
}

function adjustStepsForHwProfile(item, mode, steps) {
  if (!item || !Array.isArray(steps) || !steps.length) return steps;

  const id = item.id || "";
  const profile = currentHwProfile || "auto";

  // No-op for auto: keep JSON defaults.
  if (profile === "auto") return steps;

  // Clone steps shallowly so we don't mutate shared JSON objects
  let newSteps = steps.map(s => Object.assign({}, s));

  // Example: SystemResponsiveness tuning
  if (id === "core.tweak_latency_tolerance") {
    const targetValue = (profile === "high") ? 0 : 10;
    newSteps = newSteps.map(s => {
      if (s.type === "registry.set" &&
          s.path === "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile" &&
          s.name === "SystemResponsiveness") {
        return Object.assign({}, s, { value: targetValue });
      }
      return s;
    });
  }

  // Additional future per-item overrides can be added here using id + profile checks.

  return newSteps;
}

// Wrapper to avoid per-tweak hangs: hard timeout so batch can continue
async function runTweakWithTimeout(payload, timeoutMs){
  const t = typeof timeoutMs === "number" && timeoutMs > 0 ? timeoutMs : 90000;
  try{
    

// Tool workflow steps (ensure/launch/status) must run in renderer (IPC), not via runTweak runner.
try{
  const sp = splitToolSteps(payload && payload.steps ? payload.steps : []);
  if(sp.toolSteps.length){
    const toolRes = await executeToolSteps(sp.toolSteps);
    if(toolRes && toolRes.ok === false){
      return { ok:false, error: toolRes.error || "Tool step failed" };
    }
  }
  if(payload) payload = Object.assign({}, payload, { steps: sp.runSteps });
}catch(e){
  // fail-open: keep running non-tool steps
}

const runPromise = window.falcon && typeof window.falcon.runTweak === "function"
      ? window.falcon.runTweak(payload)
      : Promise.resolve({ ok:false, error:"runTweak not available" });
    const timeoutPromise = new Promise(resolve => {
      setTimeout(() => resolve({ ok:false, timeout:true }), t);
    });
    const res = await Promise.race([runPromise, timeoutPromise]);
    if(res && res.timeout){
      try {
        const nm = payload && payload.id ? payload.id : "Optimization";
        showToast(nm + " timed out after " + Math.round(t/1000) + "s and was skipped.", "error");
      } catch(_e){}
    }
    return res;
  }catch(e){
    console && console.warn && console.warn("runTweakWithTimeout error", e);
    return { ok:false, error:String(e||"error") };
  }
}




// Simple in-memory cache for JSON loads to reduce repeated fetch + parse work
// during search/filtering and navigation. Cleared on full reload.
const __jsonCache = new Map();
async function loadJSON(path){
  if (__jsonCache.has(path)) return __jsonCache.get(path);
  const p = (async () => {
    const res = await fetch(path, { cache: 'no-store' });
    if(!res.ok) throw new Error(`Failed to load ${path}`);
    return await res.json();
  })();
  __jsonCache.set(path, p);
  return p;
}


function deriveTagsFromSource(src){
  const s = String(src||'').toLowerCase();
  const tags = [];
  const add = (...t) => t.forEach(x => { if(x && !tags.includes(x)) tags.push(x); });

  if (s.includes('hardware.gpu') || s.includes('gpu.')) add('gpu');
  if (s.includes('hardware.cpu') || s.includes('cpu.')) add('cpu');
  if (s.includes('hardware.memory') || s.includes('memory')) add('memory');
  if (s.includes('hardware.storage') || s.includes('storage')) add('storage');
  if (s.includes('hardware.peripherals') || s.includes('peripherals')) add('peripherals');

  if (s.includes('network')) add('network');
  if (s.includes('bufferbloat')) add('bufferbloat');
  if (s.includes('priority')) add('qos');

  if (s.includes('performance.lib.latency') || s.includes('scheduler') || s.includes('timer')) add('scheduler','latency');
  if (s.includes('windows.power')) add('power');
  if (s.includes('windows.privacy')) add('privacy');
  if (s.includes('windows.qol')) add('qol');
  if (s.includes('windows.core')) add('core');

  if (s.includes('fortnite')) add('game','fortnite');
  if (s.includes('game.mode') || s.includes('gamemode')) add('game','gamemode');

  if (s.includes('debloat') || s.includes('cleaner') || s.includes('uninstall')) add('cleanup');

  if (!tags.length) add('misc');
  return tags;
}

function buildVerifyStepsFromApply(applySteps){
  const verify = [];
  const add = (st) => { if (st && st.type) verify.push(st); };

  for (const st of (applySteps||[])){
    if (!st || !st.type) continue;

    if (st.type === 'registry.set'){
      add({
        type: 'registry.check',
        path: st.path,
        name: st.name,
        equals: st.value,
        valueType: st.valueType || st.value_type || st.vt
      });
    } else if (st.type === 'registry.remove'){
      add({
        type: 'registry.check',
        path: st.path,
        name: st.name,
        exists: false
      });
    } else if (st.type === 'service.disable'){
      add({ type:'service.check', name: st.name, startMode: 'Disabled' });
    } else if (st.type === 'service.enable'){
      add({ type:'service.check', name: st.name, startMode: 'Automatic', status: (st.start === true ? 'Running' : undefined) });
    } else if (st.type === 'service.startup'){
      // expects: startupType: Automatic/Manual/Disabled
      const sm = st.startupType || st.mode || st.value;
      if (sm) add({ type:'service.check', name: st.name, startMode: sm });
    } else if (st.type === 'powercfg.set'){
      add({ type:'powercfg.check', guid: st.guid });
    }
  }

  // strip undefined fields
  return verify.map(v => {
    const o = {};
    Object.keys(v).forEach(k => { if (v[k] !== undefined) o[k]=v[k]; });
    return o;
  });
}

function normalizeLibraryItem(item, src){
  const it = Object.assign({}, item||{});
  it.__source = src;

  // Tags
  if (!Array.isArray(it.tags) || !it.tags.length){
    it.tags = deriveTagsFromSource(src);
  }

  // Verification: explicit wins, otherwise auto-derive from apply steps
  let vSteps = [];
  if (it.verify && Array.isArray(it.verify.steps)) vSteps = it.verify.steps;
  else if (Array.isArray(it.verifySteps)) vSteps = it.verifySteps;
  else {
    const applySteps = getApplyStepsWithVerify(it);
    vSteps = buildVerifyStepsFromApply(applySteps);
  }
  it.__verifySteps = Array.isArray(vSteps) ? vSteps : [];

  // Enforce visibility rules: must have tags + verification (unless informational)
  it.__hiddenReason = null;
  const hasTags = Array.isArray(it.tags) && it.tags.length > 0;
  const isInfo = (it.type === 'header' || it.type === 'note' || it.type === 'divider');
  const hasVerify = it.__verifySteps.length > 0;

  if (!hasTags) it.__hiddenReason = 'missing-tags';
  else if (!isInfo && !hasVerify) it.__hiddenReason = 'missing-verify';

  return it;
}

function debounce(fn, waitMs){
  let t = null;
  return function(...args){
    if (t) clearTimeout(t);
    t = setTimeout(() => fn.apply(this, args), waitMs);
  };
}

function normalizeRiskLabel(input){
  const raw = (typeof input === "string") ? input : (input && (input.riskLevel || input.risk));
  const key = String(raw || "Safe").trim().toLowerCase();
  if (!key || key === "unknown") return "Safe";
  if (key === "safe" || key === "info" || key === "low") return "Safe";
  if (key === "warning" || key === "caution" || key === "medium") return "Warning";
  if (key === "high" || key === "danger" || key === "extreme") return "High";
  if (key === "critical") return "Critical";
  return "Safe";
}
function normRisk(item){
  return normalizeRiskLabel(item);
}
function riskRank(value){
  const rank = { Safe:0, Warning:1, High:2, Critical:3 };
  return rank[normalizeRiskLabel(value)] || 0;
}
function isHighOrCritical(risk){
  const r = normalizeRiskLabel(risk);
  return r === "High" || r === "Critical";
}
function getConfirmPhrase(risk){
  return risk === "Critical" ? "I UNDERSTAND" : "";
}

function showConfirmModal({ title, body, risk, requireTyped }){
  return new Promise((resolve) => {
    const backdrop = document.getElementById("confirmBackdrop");
    const t = document.getElementById("confirmTitle");
    const b = document.getElementById("confirmBody");
    const chk = document.getElementById("confirmCheck");
    const chkText = document.getElementById("confirmCheckText");
    const okBtn = document.getElementById("confirmOk");
    const cancelBtn = document.getElementById("confirmCancel");
    const typeWrap = document.getElementById("confirmTypeWrap");
    const typeInput = document.getElementById("confirmTypeInput");
    const typeHint = document.getElementById("confirmTypeHint");

    t.textContent = title || "Warning";
    b.textContent = body || "";
    chk.checked = false;
    chkText.textContent = (risk === "Critical") ? "I understand this can make the PC unbootable or unstable." : "I understand and want to continue.";
    typeInput.value = "";

    const phrase = (requireTyped ? getConfirmPhrase(risk) : "");
    typeWrap.style.display = phrase ? "block" : "none";
    if(phrase){
      typeHint.textContent = `Required phrase: ${phrase}`;
    } else {
      typeHint.textContent = "";
    }

    function cleanup(val){
      backdrop.style.display = "none";
      okBtn.onclick = null;
      cancelBtn.onclick = null;
      resolve(val);
    }

    okBtn.onclick = () => {
      const okChecked = chk.checked;
      if(!okChecked) return alert("Check the confirmation box to continue.");
      if(phrase){
        if(String(typeInput.value||"").trim().toUpperCase() !== phrase){
          return alert(`Type exactly: ${phrase}`);
        }
      }
      cleanup(true);
    };
    cancelBtn.onclick = () => cleanup(false);

    backdrop.style.display = "flex";
  });
}


let aggressiveConsentAccepted = false;

async function ensureAggressiveConsent(reason) {
  if (aggressiveConsentAccepted) return true;
  const bodyLines = [
    "Aggressive tweaks and BIOS guidance can improve latency and responsiveness, but they may also:",
    "• Increase power draw, fan noise, or heat.",
    "• Reduce stability or cause crashes on some systems.",
    "• Require you to reset BIOS or restore a backup if something goes wrong.",
    "",
    "These options are intended for advanced users and competitive players who understand the risk.",
    "",
    "By continuing, you confirm you will create backups/restore points and only change settings you know how to revert."
  ];
  const ok = await showConfirmModal({
    title: "Aggressive Tweaks & BIOS Helper",
    body: bodyLines.join("\n"),
    risk: "High",
    requireTyped: true
  });
  if (ok) aggressiveConsentAccepted = true;
  return ok;
}




function itemRequiresAggressiveConsent(item) {
  if (!item) return false;
  const risk = normRisk(item);
  const riskKey = String(risk || "Safe").toLowerCase();
  const desc = String(item.description || "").toLowerCase();
  const cat = String(item.category || "").toLowerCase();
  const tags = Array.isArray(item.tags) ? item.tags.join(" ").toLowerCase() : String(item.tags || "").toLowerCase();
  if (riskKey === "high" || riskKey === "critical") return true;
  if (tags.includes("aggressive") || tags.includes("expert")) return true;
  if (desc.includes("[aggressive]") || desc.includes("[expert]")) return true;
  if (cat.includes("aggressive") || cat.includes("expert")) return true;
  return !!item.aggressive;
}

async function chooseMachineProfileForRun(previousProfile) {
  const current = (previousProfile === "laptop" ? "laptop" : "desktop");
  return new Promise((resolve) => {
    try {
      const backdrop = document.createElement("div");
      backdrop.className = "modal-backdrop";
      backdrop.id = "machineProfileBackdrop";

      const modal = document.createElement("div");
      modal.className = "modal";
      modal.innerHTML = `
        <div class="modal-title">Select machine type</div>
        <div class="modal-body">
Desktop – Maximum FPS, lowest input delay, and best ping. Recommended for plugged-in gaming PCs.

Laptop – Balanced performance while respecting mobile thermals and power. Recommended for notebooks and gaming laptops.
        </div>
        <div class="modal-actions">
          <button class="btn primary" data-choice="desktop">Desktop – max FPS</button>
          <button class="btn" data-choice="laptop">Laptop – balanced</button>
          <button class="btn" data-choice="cancel">Cancel</button>
        </div>
      `;

      backdrop.appendChild(modal);
      document.body.appendChild(backdrop);

      function cleanup(chosen) {
        try { document.body.removeChild(backdrop); } catch (_) {}
        if (chosen === "desktop" || chosen === "laptop") {
          resolve(chosen);
        } else {
          resolve(current);
        }
      }

      backdrop.addEventListener("click", (ev) => {
        if (ev.target === backdrop) {
          cleanup("cancel");
        }
      });

      const buttons = modal.querySelectorAll("button[data-choice]");
      buttons.forEach((btn) => {
        btn.addEventListener("click", () => {
          const choice = btn.getAttribute("data-choice");
          cleanup(choice);
        });
      });
    } catch (e) {
      console && console.warn && console.warn("chooseMachineProfileForRun failed, falling back to previous", e);
      resolve(current);
    }
  });
}


const PERFORMANCE_ALLOWLIST_KEYWORDS = [
  "latency", "dpc", "timer", "scheduler", "interrupt", "msi", "gpu", "nvidia", "amd", "cpu",
  "power plan", "bcdedit", "network", "tcp", "ping", "input", "usb", "mouse", "keyboard", "controller",
  "audio latency", "debloat", "game mode", "fullscreen optimizations", "fullscreen optimization"
];

const LAPTOP_SAFETY_EXCLUSION_KEYWORDS = [
  "dptf", "dynamic tuning", "intel thermal", "ipf", "pmf", "acpi", "battery", "embedded controller", "fan",
  "thermal", "armoury", "asus", "vantage", "lenovo", "msi center", "dragon center", "omen", "alienware",
  "nitrosense", "hotkey"
];

const LAPTOP_BALANCED_SLEEP_EXCLUSIONS = [
  "sleep", "hibernate", "hibernation", "modern standby", "s0ix", "connected standby", "away mode"
];

function buildItemSearchText(it){
  const tags = Array.isArray(it && it.tags) ? it.tags.join(" ") : String((it && it.tags) || "");
  return [it && it.id, it && it.name, it && it.category, it && it.description, tags].map(v => String(v || "")).join(" ").toLowerCase();
}

function hasFocusTag(item){
  const desc = String((item && item.description) || "").toLowerCase();
  return desc.includes("[focus:");
}

function matchesAnyKeyword(text, keywords){
  return keywords.some((kw) => text.includes(String(kw || "").toLowerCase()));
}

function matchesPerformanceAllowlist(item){
  return matchesAnyKeyword(buildItemSearchText(item), PERFORMANCE_ALLOWLIST_KEYWORDS);
}

function isTaggedSafePerformance(item){
  const desc = String((item && item.description) || "").toLowerCase();
  const tags = Array.isArray(item && item.tags) ? item.tags.join(" ").toLowerCase() : String((item && item.tags) || "").toLowerCase();
  return desc.includes("[safe_performance]") || desc.includes("[safe-performance]") || tags.includes("safe_performance") || tags.includes("safe-performance");
}

function shouldExcludeForLaptopSafety(item, machineProfile, profileId){
  if (machineProfile !== "laptop") return false;
  const text = buildItemSearchText(item);
  if (matchesAnyKeyword(text, LAPTOP_SAFETY_EXCLUSION_KEYWORDS)) return true;
  if (String(profileId || "") === "laptop_balanced") {
    const sleepRisk = matchesAnyKeyword(text, LAPTOP_BALANCED_SLEEP_EXCLUSIONS);
    if (sleepRisk && !isTaggedSafePerformance(item)) return true;
  }
  return false;
}

function detectMachineProfileFromSystemInfo(info){
  if (!info || typeof info !== "object") return "desktop";

  const boolBatteryKeys = ["HasBattery", "hasBattery", "BatteryPresent", "batteryPresent", "IsLaptop", "isLaptop", "IsMobile", "isMobile"];
  for (const k of boolBatteryKeys) {
    if (info[k] === true || info[k] === 1 || String(info[k] || "").toLowerCase() === "true") return "laptop";
  }

  const numericSystemType = Number(info.PCSystemType || info.pcSystemType || info.SystemTypeCode || 0);
  if ([2, 8, 9, 10, 14].includes(numericSystemType)) return "laptop";

  const text = [
    info.ChassisType, info.chassisType, info.ChassisTypes, info.SystemEnclosureChassisTypes,
    info.Model, info.SystemModel, info.ProductName, info.DeviceType
  ].map(v => String(v || "")).join(" ").toLowerCase();

  if (/laptop|notebook|portable|mobile|ultrabook|netbook|tablet/.test(text)) return "laptop";
  return "desktop";
}

async function getStoredOrDetectedMachineProfile(){
  let stored = "";
  try { stored = String(localStorage.getItem("falcon.machineProfile") || "").toLowerCase(); } catch(_e) {}
  if (stored === "desktop" || stored === "laptop") return stored;

  let detected = detectMachineProfileFromSystemInfo(lastSystemInfo || null);
  if (!lastSystemInfo && window.falcon && window.falcon.getSystemInfo) {
    try {
      const sys = await window.falcon.getSystemInfo();
      if (sys && sys.info) {
        lastSystemInfo = sys.info;
        detected = detectMachineProfileFromSystemInfo(sys.info);
      }
    } catch(_e) {}
  }

  try { localStorage.setItem("falcon.machineProfile", detected); } catch(_e) {}
  if (window.falcon) window.falcon.machineProfile = detected;
  return detected;
}


let simulationMode = (localStorage.getItem("falcon_simulation") === "1");
function setSimulationMode(on){
  simulationMode = !!on;
  localStorage.setItem("falcon_simulation", simulationMode ? "1" : "0");
}

const routes = {
  home: { title: 'Home', sub: 'Ready to enhance your system performance?', tabs: [] },
  backups: { title: 'Backups', sub: 'Create and restore snapshots safely.', tabs: [] },
  fixes: { title: 'Fixes', sub: 'Detect and repair common system issues.', tabs: [] },
  explore: { title: 'Explore', sub: 'Search, filter, and run any optimization.', tabs: [] },
  general: { title: 'General', sub: 'Enhance your system performance.', tabs: [
    { id:'core', label:'Core', source:'tweaks/windows.core.json' },
    { id:'privacy', label:'Privacy', source:'tweaks/windows.privacy.json' },
    { id:'qol', label:'QOL', source:'tweaks/windows.qol.json' },
    { id:'power', label:'Powerplan', source:'tweaks/windows.power.json' },
    { id:'latencyLib', label:'Scheduler + Timer', source:'tweaks/performance.lib.latency.scheduler_timer.json' }
  ]},
  hardware: { title: 'Hardware', sub: 'Optimize your hardware performance.', tabs: [
    { id:'gpu', label:'GPU', source:'tweaks/hardware.gpu.nvidia.json' },
    { id:'cpu', label:'CPU', source:'tweaks/hardware.cpu.intel.json' },
    { id:'memory', label:'Memory', source:'tweaks/hardware.memory.json' },
    { id:'peripherals', label:'Peripherals', source:'tweaks/hardware.peripherals.json' },
    { id:'inputlab', label:'Input Latency Lab', source:'tweaks/input.latency.json' },
    { id:'storage', label:'Storage', source:'tweaks/hardware.storage.json' }
      ,
    { id:'gpuLib', label:'GPU Library', source:'tweaks/performance.lib.hardware.gpu.json' },
    { id:'cpuLib', label:'CPU Library', source:'tweaks/performance.lib.hardware.cpu.json' },
    { id:'memoryLib', label:'Memory Library', source:'tweaks/performance.lib.hardware.memory.json' },
    { id:'storageLib', label:'Storage Library', source:'tweaks/performance.lib.hardware.storage.json' },
    { id:'periphLib', label:'Peripherals Library', source:'tweaks/performance.lib.hardware.peripherals.json' }

  ]},
  network: { title: 'Network', sub: 'Optimize network settings and performance.', tabs: [
    { id:'tweaks', label:'Tweaks', source:'tweaks/network.tweaks.json' },
    { id:'adapter', label:'Adapter Tuner', source:'tweaks/network.adapter-tuner.json' },
    { id:'bufferbloat', label:'Bufferbloat', source:'tweaks/network.bufferbloat.json' },
    { id:'priority', label:'Network Priority', source:'tweaks/network.priority.json' },
    { id:'lab', label:'Latency Lab', source:'tweaks/network.lab.json' },
    { id:'lib', label:'Library', source:'tweaks/performance.lib.network.json' }
  ]},
  speedCore: { title: 'Falcon Speed & Integrity Core', sub: 'Quick cleanup and deep integrity repair.', tabs: [
    { id:'boost', label:'Speed Boost Cleanup', source:'tweaks/speed.boost.json' },
    { id:'integrity', label:'Integrity & Repair', source:'tweaks/speed.integrity.json' },
    { id:'boostLib', label:'Cleanup Library', source:'tweaks/performance.lib.speed.cleanup.json' },
    { id:'integrityLib', label:'Integrity Library', source:'tweaks/performance.lib.speed.integrity.json' }
  ]},
    performanceLibrary: { title: 'Performance Library', sub: 'Integrated performance and latency library (organized by category).', tabs: [
    { id:'latency', label:'Scheduler + Timer', source:'tweaks/performance.lib.latency.scheduler_timer.json' },
    { id:'gpu', label:'GPU', source:'tweaks/performance.lib.hardware.gpu.json' },
    { id:'cpu', label:'CPU', source:'tweaks/performance.lib.hardware.cpu.json' },
    { id:'memory', label:'Memory', source:'tweaks/performance.lib.hardware.memory.json' },
    { id:'storage', label:'Storage', source:'tweaks/performance.lib.hardware.storage.json' },
    { id:'peripherals', label:'Peripherals', source:'tweaks/performance.lib.hardware.peripherals.json' },
    { id:'network', label:'Network', source:'tweaks/performance.lib.network.json' },
    { id:'cleanup', label:'Cleanup', source:'tweaks/performance.lib.speed.cleanup.json' },
    { id:'integrity', label:'Integrity', source:'tweaks/performance.lib.speed.integrity.json' },
    { id:'process', label:'Process + Services', source:'tweaks/performance.lib.process.json' },
    { id:'misc', label:'Misc', source:'tweaks/performance.lib.misc.json' }
  ] },

processLab: { title: 'Process Lab', sub: 'Audit and close non-essential background processes.', tabs: [
    { id:'presets', label:'Presets & Service Groups', source:'tweaks/process.lab.json' },
    { id:'lib', label:'Library', source:'tweaks/performance.lib.process.json' }
  ] },
  audio: { title: 'Audio Lab', sub: 'Simplify the audio engine and reduce audio-related stutter.', tabs: [
    { id:'latency', label:'Latency & Enhancements', source:'tweaks/audio.latency.json' }
  ]},
  controller: { title: 'Controller', sub: 'Controller polling rate, USB power, and gamepad-specific tweaks.', tabs: [
    { id:'overclock', label:'Overclock & USB', source:'tweaks/controller.lab.json' }
  ]},
  thermal: { title: 'Thermal Engine', sub: 'Control cooling policy and OS-side throttling behavior.', tabs: [
    { id:'engine', label:'Engine & Policies', source:'tweaks/thermal.engine.json' },
    { id:'cooling', label:'Cooling & Fan Control', source:'tweaks/thermal.cooling.json' }
  ]},
  driverLab: { title: 'Driver Lab', sub: 'Scan GPU driver health and clean shader caches.', tabs: [
    { id:'gpuhealth', label:'GPU Driver Health', source:'tweaks/gpu.driverhealth.json' },
    { id:'latencypresets', label:'Latency Presets', source:'tweaks/gpu.latency.presets.json' }
  ]},
  serviceLab: { title: 'Service Impact Lab', sub: 'Baseline/after snapshots to measure impact of service changes.', tabs: [
     { id:'impact', label:'Impact Analyzer', source:'tweaks/service.impact.json' },
     { id:'disabler', label:'Service Disabler', source:'tweaks/service.disabler.json' }
   ]},
  safeguardLab: { title: 'Safeguard / Failsafe', sub: 'Snapshot and restore core services + low-level settings.', tabs: [
    { id:'safeguard', label:'Safeguard Snapshots', source:'tweaks/safeguard.lab.json' }
  ]},
  registryLab: { title: 'Registry Lab', sub: 'Explorer history cleanup and MRU analyzer.', tabs: [
    { id:'registry', label:'Registry Deep Cleaner', source:'tweaks/registry.lab.json' }
  ]},
  memoryLab: { title: 'Memory Lab', sub: 'RAM stability scan and low-latency memory tweaks.', tabs: [
    { id:'ramlab', label:'RAM Stability & Tweaks', source:'tweaks/memory.lab.json' }
  ]},
  dpcLab: { title: 'DPC Latency Lab', sub: 'Approximate DPC/ISR latency snapshot for troubleshooting stutters.', tabs: [
    { id:'snapshot', label:'Latency Snapshot', source:'tweaks/dpc.latency.json' }
  ]},
  gameMode: { title: 'Game Mode', sub: 'Real-time gaming optimizations.', tabs: [
    { id:'runtime', label:'Runtime', source:'tweaks/gamemode.runtime.json' },
    { id:'toggles', label:'Toggles', source:'tweaks/game.mode.json' }
  ]},
  stretchLab: { title: 'StretchLab', sub: 'Copy real pro stretch res and apply clean presets.', tabs: [] },
  advanced: { title: 'Advanced', sub: 'Device, MSI, and security controls.', tabs: [
    { id:'importReg', label:'Imported Registry', source:'tweaks/imported.registry.oneclick.json' },
    { id:'devices', label:'Devices', source:'tweaks/advanced.devices.json' },
    { id:'msi', label:'MSI Mode', source:'tweaks/advanced.msi_mode.json' },
    { id:'security', label:'Security', source:'tweaks/advanced.security.json' }
  ]},
  fortnite: { title: 'Game Specific', sub: 'Per-game competitive tweaks, guides, and helpers.', tabs: [
    { id:'fortniteCompetitive', label:'Fortnite', source:'tweaks/fortnite.competitive.json' },
    { id:'overwatch2', label:'Overwatch 2', source:'tweaks/game.overwatch.json' },
    { id:'apex', label:'Apex Legends', source:'tweaks/game.apex.json' },
    { id:'geforceNow', label:'GeForce NOW', source:'tweaks/game.geforcenow.json' },
    { id:'valorant', label:'Valorant', source:'tweaks/game.valorant.json' },
    { id:'cs2', label:'CS2', source:'tweaks/game.cs2.json' },
    { id:'stretchRes', label:'Stretch Resolution', source:'tweaks/game.stretchres.json' },
    { id:'rocketLeague', label:'Rocket League', source:'tweaks/game.rocketleague.json' },
    { id:'gta5', label:'GTA V', source:'tweaks/game.gta5.json' },
    { id:'league', label:'League of Legends', source:'tweaks/game.league.json' },
    { id:'priorityScheduler', label:'Priority Scheduler', source:'tweaks/game.priority.scheduler.json' },
    { id:'gameGuides', label:'Game Guides & Helpers', source:'tweaks/game.specific.json' },
    { id:'gamePack', label:'GamePack 2.0 (Auto)', source:'tweaks/game.autodetect.json' }
  ]},
  expansion: { title: 'Expansion', sub: 'Extra granular toggles (Phase 3).', tabs: [
    { id:'bg', label:'Background Apps', source:'tweaks/expansion.backgroundapps.json' },
    { id:'tasks', label:'Scheduled Tasks', source:'tweaks/expansion.tasks.json' },
    { id:'services', label:'Services', source:'tweaks/expansion.services.json' },
    { id:'registry', label:'Registry', source:'tweaks/expansion.registry.json' },
    { id:'nvidia', label:'NVIDIA Tools', source:'tweaks/expansion.nvidia.tools.json' },
    { id:'impReg', label:'Imported Registry', source:'tweaks/expansion.imported.registry.json' },
    { id:'impSvc', label:'Imported Services', source:'tweaks/expansion.imported.services.json' },
    { id:'impPower', label:'Imported Power + BCD', source:'tweaks/expansion.imported.power_bcd.json' },
    { id:'impDebloat', label:'Imported Debloat + Cleanup', source:'tweaks/expansion.imported.debloat_cleanup.json' },
    { id:'impSec', label:'Imported Security', source:'tweaks/expansion.imported.security.json' },
    { id:'impMisc', label:'Imported Misc', source:'tweaks/expansion.imported.misc.json' }
  ]},
  
  hardcore: { title: 'Hardcore Tweaks', sub: 'EXTREME / DANGEROUS – max FPS, minimum delay.', tabs: [
  { id:'all', label:'All Hardcore Tweaks', source:'tweaks/hardcore.tweaks.json' }
]}, 

bios: { title: 'BIOS / UEFI Helper', sub: 'Motherboard detection and firmware shortcuts.', tabs: [] },
  themes: { title: 'Themes', sub: 'Switch visual presets for Falcon Optimizer.', tabs: [] },
  language: { title: 'Language', sub: 'Choose language preferences for Falcon Optimizer.', tabs: [] },
  utilities: { title: 'Apps / Utilities', sub: 'Installers and utilities.', tabs: [
    { id:'tools', label:'Tools', source:'tweaks/utilities.json' },
    { id:'audit', label:'Pro Gamer Audit', source:'tweaks/audit.progamer.json' }
  ]}
};


let themeEngine = null;
let themeList = [];
let currentThemeId = null;
let fxIntensity = "full"; // off | subtle | full

async function loadThemeEngine(){
  if (themeEngine) return themeEngine;
  // hydrate FX intensity from localStorage once per boot
  try {
    if (window && window.localStorage) {
      const storedFx = window.localStorage.getItem("falcon.fxIntensity");
      if (storedFx === "off" || storedFx === "subtle" || storedFx === "full") {
        fxIntensity = storedFx;
      }
    }
  } catch (_) {}
  try{
    const res = await fetch("themesystem/theme-engine.json");
    themeEngine = await res.json();
    themeList = Object.entries(themeEngine.themes || {}).map(([id, t]) => ({ id, ...(t||{}) }));
    const stored = window.localStorage ? window.localStorage.getItem("falcon.theme.id") : null;
    if (stored && themeEngine.themes[stored]) {
      currentThemeId = stored;
      applyThemeById(stored, false);
    } else {
      const def = themeEngine.defaultTheme && themeEngine.themes[themeEngine.defaultTheme]
        ? themeEngine.defaultTheme
        : (themeList[0]?.id || null);
      if (def) {
        currentThemeId = def;
        applyThemeById(def, false);
      }
    }
  }catch(e){
    console.error("Failed to load theme engine", e);
  }
  return themeEngine;
}


function applyThemeById(id, persist=true){
  if (!themeEngine || !themeEngine.themes) return;
  const theme = themeEngine.themes[id];
  if (!theme) return;

  currentThemeId = id;

  // Persist selection
  if (persist && window.localStorage) {
    try { window.localStorage.setItem("falcon.theme.id", id); } catch(e){}
  }

  // Expose theme id + FX hints to CSS
  const root = document.documentElement;
  try {
    root.setAttribute("data-theme", id);
    const fxMode = theme["fx-mode"] || "glass";
    const fxCorners = theme["fx-corners"] || "rounded";
    const fxOverlay = theme["fx-overlay"] || "";
    const fxToast = theme["fx-toast"] || "";
    root.setAttribute("data-fx-mode", fxMode);
    root.setAttribute("data-fx-corners", fxCorners);
    if (fxOverlay) root.setAttribute("data-fx-overlay", fxOverlay);
    if (fxToast) root.setAttribute("data-fx-toast", fxToast);
  } catch(e){}

  const set = (k,v) => root.style.setProperty(k, v);

  // Core surfaces
  set("--bg", theme["bg"] || "#0f172a");
  set("--bg2", theme["bg2"] || theme["bg"] || "#020617");
  set("--card", theme["card"] || "#0b1120");
  set("--card2", theme["card2"] || theme["card"] || "#020617");

  // Text
  set("--text", theme["text-main"] || "#e5e7eb");
  set("--muted", theme["text-muted"] || "#9ca3af");
  set("--fg-main", theme["text-main"] || "#e5e7eb");
  set("--fg-muted", theme["text-muted"] || "#9ca3af");

  // Accents & glow
  set("--accent", theme["accent-main"] || "#ef4444");
  set("--glow", theme["glow-soft"] || "rgba(248,113,113,0.35)");
  set("--stroke", theme["border"] || "rgba(15,23,42,0.25)");

  // Optional shadows
  if (theme["shadow-1"]) set("--shadow-strong", theme["shadow-1"]);
  if (theme["shadow-2"]) set("--shadow-soft", theme["shadow-2"]);

  // Optional extras: buttons + FPS bars
  if (theme["button-bg"]) set("--btn-bg", theme["button-bg"]);
  if (theme["button-fg"]) set("--btn-fg", theme["button-fg"]);
  if (theme["fps-bar-track"]) set("--fps-track", theme["fps-bar-track"]);
  if (theme["fps-bar-fill"]) set("--fps-fill", theme["fps-bar-fill"]);

  // Drive high-detail particle FX for current theme
  try {
    if (typeof updateThemeFxParticles === "function") {
      updateThemeFxParticles(id);
    }
  } catch(e){
    console && console.warn && console.warn('updateThemeFxParticles failed', e);
  }
}
// Render Themes route panel
function renderThemes(){
  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Themes & Visual FX</div>
      <div class="card-desc">
        Choose a Falcon visual preset and particle intensity. Themes only change how the optimizer looks – not how your system performs.
        Use a bold preset for daily use, or a clean minimal one for focus mode.
      </div>
      <div class="card">
        <div class="card-title">Theme selection</div>
        <div class="card-desc">Pick a theme and FX level. Changes apply instantly across the app.</div>
        <div class="card-actions" style="display:flex;flex-wrap:wrap;gap:8px;">
          <label class="field-label" style="display:flex;align-items:center;gap:6px;">
            Theme:
            <select id="themeSelect"></select>
          </label>
          <label class="field-label" style="display:flex;align-items:center;gap:6px;">
            FX intensity:
            <select id="fxIntensitySelect">
              <option value="full">Full</option>
              <option value="subtle">Subtle</option>
              <option value="off">Off</option>
            </select>
          </label>
        </div>
        <p class="bios-note" style="margin-top:8px;">
          FX intensity controls overlays, particles, and glow levels. Turning FX off can very slightly help GPU temps on low-end rigs.
        </p>
      </div>
    </div>
    <div class="panel">
      <div class="card-title">Theme gallery</div>
      <div class="card-desc">
        Click a card to apply a theme. The gallery uses real colors and gradients from each preset so you can see the vibe before applying.
      </div>
      <div id="themeGrid" class="theme-grid"></div>
    </div>
  `;

  loadThemeEngine().then(() => {
    const select = document.getElementById("themeSelect");
    const grid = document.getElementById("themeGrid");
    const fxSelect = document.getElementById("fxIntensitySelect");
    if (!select || !grid || !themeList.length) return;

    // Populate theme dropdown
    select.innerHTML = "";
    themeList.forEach(t => {
      const opt = document.createElement("option");
      opt.value = t.id;
      opt.textContent = t.name || t.id;
      if (t.id === currentThemeId) opt.selected = true;
      select.appendChild(opt);
    });

    // Wire FX intensity selector
    if (fxSelect) {
      try {
        fxSelect.value = fxIntensity || 'full';
      } catch(_e) {}
      fxSelect.onchange = () => {
        fxIntensity = fxSelect.value || 'full';
        try { window.localStorage.setItem('falcon.fxIntensity', fxIntensity); } catch(_e) {}
        try {
          if (typeof updateThemeFxParticles === 'function' && currentThemeId) {
            updateThemeFxParticles(currentThemeId);
          }
        } catch(_e) {}
        showToast('Preference saved.', 'info');
      };
    }

    function buildGrid(){
      grid.innerHTML = "";
      themeList.forEach(t => {
        const card = document.createElement("button");
        card.className = "theme-card" + (t.id === currentThemeId ? " active" : "");
        card.dataset.themeId = t.id;

        const previewGradient = t["panel-gradient"] || "linear-gradient(135deg,#111827,#020617)";
        const accent = t["accent-main"] || "#ef4444";
        const bg = t["bg"] || "#020617";

        card.innerHTML = `
          <div class="theme-preview" style="background:${previewGradient};">
            <div class="theme-preview-bar" style="background:${bg};"></div>
            <div class="theme-preview-fps-track">
              <div class="theme-preview-fps-fill" style="background:${t["fps-bar-fill"]||accent};"></div>
            </div>
          </div>
          <div class="theme-meta">
            <div class="theme-name">${__eh(t.name || t.id)}</div>
            <div class="theme-tagline">${__eh(t["background-art"] || "Custom visual preset")}</div>
          </div>
        `;
        card.onclick = () => {
          applyThemeById(t.id, true);
          currentThemeId = t.id;
          buildGrid();
          select.value = t.id;
          showToast('Theme "' + (t.name || t.id) + '" applied.', 'success');
        };
        grid.appendChild(card);
      });
    }

    // React to dropdown changes
    select.onchange = () => {
      const id = select.value;
      if (!id) return;
      applyThemeById(id, true);
      currentThemeId = id;
      buildGrid();
      try {
        if (typeof updateThemeFxParticles === 'function') {
          updateThemeFxParticles(id);
        }
      } catch(_e) {}
      showToast('Theme "' + id + '" applied.', 'success');
    };

    buildGrid();
  }).catch((e) => {
    console.error("Failed to load/apply themes", e);
    showToast('Failed to load themes. Check theme-engine.json.', 'error');
  });
}
function renderResult(res){
  const ok = !!(res && res.ok);
  const errs = (res && res.errors) ? res.errors : [];
  const warns = (res && res.warnings) ? res.warnings : [];
  lastLogFile = res && res.logFile ? res.logFile : null;
  if (els.runStatus) { els.runStatus.classList.remove("ok","fail"); els.runStatus.classList.add(ok ? "ok" : "fail"); }

  appendRunOutput(ok ? "OK" : "FAILED");

  const stepResults = (res && res.stepResults) ? res.stepResults : null;
  if (stepResults && Array.isArray(stepResults) && stepResults.length) {
    const okCount = stepResults.filter(s=>s && s.ok).length;
    const fail = stepResults.filter(s=>s && !s.ok);
    appendRunOutput(`Steps: ${okCount}/${stepResults.length} OK`);
    if (fail.length) {
      appendRunOutput("Failed steps:");
      fail.slice(0,20).forEach(s=>appendRunOutput(` - ${s.type || "step"}: ${s.label || ""}`));
      if (fail.length > 20) appendRunOutput(` - ...and ${fail.length-20} more`);
    }
  }

  if (warns && warns.length) {
    appendRunOutput("");
    appendRunOutput("Warnings:");
    warns.forEach(w=>appendRunOutput(" - " + (w.msg || w)));
  }
  if (errs && errs.length) {
    appendRunOutput("");
    appendRunOutput("Errors:");
    errs.forEach(e=>appendRunOutput(" - " + (e.msg || e)));
  }

  if (res && res.stderr) {
    appendRunOutput("");
    appendRunOutput("Stderr:");
    appendRunOutput(String(res.stderr));
  }
  if (res && res.stdout) {
    appendRunOutput("");
    appendRunOutput("Stdout:");
    appendRunOutput(String(res.stdout));
  }
  if (lastLogFile) {
    appendRunOutput("");
    appendRunOutput("Log: " + lastLogFile);
  }
}

function renderTweakDetails(item){
  try{
    const detailsEl = document.getElementById('tweakDetails');
    if(!detailsEl){
      return;
    }
    if(!item){
      detailsEl.textContent = 'No additional details available for this tweak.';
      return;
    }
    const desc = item.description || '';
    const applySteps = adjustStepsForHwProfile(item, 'apply', getApplyStepsWithVerify(item)) || [];
    const revertSteps = getStepsFor(item,'revert') || [];
    const logRec = (item.id && tweakLogsById && tweakLogsById[item.id]) ? tweakLogsById[item.id] : null;
    if(!desc && (!applySteps || !applySteps.length) && (!revertSteps || !revertSteps.length) && !logRec){
      detailsEl.textContent = 'No additional details available for this tweak.';
      return;
    }
    let out = '';
    out += 'Name: ' + (item.name || item.id || '(unnamed)') + '\n';
    out += 'ID: ' + (item.id || '(none)') + '\n';
    out += 'Risk: ' + (item.riskLevel || item.risk || 'Safe') + '\n\n';
    if(desc){
      out += 'Description:\n' + desc + '\n\n';
    }
    if(applySteps && applySteps.length){
      out += 'Apply steps (' + applySteps.length + '):\n' + JSON.stringify(applySteps, null, 2) + '\n\n';
    }
    if(revertSteps && revertSteps.length){
      out += 'Revert steps (' + revertSteps.length + '):\n' + JSON.stringify(revertSteps, null, 2) + '\n\n';
    }
    if(logRec && logRec.text){
      out += 'Last run output (' + (logRec.mode || 'apply') + '):\n' + logRec.text + '\n';
    } else {
      out += 'No previous run output recorded for this tweak.\n';
    }
    detailsEl.textContent = out;
  }catch(e){
    try{ console && console.warn && console.warn('renderTweakDetails failed', e); }catch(_e){}
  }
}

const els = {
  pageTitle: document.getElementById('pageTitle'),
  pageSub: document.getElementById('pageSub'),
  tabs: document.getElementById('tabs'),
  panel: document.getElementById('panel'),
  searchInput: document.getElementById('searchInput'),
  runStatus: document.getElementById('runStatus'),
  runStatusTitle: document.getElementById('runStatusTitle'),
  runStatusMeta: document.getElementById('runStatusMeta'),
  runProgress: document.getElementById('runProgress'),
  runOutput: document.getElementById('runOutput'),
  openLogBtn: document.getElementById('openLogBtn'),
  clearRunBtn: document.getElementById('clearRunBtn')
};


// =========================
// Run status helpers (Fixes / Scripts / Optimizations)
// =========================
// If these are missing, clicks can appear to do nothing due to ReferenceError.
function showRunPanel(title, meta){
  try{
    if(!els.runStatus) return;
    els.runStatus.style.display = 'block';
    if(els.runStatusTitle) els.runStatusTitle.textContent = title || 'Running…';
    if(els.runStatusMeta) els.runStatusMeta.textContent = meta || '';
    if(els.runProgress){ els.runProgress.value = 0; }
    if(els.runOutput){ els.runOutput.textContent = ''; }
    if(els.runStatus){ els.runStatus.classList.remove('ok','fail'); }
  }catch(e){ try{ console && console.warn && console.warn('showRunPanel failed', e); }catch(_e){} }
}
function hideRunPanel(){
  try{
    if(!els.runStatus) return;
    els.runStatus.style.display = 'none';
  }catch(e){ try{ console && console.warn && console.warn('hideRunPanel failed', e); }catch(_e){} }
}
function setProgress(pct, label){
  try{
    if(els.runProgress) els.runProgress.value = Math.max(0, Math.min(100, Number(pct)||0));
    if(label) appendRunOutput(String(label));
  }catch(e){ try{ console && console.warn && console.warn('setProgress failed', e); }catch(_e){} }
}
function appendRunOutput(line){
  try{
    if(!els.runOutput) return;
    const s = (line === null || line === undefined) ? '' : String(line);
    els.runOutput.textContent += (els.runOutput.textContent ? '\n' : '') + s;
  }catch(e){ try{ console && console.warn && console.warn('appendRunOutput failed', e); }catch(_e){} }
}
function clearRunOutput(){
  try{ if(els.runOutput) els.runOutput.textContent = ''; }catch(_e){}
}

// Wire buttons (safe: only if present)
try{
  if(els.clearRunBtn){
    els.clearRunBtn.onclick = () => { clearRunOutput(); showToast('Output cleared.', 'info'); };
  }
  if(els.openLogBtn){
    els.openLogBtn.onclick = async () => {
      if(lastLogFile){
        await window.falcon.openPath(lastLogFile);
        showToast('Opening log file…', 'info');
      }else{
        showToast('No log file available for last run.', 'error');
      }
    };
  }
}catch(_e){}


function setBatchProgress(show, current, total, label){
  const wrap = document.getElementById('batchProgressWrap');
  const bar = document.getElementById('batchProgressBar');
  const pct = document.getElementById('batchProgressPct');
  const lab = document.getElementById('batchProgressLabel');
  if(!wrap || !bar || !pct || !lab) return;
  if(!show){ wrap.style.display='none'; return; }
  wrap.style.display='block';
  const p = total>0 ? Math.round((current/total)*100) : 0;
  bar.style.width = `${p}%`;
  pct.textContent = `${p}%`;
  lab.textContent = label || `Running ${current}/${total}`;
}

function resolveConflictGroups(items){
  const seen = new Map();
  const kept = [];
  const skipped = [];
  for(const it of items){
    const g = it.conflictGroup ? String(it.conflictGroup) : "";
    if(!g){ kept.push(it); continue; }
    if(seen.has(g)){
      skipped.push({ id: it.id, group: g, kept: seen.get(g) });
      continue;
    }
    seen.set(g, it.id);
    kept.push(it);
  }
  return { kept, skipped };
}

function escapeHtml(s){
  return (s||'').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
function setActiveNav(route){
  document.querySelectorAll('.nav-item').forEach(btn=>{
    btn.classList.toggle('active', btn.dataset.route === route);
  });
}
function renderTabs(route){
  const cfg = routes[route];
  els.tabs.innerHTML = '';
  if(!cfg.tabs || cfg.tabs.length === 0){ els.tabs.style.display = 'none'; return; }
  els.tabs.style.display = 'flex';
  cfg.tabs.forEach(t=>{
    const b = document.createElement('button');
    b.className = 'tab' + (currentTab?.id===t.id ? ' active' : '');
    b.textContent = t.label;
    b.onclick = () => { currentTab = t; refresh(false); };
    els.tabs.appendChild(b);
  });
}

function riskBadge(risk){
  const r = String(risk||"Safe");
  const cls = r==="Critical" ? "risk-critical" : (r==="High" ? "risk-high" : (r==="Warning" ? "risk-warning" : ""));
  return `<span class="badge ${cls}">${__eh(r)}</span>`;
}


function formatDescription(desc){
  const raw = String(desc || "");
  let mode = "full";
  try {
    if (window.localStorage) {
      mode = window.localStorage.getItem('falcon.ui.languageDetail') || 'full';
    }
  } catch(_e) {}

  if (mode === 'compact') {
    const idx = raw.indexOf('.');
    if (idx > 0 && idx < raw.length - 1) {
      return raw.slice(0, idx + 1);
    }
    return raw;
  }
  return raw;
}

async function loadPcSpecsAndFps(){
  const cpuEl = document.getElementById('specCPU');
  const gpuEl = document.getElementById('specGPU');
  const ramEl = document.getElementById('specRAM');
  const vramEl = document.getElementById('specVRAM');
  const osEl = document.getElementById('specOS');
  const mbEl = document.getElementById('specMotherboard');
  const fpsWrap = document.getElementById('fpsEstimates');
  if (!cpuEl || !gpuEl || !ramEl || !osEl || !fpsWrap) return;

  const isPreviewMode = (!window.falcon || !window.falcon.getSystemInfo);
  const previewInfo = {
    CPU: "Preview CPU (Browser)",
    GPU: "Preview GPU (Browser)",
    RAMBytes: 16 * 1024 * 1024 * 1024,
    OS: "Windows 11 (Preview)",
    GPUVRAM: 8,
    MotherboardLabel: "Preview Motherboard"
  };
  const fpsHint = document.getElementById('fpsHint');

  try {
    const res = isPreviewMode ? { info: previewInfo } : await window.falcon.getSystemInfo();
    const info = res && res.info ? res.info : null;
    if (!info) throw new Error("No system info");

    const cpuName = info.CPU || info.cpu || "Unknown CPU";
    const gpuName = info.GPU || info.gpu || info.GPUN || "Unknown GPU";
    const ramBytes = info.RAMBytes || info.ramBytes || info.ram || 0;
    const ramGb = ramBytes ? Math.round(ramBytes / (1024*1024*1024)) : null;
    const osName = info.OS || info.os || "Windows";
    const vramGb = (info.GPUVRAM || info.gpuVramGb || info.gpuVram || null);
    const mbLabel = info.MotherboardLabel || [info.MotherboardManufacturer, info.MotherboardProduct].filter(Boolean).join(' ') || null;
    lastSystemInfo = info;
    // Detect GPU vendor for gating GPU-specific tweaks
    let detectedVendor = info.GPUVendor || "";
    if (!detectedVendor) {
      const lowerGpu = String(gpuName || "").toLowerCase();
      if (lowerGpu.includes("nvidia") || lowerGpu.includes("geforce") || lowerGpu.includes("rtx") || lowerGpu.includes("gtx")) {
        detectedVendor = "nvidia";
      } else if (lowerGpu.includes("amd") || lowerGpu.includes("radeon") || lowerGpu.includes("rx ")) {
        detectedVendor = "amd";
      } else if (lowerGpu.includes("intel") || lowerGpu.includes("iris") || lowerGpu.includes("uhd")) {
        detectedVendor = "intel";
      } else {
        detectedVendor = "unknown";
      }
    }
    currentGpuVendor = detectedVendor || "unknown";



    cpuEl.textContent = cpuName;
    gpuEl.textContent = gpuName;
    ramEl.textContent = ramGb ? ramGb + " GB" : "Unknown";
    osEl.textContent = osName;
    if (vramEl) {
      vramEl.textContent = vramGb ? (vramGb + " GB") : "Unknown";
    }
    if (mbEl) {
      mbEl.textContent = mbLabel || "Unknown";
    }
    if (fpsHint && isPreviewMode) {
      fpsHint.textContent = "Preview mode: hardware data is mocked for the browser UI preview.";
    }

    const tier = classifyPerfTier(cpuName, gpuName, ramGb || 0);

    try {
      var hwTier = mapHardwareTierFromPerf(tier, cpuName, gpuName, ramGb || 0, vramGb || 0);
      if (window.falcon) {
        window.falcon.hardwareTier = hwTier;
      }
      if (!window.__falconHardwareToastShown) {
        window.__falconHardwareToastShown = true;
        var label = hwTier === "high" ? "High-End" : (hwTier === "low" ? "Low-End" : "Mid-End");
        showToast("Detected hardware tier: " + label + ".", "info");
      }
    } catch(_e) {}

    // Render simple CPU/GPU/RAM comparison vs common gaming builds
    const compareWrap = document.getElementById('specCompare');
    if (compareWrap) {
      const cpuFill = document.getElementById('specCompareCpuFill');
      const gpuFill = document.getElementById('specCompareGpuFill');
      const ramFill = document.getElementById('specCompareRamFill');
      const summaryEl = document.getElementById('specCompareSummary');

      function tierToPct(t) {
        switch (t) {
          case 'ultra': return 100;
          case 'high': return 85;
          case 'mid': return 70;
          case 'entry': return 55;
          case 'low': return 40;
          default: return 60;
        }
      }

      function ramToPct(gb) {
        if (!gb) return 0;
        if (gb >= 32) return 100;
        if (gb >= 24) return 90;
        if (gb >= 16) return 75;
        if (gb >= 12) return 65;
        if (gb >= 8) return 55;
        return 40;
      }

      const perfPct = tierToPct(tier);
      const ramPct = ramToPct(ramGb || 0);

      if (cpuFill) cpuFill.style.width = perfPct + "%";
      if (gpuFill) gpuFill.style.width = perfPct + "%";
      if (ramFill) ramFill.style.width = ramPct + "%";

      if (summaryEl) {
        let hwLabel = 'Mid-End';
        if (typeof hwTier === 'string') {
          if (hwTier === 'high') hwLabel = 'High-End';
          else if (hwTier === 'low') hwLabel = 'Low-End';
        }
        const gpuText = (hwLabel === 'High-End')
          ? 'Your GPU is roughly High-End for 1080p esports (around or above RTX 3060 / RX 6700).'
          : (hwLabel === 'Mid-End')
            ? 'Your GPU is Mid-End – solid for 1080p esports, but may struggle with ultra settings in new AAA titles.'
            : 'Your GPU is Low-End – focus on competitive settings and lower resolutions for stable FPS.';
        const cpuText = (hwLabel === 'High-End')
          ? 'Your CPU is strong enough for very high FPS in most competitive games.'
          : (hwLabel === 'Mid-End')
            ? 'Your CPU is Mid-End and may bottleneck ultra-high FPS in some CPU-heavy games.'
            : 'Your CPU is the likely bottleneck; close background apps and prefer high-FPS, low-CPU game configs.';
        const ramText = (ramGb && ramGb >= 32)
          ? 'Your RAM (32 GB or more) is ideal for heavy multitasking and modern titles.'
          : (ramGb && ramGb >= 16)
            ? 'Your RAM (16 GB) is ideal for most competitive games.'
            : (ramGb && ramGb >= 8)
              ? 'Your RAM is workable but can limit smoothness in some heavy titles.'
              : 'Your RAM is below 8 GB; consider upgrading for best stability.';

        summaryEl.textContent = gpuText + ' ' + cpuText + ' ' + ramText;
      }
    }

    const fpsRows = buildFpsRowsForTier(tier);
    if (typeof updatePerfTopology === "function") {
      updatePerfTopology(tier);
    }
    fpsRows.forEach(row => {
      const rowEl = document.createElement('div');
      rowEl.className = 'fps-row';
      const gameEl = document.createElement('div');
      gameEl.className = 'fps-game';
      gameEl.textContent = row.game;
      const fpsCell = document.createElement('div');
      fpsCell.className = 'fps-fps';
      const bar = document.createElement('div');
      bar.className = 'fps-bar';
      const fill = document.createElement('div');
      fill.className = 'fps-bar-fill';
      const pct = Math.max(8, Math.min(100, Math.round(row.fps / 400 * 100)));
      fill.style.width = pct + "%";
      const label = document.createElement('span');
      label.className = 'fps-bar-label';
      label.textContent = row.fps + " FPS";
      bar.appendChild(fill);
      bar.appendChild(label);
      fpsCell.appendChild(bar);
      rowEl.appendChild(gameEl);
      rowEl.appendChild(fpsCell);
      fpsWrap.appendChild(rowEl);
    });
  } catch (e) {
    cpuEl.textContent = gpuEl.textContent = ramEl.textContent = osEl.textContent = "Failed to detect (run as admin?).";
    if (vramEl) vramEl.textContent = "Failed to detect (run as admin?).";
  }
}


function classifyPerfTier(cpuName, gpuName, ramGb){
  const name = (gpuName || "").toUpperCase();
  const cpu  = (cpuName || "").toUpperCase();
  const ram  = ramGb || 0;

  const highGpuTags = [
    "RTX 4090","RTX 4080","RTX 4070 TI","RTX 4070",
    "RTX 4060 TI","RTX 3090","RTX 3080","RX 7900","RX 7800"
  ];
  const midGpuTags = [
    "RTX 3060","RTX 2070","RTX 2060",
    "GTX 1080","GTX 1660",
    "RX 6700","RX 6600","RX 5700","RX 5600"
  ];
  const entryGpuTags = [
    "GTX 1050","GTX 970","GTX 960",
    "RX 580","RX 570","RX 480"
  ];

  const hasTag = (tags) => tags.some(tag => name.includes(tag));

  const isHighCpu = /I[79]-1[2-9]\d{2}|RYZEN 7|RYZEN 9/.test(cpu);
  const isMidCpu  = /I5-|RYZEN 5/.test(cpu);

  if (hasTag(highGpuTags) && ram >= 16) return "ultra";
  if ((hasTag(highGpuTags) || isHighCpu) && ram >= 16) return "high";
  if ((hasTag(midGpuTags) || isMidCpu) && ram >= 16) return "mid";
  if (hasTag(entryGpuTags) && ram >= 8) return "entry";

  if (ram >= 32) return "mid";
  if (ram >= 16) return "entry";
  return "low";
}

function mapHardwareTierFromPerf(tier,cpuName,gpuName,ramGb,vramGb){
  // Map esports perf tier + RAM + VRAM into coarse hardware tier used by Apply-All filtering
  const t = tier || "mid";
  const ram = ramGb || 0;
  const vram = vramGb || 0;
  // If RAM or VRAM are very low, treat as low-end regardless of raw perf score
  if ((ram && ram < 8) || (vram && vram < 4)) return "low";
  // Strong GPUs/CPUs with decent RAM+VRAM are high-end
  if ((t === "ultra" || t === "high") && ram >= 16 && vram >= 8) return "high";
  if ((t === "ultra" || t === "high") && (ram >= 16 || vram >= 6)) return "high";
  // Mid / entry perf tiers map to mid, given enough RAM
  if ((t === "mid" || t === "entry") && ram >= 8 && vram >= 4) return "mid";
  // Fallbacks: good RAM but unknown VRAM -> mid; otherwise low
  if (ram >= 16) return "mid";
  return "low";
}

function buildFpsRowsForTier(tier){
  const base = {
    ultra: { fortnite: 450, valorant: 500, cs2: 420, apex: 280 },
    high:  { fortnite: 360, valorant: 420, cs2: 360, apex: 240 },
    mid:   { fortnite: 240, valorant: 320, cs2: 260, apex: 180 },
    entry: { fortnite: 160, valorant: 220, cs2: 180, apex: 120 },
    low:   { fortnite: 100, valorant: 160, cs2: 140, apex: 90 }
  }[tier || "mid"];
  return [
    { game: "Fortnite (Performance)", fps: base.fortnite },
    { game: "Valorant", fps: base.valorant },
    { game: "CS2", fps: base.cs2 },
    { game: "Apex Legends", fps: base.apex }
  ];
}


function tierVisualMeta(tier){
  const key = tier || "mid";
  const presets = {
    ultra: {
      cpuLoad: 78, cpuHeadroom: 22,
      gpuLoad: 88, gpuHeadroom: 12,
      ramLoad: 62, ramHeadroom: 38,
      storageSnap: 92, storageLatency: 14,
      netStability: 90, netLatency: 18,
      thermAvg: 72, thermPeak: 88
    },
    high: {
      cpuLoad: 72, cpuHeadroom: 28,
      gpuLoad: 80, gpuHeadroom: 20,
      ramLoad: 58, ramHeadroom: 42,
      storageSnap: 84, storageLatency: 20,
      netStability: 84, netLatency: 22,
      thermAvg: 68, thermPeak: 84
    },
    mid: {
      cpuLoad: 64, cpuHeadroom: 36,
      gpuLoad: 72, gpuHeadroom: 28,
      ramLoad: 52, ramHeadroom: 48,
      storageSnap: 76, storageLatency: 26,
      netStability: 78, netLatency: 28,
      thermAvg: 62, thermPeak: 78
    },
    entry: {
      cpuLoad: 56, cpuHeadroom: 44,
      gpuLoad: 64, gpuHeadroom: 36,
      ramLoad: 48, ramHeadroom: 52,
      storageSnap: 68, storageLatency: 32,
      netStability: 70, netLatency: 34,
      thermAvg: 58, thermPeak: 74
    },
    low: {
      cpuLoad: 48, cpuHeadroom: 52,
      gpuLoad: 58, gpuHeadroom: 42,
      ramLoad: 44, ramHeadroom: 56,
      storageSnap: 60, storageLatency: 38,
      netStability: 64, netLatency: 40,
      thermAvg: 54, thermPeak: 70
    }
  };
  return presets[key] || presets.mid;
}

function updatePerfTopology(tier){
  const meta = tierVisualMeta(tier);
  if (!meta) return;

  const barMap = [
    ["cpuLoadBar", meta.cpuLoad],
    ["cpuHeadroomBar", meta.cpuHeadroom],
    ["gpuLoadBar", meta.gpuLoad],
    ["gpuHeadroomBar", meta.gpuHeadroom],
    ["ramLoadBar", meta.ramLoad],
    ["ramHeadroomBar", meta.ramHeadroom],
    ["storageSnapBar", meta.storageSnap],
    ["storageLatencyBar", meta.storageLatency],
    ["netStabilityBar", meta.netStability],
    ["netLatencyBar", meta.netLatency],
    ["thermAvgBar", meta.thermAvg],
    ["thermPeakBar", meta.thermPeak]
  ];

  barMap.forEach(([id, value]) => {
    const el = document.getElementById(id);
    if (!el) return;
    const pct = Math.max(4, Math.min(100, Number(value) || 0));
    el.style.width = pct + "%";
    el.style.setProperty("--fill-pct", pct + "%");
  });

  const tierLabel = (tier || "mid").toUpperCase();
  const nice = {
    ultra: "S-tier latency (ULTRA esports)",
    high: "A-tier latency (HIGH competitive)",
    mid: "B-tier latency (mid-range)",
    entry: "C-tier latency (entry)",
    low: "D-tier latency (low-end)"
  }[tier || "mid"] || tierLabel;

  const labelIds = [
    "cpuTierLabel",
    "gpuTierLabel",
    "ramTierLabel",
    "storageTierLabel",
    "netTierLabel",
    "thermTierLabel"
  ];
  labelIds.forEach(id => {
    const el = document.getElementById(id);
    if (el) el.textContent = nice;
  });
}

function guessBiosKeysForVendor(vendorRaw){
  const v = (vendorRaw || '').toUpperCase();
  if (!v) return 'Common keys: Del, F2, Esc, F10, F12 (press repeatedly during startup).';
  if (v.includes('ASUS')) return 'ASUS: Del or F2 during startup.';
  if (v.includes('MSI')) return 'MSI: Del during startup.';
  if (v.includes('GIGABYTE')) return 'Gigabyte: Del or F12 during startup.';
  if (v.includes('ASROCK')) return 'ASRock: F2 or Del during startup.';
  if (v.includes('DELL')) return 'Dell: F2 or F12 during startup.';
  if (v.includes('HP')) return 'HP: F10 or Esc during startup.';
  if (v.includes('LENOVO')) return 'Lenovo: F1, F2, or the Novo button (small side button) during startup.';
  if (v.includes('ACER')) return 'Acer: Del or F2 during startup.';
  return 'Common keys: Del, F2, Esc, F10, F12 (press repeatedly during startup).';
}

function buildXmpGuideForVendor(vendorRaw){
  const v = (vendorRaw || '').toUpperCase();
  if (!v) return 'In your BIOS/UEFI, look for an XMP, EXPO, or DOCP option in the overclocking/memory menu. Enable the first profile, save, and restart. If the PC becomes unstable, disable it again.';
  if (v.includes('ASUS')) return 'ASUS: In BIOS, go to Ai Tweaker / Extreme Tweaker → set DOCP/XMP I/XMP II to Enabled, then save and restart.';
  if (v.includes('MSI')) return 'MSI: In BIOS, go to OC tab → enable XMP Profile 1 (or EXPO for AMD), then save and restart.';
  if (v.includes('GIGABYTE')) return 'Gigabyte: In BIOS, go to Tweaker → enable X.M.P Profile 1, then save and restart.';
  if (v.includes('ASROCK')) return 'ASRock: In BIOS, go to OC Tweaker → load XMP Profile 1, then save and restart.';
  if (v.includes('DELL') || v.includes('HP') || v.includes('LENOVO') || v.includes('ACER')) return 'Many OEM prebuilts do not expose XMP/EXPO controls. If you see no XMP setting in BIOS, your system may not support it.';
  return 'In your BIOS/UEFI, look for XMP, EXPO, or DOCP in the memory/overclocking menu, enable the first profile, then save and restart. If unstable, revert the change.';
}

function buildRebarGuideForVendor(gpuVendor, status){
  const vendor = (gpuVendor || '').toLowerCase();
  let base;
  if (status === 'Enabled') base = 'Resizable BAR appears ENABLED in Windows. You are already benefiting from it.';
  else if (status === 'Disabled') base = 'Resizable BAR appears DISABLED. You may be able to turn it on in BIOS and your GPU drivers.';
  else base = 'Windows could not confirm Resizable BAR. Support depends on your CPU, motherboard, and GPU generation.';

  if (vendor === 'nvidia') {
    return base + ' On NVIDIA RTX 30/40 series, enable Above 4G Decoding and Resizable BAR in BIOS, then ensure your VBIOS and drivers support ReBAR.';
  }
  if (vendor === 'amd') {
    return base + ' On AMD RX 6000/7000 series, enable Above 4G Decoding and Resizable BAR / Smart Access Memory in BIOS, then toggle Smart Access Memory in Radeon Software.';
  }
  return base + ' Many systems expose this as "Resizable BAR" and "Above 4G decoding" options in BIOS. If you do not see them, your platform may not support ReBAR.';
}


const BIOS_GUIDE = {
  memory: {
    key: "memory",
    label: "Memory (XMP / RAM timings)",
    summary: "RAM speed and timings strongly influence 1% lows and input latency. Always test stability after changes.",
    options: [
      {
        id: "bios.mem.xmp",
        name: "XMP / DOCP / EXPO profile",
        what: "Loads the advertised speed and timings from your RAM kit.",
        impact: "Often the single biggest free FPS + latency improvement if your RAM was stuck at a low JEDEC speed.",
        recommended: {
          high: "Enabled (Profile 1 / EXPO I) if stable.",
          mid: "Enabled if the kit and board are rated for it; otherwise Auto.",
          low: "Try enabling; if you see crashes or boot loops, revert to Auto/Disabled."
        },
        level: "Safe",
        notes: "Only enable profiles your kit and motherboard officially support. If the PC fails to boot, clear CMOS to revert."
      },
      {
        id: "bios.mem.gear_mode",
        name: "Memory Gear Mode (Intel)",
        what: "On Intel DDR4/DDR5 platforms, Gear 1 runs memory and memory controller in sync; Gear 2 runs the controller slower for higher clocks.",
        impact: "Gear 1 usually has slightly better latency at moderate speeds; Gear 2 allows higher raw frequency but with a small latency cost.",
        recommended: {
          high: "Gear 1 up to ~3600 MT/s DDR4 or ~6000 MT/s DDR5 if stable; otherwise Auto.",
          mid: "Auto. Only force Gear 1 if you understand memory tuning and can test thoroughly.",
          low: "Auto. Do not force specific gear modes on older or OEM boards."
        },
        level: "Aggressive",
        notes: "Changing gear mode is an advanced tweak. If the system becomes unstable, set it back to Auto or the factory default."
      },
      {
        id: "bios.mem.cmd_rate",
        name: "Command Rate (1T vs 2T)",
        what: "Controls how many clock cycles commands wait before being issued to RAM.",
        impact: "1T can shave a bit of latency and help minimum FPS, but may be unstable on some kits; 2T is more forgiving.",
        recommended: {
          high: "1T if your memory is fully stable in stress tests; otherwise 2T.",
          mid: "Auto or 2T for safety. Only try 1T if you run stability tests.",
          low: "Auto (often defaults to 2T). Prioritize stability over tiny latency gains."
        },
        level: "Aggressive",
        notes: "If you see memory errors or random crashes after switching to 1T, revert to 2T or Auto."
      },
      {
        id: "bios.mem.fast_boot",
        name: "Memory Fast Boot",
        what: "Skips some memory training on boot when settings are unchanged.",
        impact: "Faster boot times; can slightly reduce how often marginal RAM configs retrain.",
        recommended: {
          high: "Enabled once your memory is proven stable.",
          mid: "Enabled for faster boots after confirming stability.",
          low: "Auto or Disabled while troubleshooting RAM issues; Enabled only when fully stable."
        },
        level: "Safe",
        notes: "If you are actively tuning RAM, disable Fast Boot until you settle on stable settings."
      }
    ]
  },
  cpu: {
    key: "cpu",
    label: "CPU frequency, boost, and C-states",
    summary: "CPU power-saving and boost behavior have a direct effect on input latency, frame-time consistency, and thermals.",
    options: [
      {
        id: "bios.cpu.speedstep",
        name: "Intel SpeedStep / AMD Cool'n'Quiet",
        what: "Lets the CPU drop clocks and voltage at idle.",
        impact: "Lower idle power and thermals; very small latency impact on modern CPUs.",
        recommended: {
          high: "Enabled. Modern CPUs ramp clocks fast enough that this rarely hurts latency.",
          mid: "Enabled (default).",
          low: "Enabled for lower noise and power."
        },
        level: "Safe",
        notes: "Disabling all power saving can increase heat and fan noise for almost no real benefit in most games."
      },
      {
        id: "bios.cpu.speedshift",
        name: "Intel Speed Shift / CPPC (RYZEN)",
        what: "Gives the CPU more direct control over its own voltage/frequency scaling.",
        impact: "Faster boost response, which is good for bursty game workloads.",
        recommended: {
          high: "Enabled.",
          mid: "Enabled.",
          low: "Enabled (default on most modern systems)."
        },
        level: "Safe",
        notes: "Generally recommended for snappy boost behavior; keep it enabled unless a vendor specifically says otherwise."
      },
      {
        id: "bios.cpu.turbo",
        name: "Turbo Boost / Precision Boost",
        what: "Allows CPU cores to boost above base clock within power/thermal limits.",
        impact: "Higher single‑thread FPS and better frame times at the cost of more heat and power.",
        recommended: {
          high: "Enabled with default power limits or a mild raise if cooling is strong.",
          mid: "Enabled. Avoid extreme power limit increases.",
          low: "Enabled if cooling is adequate; otherwise leave limits at stock or slightly reduced."
        },
        level: "Safe",
        notes: "Raising power limits too far is an advanced overclock; keep thermals under control."
      },
      {
        id: "bios.cpu.cstates",
        name: "CPU C-States (C1E / C3 / C6 / C7)",
        what: "Deep sleep states that cut power when cores are idle.",
        impact: "Disabling deeper C-states can reduce latency spikes at the cost of higher idle power and heat.",
        recommended: {
          high: "Leave C1/C3 enabled but consider disabling the deepest C-states if you chase absolute lowest latency and have strong cooling.",
          mid: "Auto. Let the motherboard manage C-states.",
          low: "Auto. Prioritize lower power draw and noise."
        },
        level: "Aggressive",
        notes: "Full C-state disable is an extreme tweak. Monitor temperatures and power draw if you experiment here."
      },
      {
        id: "bios.cpu.power_limits",
        name: "CPU power limits (PL1/PL2 / PPT / TDC / EDC)",
        what: "Define how much sustained and short‑term power the CPU is allowed to draw.",
        impact: "Higher limits can improve boost clocks and FPS, but also raise temperatures and VRM stress.",
        recommended: {
          high: "Use manufacturer default or a small bump (5–15%) only if cooling and VRMs are high quality.",
          mid: "Keep at Auto/Default for best balance.",
          low: "Auto/Default. Do not raise limits on OEM prebuilts or weak coolers."
        },
        level: "Aggressive",
        notes: "Treat large power limit increases like overclocking. Watch CPU and VRM temps under sustained load."
      }
    ]
  },
  pcie: {
    key: "pcie",
    label: "PCIe, GPU, and latency-related links",
    summary: "GPU and PCIe configuration influence both bandwidth and latency. Focus on stable Gen settings and sensible power savings.",
    options: [
      {
        id: "bios.pcie.rebar",
        name: "Resizable BAR / Smart Access Memory",
        what: "Lets the CPU access the full GPU VRAM address space instead of small windows.",
        impact: "Small but real FPS and frame‑time gains in many modern titles on supported platforms.",
        recommended: {
          high: "Enabled along with Above 4G Decoding if your CPU, board, and GPU support it.",
          mid: "Enabled on modern platforms; leave Disabled if you see instability or black screens.",
          low: "Enabled only if the vendor explicitly supports it; otherwise leave Disabled."
        },
        level: "Safe",
        notes: "Requires compatible CPU, motherboard, and GPU. Update BIOS and GPU drivers when enabling."
      },
      {
        id: "bios.pcie.gen",
        name: "PCIe link speed (Gen 3 / Gen 4 / Auto)",
        what: "Controls the maximum PCIe generation for GPU and other slots.",
        impact: "Gen 4 offers more bandwidth; forcing Gen 3 can sometimes improve stability on borderline setups.",
        recommended: {
          high: "Auto or Gen 4 for GPUs that support it and are fully stable.",
          mid: "Auto. Only drop to Gen 3 if you have signal stability issues.",
          low: "Auto or Gen 3 for older cards and boards to reduce link training issues."
        },
        level: "Safe",
        notes: "If you experience random black screens or link errors, try forcing Gen 3 for the GPU slot."
      },
      {
        id: "bios.pcie.igpu",
        name: "Integrated GPU (iGPU)",
        what: "On CPUs with integrated graphics, this toggles whether the iGPU stays enabled.",
        impact: "Disabling iGPU can simplify GPU routing and free some shared memory; keeping it on enables QuickSync / iGPU outputs.",
        recommended: {
          high: "Disabled on desktop rigs using a discrete GPU only, unless you need iGPU features.",
          mid: "Disabled if you never use motherboard display outputs; otherwise Auto.",
          low: "Auto. On laptops, leave it enabled; switching it off can break power management."
        },
        level: "Aggressive",
        notes: "Never disable the only GPU in the system. On laptops, keep hybrid/Optimus defaults unless you know exactly what you are doing."
      },
      {
        id: "bios.pcie.aspm",
        name: "PCIe ASPM / power saving on PCIe",
        what: "Active State Power Management lets PCIe links downclock or enter low‑power states when idle.",
        impact: "Turning off aggressive ASPM can reduce rare latency spikes on some desktop systems.",
        recommended: {
          high: "Disabled or minimal ASPM on desktop gaming rigs.",
          mid: "Auto. Only relax ASPM if you suspect it of causing device dropouts.",
          low: "Auto or Enabled, especially on laptops where battery life matters."
        },
        level: "Aggressive",
        notes: "On mobile devices, disabling ASPM can noticeably hurt battery life."
      }
    ]
  },
  latency: {
    key: "latency",
    label: "Latency-focused toggles",
    summary: "A few firmware options primarily change latency behavior. Treat them as advanced tweaks and test carefully.",
    options: [
      {
        id: "bios.latency.spread_spectrum",
        name: "Spread Spectrum",
        what: "Slightly modulates clock frequencies to reduce electromagnetic interference (EMI).",
        impact: "Turning this off can marginally tighten timing behavior but may increase EMI.",
        recommended: {
          high: "Disabled on well‑shielded desktop systems focused on latency.",
          mid: "Auto/Default.",
          low: "Auto/Enabled, especially in electrically noisy environments."
        },
        level: "Aggressive",
        notes: "Usually safe to leave at default. Only disable if you are comfortable monitoring stability and compliance."
      },
      {
        id: "bios.latency.hpet",
        name: "HPET (High Precision Event Timer)",
        what: "Firmware timer exposed to the OS. Windows 10/11 typically handle timer selection automatically.",
        impact: "For most modern systems, leaving HPET at its default state in BIOS is safest. Over‑tweaking timers can backfire.",
        recommended: {
          high: "Leave at Default/Enabled in BIOS and manage any timer experiments from the OS only if you know exactly what you are doing.",
          mid: "Default/Enabled.",
          low: "Default/Enabled. Do not disable HPET without a clear reason."
        },
        level: "Safe",
        notes: "Conflicting online advice exists about HPET. The safest approach is to avoid forcing changes in firmware."
      },
      {
        id: "bios.latency.smt",
        name: "SMT / Hyper‑Threading",
        what: "Enables additional logical threads per physical core.",
        impact: "Disabling SMT can slightly improve worst‑case latency in a few esports titles, but often hurts performance in others.",
        recommended: {
          high: "Enabled for most users. Consider testing Disabled only for specific competitive games that benefit and where CPU cores are abundant.",
          mid: "Enabled.",
          low: "Enabled. Do not disable SMT/HT on low core‑count CPUs."
        },
        level: "Aggressive",
        notes: "Treat SMT toggling as game‑by‑game experimentation, not a universal optimization."
      }
    ]
  },
  misc: {
    key: "misc",
    label: "Virtualization, boot, and address space",
    summary: "A few firmware switches can free up resources or enable features like Resizable BAR.",
    options: [
      {
        id: "bios.misc.virtualization",
        name: "Virtualization (Intel VT-x / AMD SVM)",
        what: "Required for virtual machines and some anti‑cheat / security features.",
        impact: "Negligible latency impact; turning it off only makes sense if you never run VMs and want the simplest possible attack surface.",
        recommended: {
          high: "Enabled unless you are extremely focused on attack‑surface hardening.",
          mid: "Enabled (default on most boards).",
          low: "Enabled."
        },
        level: "Safe",
        notes: "Some anti‑cheats and security tools expect virtualization to be available; disabling it can cause compatibility issues."
      },
      {
        id: "bios.misc.csm",
        name: "Legacy / CSM boot",
        what: "Compatibility Support Module for legacy BIOS boot devices.",
        impact: "Disabling CSM and running pure UEFI is cleaner and required for some features (like Secure Boot and full Resizable BAR).",
        recommended: {
          high: "Disabled once Windows is installed in UEFI mode and all drives support it.",
          mid: "Disabled if your install is UEFI; otherwise keep Enabled until you can migrate.",
          low: "Auto/Enabled on very old hardware that cannot boot UEFI cleanly."
        },
        level: "Safe",
        notes: "Do not disable CSM if your OS is installed in legacy/MBR mode without planning a reinstall or conversion."
      },
      {
        id: "bios.misc.above4g",
        name: "Above 4G Decoding",
        what: "Allows the system to map more than 4 GB of PCIe device address space.",
        impact: "Required for Resizable BAR / Smart Access Memory and multi‑GPU setups; no direct latency penalty.",
        recommended: {
          high: "Enabled on modern platforms, especially with Resizable BAR.",
          mid: "Enabled if your GPU vendor recommends it; otherwise Auto.",
          low: "Enabled only on modern boards; very old hardware may prefer it Disabled."
        },
        level: "Safe",
        notes: "Usually paired with Resizable BAR. Turning it on is safe on modern hardware with up‑to‑date firmware."
      },
      {
        id: "bios.misc.fast_boot",
        name: "BIOS Fast Boot",
        what: "Skips some device initialization to shorten boot times.",
        impact: "Slightly faster boots; no direct effect on in‑game FPS.",
        recommended: {
          high: "Enabled once your system is fully stable and you rarely change hardware.",
          mid: "Enabled.",
          low: "Auto or Enabled. Disable temporarily when troubleshooting boot issues."
        },
        level: "Safe",
        notes: "If USB keyboards or devices sometimes fail to initialize on cold boot, try turning Fast Boot off."
      }
    ]
  }
};

function getHardwareTierLabelForBios(tierKey) {
  const t = String(tierKey || "mid").toLowerCase();
  if (t === "high" || t === "high-end" || t === "ultra") return "High-End";
  if (t === "low" || t === "low-end") return "Low-End";
  return "Mid-End";
}

function buildBiosPresetForTier(tierKey) {
  const t = String(tierKey || "mid").toLowerCase();
  if (t === "high" || t === "high-end" || t === "ultra") {
    return "Preset focus: latency-first competitive tuning. XMP/EXPO enabled, moderate boost power limits, C-states kept shallow, Resizable BAR on where supported, and ASPM/Spread Spectrum relaxed on desktop systems.";
  }
  if (t === "low" || t === "low-end") {
    return "Preset focus: stability-first with sensible performance. Use XMP/EXPO only if the kit is rated for it, keep most power saving features on, and avoid any extreme power-limit or deep C-state changes.";
  }
  return "Preset focus: balanced. Enable XMP/EXPO if supported, keep turbo features on, and leave most advanced options on Auto while you gain experience with BIOS tuning.";
}

function buildBiosChecklistForTier(tierKey) {
  const t = String(tierKey || "mid").toLowerCase();
  const label = getHardwareTierLabelForBios(t);
  const lines = [];
  lines.push("Falcon Optimizer – BIOS walkthrough (" + label + ")");
  lines.push("Mode: latency-first but stability-aware.");
  lines.push("");
  Object.values(BIOS_GUIDE).forEach((cat) => {
    lines.push("[" + cat.label + "]");
    (cat.options || []).forEach((opt) => {
      const rec = opt.recommended || {};
      let val = rec.mid || "Follow Auto/Default unless you are tuning.";
      if (t === "high" || t === "high-end" || t === "ultra") val = rec.high || val;
      else if (t === "low" || t === "low-end") val = rec.low || val;
      lines.push("- " + opt.name + ": " + val + " (" + (opt.level || "Safe") + ")");
    });
    lines.push("");
  });
  lines.push("Reminder: Falcon Optimizer does NOT change BIOS automatically. Apply these manually, one change at a time, and keep notes so you can revert anything that causes instability.");
  return lines.join("\n");
}

function buildBiosAdvancedGuidePanel(systemInfo) {
  const host = els.panel;
  if (!host) return;
  const hwTierRaw = (window.falcon && window.falcon.hardwareTier) || "mid";
  const hwTierKey = String(hwTierRaw || "mid").toLowerCase();
  const hwLabel = getHardwareTierLabelForBios(hwTierKey);
  const board = (systemInfo && (systemInfo.MotherboardLabel || systemInfo.MotherboardProduct || systemInfo.MotherboardManufacturer)) || "Unknown motherboard";

  const panel = document.createElement("div");
  panel.className = "panel";
  panel.innerHTML = `
    <div class="card-title">Deeper BIOS optimization guide</div>
    <div class="card-desc">Read-only checklist of advanced BIOS options that affect latency, FPS, stability, and thermals. Falcon Optimizer never changes BIOS directly – you apply these inside firmware yourself.</div>
    <div class="bios-advanced-summary">
      <p><strong>Detected tier:</strong> ${__eh(hwLabel)}.</p>
      <p><strong>Motherboard:</strong> ${__eh(board)}</p>
      <p>${__eh(buildBiosPresetForTier(hwTierKey))}</p>
    </div>
    <div class="bios-advanced-layout" style="display:flex;flex-wrap:wrap;gap:16px;margin-top:12px;align-items:flex-start;">
      <div style="flex:1 1 260px;min-width:260px;max-width:360px;">
        <div class="card">
          <div class="card-title">Sections</div>
          <div class="card-desc">Pick a BIOS area and review suggested values per tier.</div>
          <div class="field">
            <label class="field-label">Category</label>
            <select id="biosCategorySelect" class="input">
              ${Object.values(BIOS_GUIDE).map(cat => `<option value="${cat.key}">${__eh(cat.label)}</option>`).join("")}
            </select>
          </div>
          <div class="bios-cat-summary" id="biosCategorySummary"></div>
        </div>
      </div>
      <div style="flex:2 1 360px;min-width:300px;">
        <div class="card">
          <div class="card-title">Options and recommended values</div>
          <div class="card-desc">Latency-first defaults for High-End / Mid-End / Low-End rigs. Treat Aggressive items as expert-only tweaks.</div>
          <div class="bios-options" id="biosOptionsTable"></div>
        </div>
      </div>
    </div>
    <div class="panel">
      <div class="card-title">Printable BIOS checklist</div>
      <div class="card-desc">Copy this into a notes app or print it before entering BIOS. Check off each option as you go.</div>
      <textarea id="biosChecklistText" class="log" rows="10" readonly></textarea>
      <div class="card-actions">
        <button class="btn" id="biosChecklistCopy">Copy checklist</button>
      </div>
  `;

  host.appendChild(panel);

  function renderCategory(key) {
    const cat = BIOS_GUIDE[key] || BIOS_GUIDE.memory;
    const tableHost = panel.querySelector("#biosOptionsTable");
    const summaryHost = panel.querySelector("#biosCategorySummary");
    if (!tableHost || !cat) return;
    if (summaryHost) {
      summaryHost.innerHTML = `<p>${__eh(cat.summary || "")}</p>`;
    }
    const rows = (cat.options || []).map((opt) => {
      const levelLabel = opt.level || "Safe";
      const impact = opt.impact || "";
      const notes = opt.notes || "";
      const rec = opt.recommended || {};
      const rh = rec.high || "";
      const rm = rec.mid || "";
      const rl = rec.low || "";
      return `
        <div class="bios-option-row">
          <div class="bios-option-main">
            <div class="bios-option-name" title="${__eh(opt.what || impact || notes)}">${__eh(opt.name)}</div>
            <div class="bios-option-notes">${__eh(notes)}</div>
          </div>
          <div class="bios-option-impact">
            <div class="bios-option-impact-label">${__eh(impact)}</div>
            <div class="bios-option-tier">
              <strong>High-End:</strong> ${__eh(rh)}<br/>
              <strong>Mid-End:</strong> ${__eh(rm)}<br/>
              <strong>Low-End:</strong> ${__eh(rl)}
            </div>
            <div class="bios-option-risk"><span class="badge">${__eh(levelLabel)}</span></div>
          </div>
        </div>
      `;
    }).join("") || "<p>No options defined yet.</p>";
    tableHost.innerHTML = rows;
  }

  const select = panel.querySelector("#biosCategorySelect");
  if (select) {
    select.onchange = () => renderCategory(select.value);
    renderCategory(select.value);
  }

  const checklistEl = panel.querySelector("#biosChecklistText");
  if (checklistEl) {
    checklistEl.value = buildBiosChecklistForTier(hwTierKey);
  }
  const copyBtn = panel.querySelector("#biosChecklistCopy");
  if (copyBtn && navigator.clipboard) {
    copyBtn.onclick = async () => {
      try {
        await navigator.clipboard.writeText(checklistEl.value || "");
        showToast("BIOS checklist copied to clipboard.", "success");
      } catch (e) {
        showToast("Could not copy checklist. Select and copy manually.", "error");
      }
    };
  }
}


async function renderBiosHelper(){
  const allowed = await ensureAggressiveConsent("bios");
  if (!allowed) {
    els.panel.innerHTML = `
      <div class="panel">
        <div class="card-title">BIOS Optimizer</div>
        <div class="card-desc">Aggressive tweaks and BIOS guidance can affect stability and temperatures. Accept to continue.</div>
        <div style="margin-top:12px; display:flex; gap:10px; flex-wrap:wrap;">
          <button class="btn primary" id="biosAcceptContinue">Accept & Continue</button>
          <button class="btn" id="biosBackHome">Back</button>
        </div>
      </div>
    `;
    try{
      const b = document.getElementById('biosAcceptContinue');
      if (b) b.onclick = async () => { const ok = await ensureAggressiveConsent("bios"); if (ok) { aggressiveConsentAccepted = true; renderBiosHelper(); } };
      const back = document.getElementById('biosBackHome');
      if (back) back.onclick = () => { try{ setPage('home'); }catch(_e){} };
    }catch(_e){}
    return;
  }

  // Fetch best-effort firmware/system signals
  let sys = null;
  let bios = null;
  try { sys = await window.falcon.getSystemInfo(); } catch(_){}
  try { bios = await window.falcon.getBiosInfo(); } catch(_){}
  const info = (bios && bios.ok && bios.info) ? bios.info : null;

  const cpuName = (sys && sys.CPU) ? String(sys.CPU) : "Unknown CPU";
  const cpuIsAMD = /amd|ryzen|threadripper/i.test(cpuName);
  const cpuIsIntel = /intel|core|xeon/i.test(cpuName) && !cpuIsAMD;

  const moboLabel = info && info.motherboard && info.motherboard.label ? info.motherboard.label : (sys && sys.Motherboard ? sys.Motherboard : "Unknown");
  const biosVendor = info && info.bios && info.bios.vendor ? info.bios.vendor : "Unknown";
  const biosVer = info && info.bios && (info.bios.smbios || info.bios.version) ? (info.bios.smbios || info.bios.version) : "Unknown";

  const pickMoboBrand = (s) => {
    const t = String(s||'').toLowerCase();
    if (t.includes('asustek') || t.includes('asus')) return 'ASUS';
    if (t.includes('micro-star') || t.includes('msi')) return 'MSI';
    if (t.includes('gigabyte')) return 'Gigabyte';
    if (t.includes('asrock')) return 'ASRock';
    return 'Generic';
  };
  const moboBrand = pickMoboBrand(moboLabel);

  const yn = (v) => (v === true ? "Enabled" : v === false ? "Disabled" : "Unknown");
  const sb = info ? yn(info.secureBoot && info.secureBoot.enabled) : "Unknown";
  const tpm = info ? yn(info.tpm && info.tpm.enabled) : "Unknown";
  const virtFw = info ? yn(info.virtualization && info.virtualization.firmwareEnabled) : "Unknown";
  const rebar = info ? yn(info.resizableBar && info.resizableBar.enabled) : "Unknown";

  const routeHint = (brand, key) => {
    const map = {
      ASUS: {
        OC: "AI Tweaker / Extreme Tweaker",
        ADV: "Advanced",
        PCI: "Advanced → PCI Subsystem Settings",
        USB: "Advanced → USB Configuration",
        ONB: "Advanced → Onboard Devices",
        SEC: "Advanced → Trusted Computing / Boot",
        TOOL: "Tool"
      },
      MSI: {
        OC: "OC",
        ADV: "Settings → Advanced",
        PCI: "Settings → Advanced → PCIe/PCI Subsystem",
        USB: "Settings → Advanced → USB",
        ONB: "Settings → Advanced → Integrated Peripherals",
        SEC: "Settings → Security / Boot",
        TOOL: "Settings"
      },
      Gigabyte: {
        OC: "Tweaker",
        ADV: "Settings",
        PCI: "Settings → IO Ports / PCIe",
        USB: "Settings → IO Ports → USB",
        ONB: "Settings → IO Ports",
        SEC: "Settings → Trusted Computing / Boot",
        TOOL: "Settings"
      },
      ASRock: {
        OC: "OC Tweaker",
        ADV: "Advanced",
        PCI: "Advanced → Chipset Configuration",
        USB: "Advanced → USB Configuration",
        ONB: "Advanced → Onboard Devices",
        SEC: "Security / Boot",
        TOOL: "Tool"
      },
      Generic: {
        OC: "Overclocking / Tweaker",
        ADV: "Advanced",
        PCI: "PCIe / Chipset",
        USB: "USB",
        ONB: "Onboard Devices",
        SEC: "Security / Boot",
        TOOL: "Tools"
      }
    };
    const b = map[brand] || map.Generic;
    return b[key] || b.ADV;
  };

  // Load large BIOS catalog (if present) for expanded settings list
  let biosCatalog = null;
  try{
    const r = await fetch('data/bios/bios_catalog.json', { cache:'no-store' });
    if (r && r.ok) biosCatalog = await r.json();
  }catch(_){ biosCatalog = null; }

  const normalizeRisk = (r) => {
    const t = String(r||'Safe').toLowerCase();
    if (t.includes('extreme')) return 'Extreme';
    if (t.includes('danger')) return 'Danger';
    if (t.includes('warn')) return 'Warning';
    return 'Safe';
  };

  const isRelevantToSystem = (tags=[]) => {
    const t = (tags||[]).map(x=>String(x||'').toLowerCase());
    if (t.includes('intel') && !cpuIsIntel) return false;
    if (t.includes('amd') && !cpuIsAMD) return false;
    return true;
  };

  const resolveWhere = (whereKey) => routeHint(moboBrand, whereKey || 'ADV');
  const resolveKeyword = (kwObj) => {
    if (!kwObj) return '';
    return kwObj[moboBrand] || kwObj['Generic'] || '';
  };

  const getCatalogBlocks = (profileId, opts={}) => {
    const query = String(opts.query||'').trim().toLowerCase();
    const onlyRelevant = !!opts.onlyRelevant;
    const allowedRisks = new Set((opts.allowedRisks && opts.allowedRisks.length ? opts.allowedRisks : ['Safe','Warning','Danger','Extreme']).map(String));
    const blocks = [];
    if (!biosCatalog || !biosCatalog.sections) return blocks;

    for (const sec of biosCatalog.sections) {
      const items = [];
      for (const raw of (sec.items||[])) {
        const risk = normalizeRisk(raw.risk);
        if (!allowedRisks.has(risk)) continue;

        if (onlyRelevant && !isRelevantToSystem(raw.tags)) continue;

        const name = String(raw.name||'');
        const notes = String(raw.notes||'');
        const where = resolveWhere(raw.whereKey);
        const searchTerm = resolveKeyword(raw.keywords);
        const value = (raw.profiles && raw.profiles[profileId]) ? raw.profiles[profileId] : (raw.profiles && raw.profiles['balanced'] ? raw.profiles['balanced'] : 'See BIOS');

        const hay = (name + ' ' + notes + ' ' + where + ' ' + searchTerm + ' ' + (raw.tags||[]).join(' ')).toLowerCase();
        if (query && !hay.includes(query)) continue;

        items.push({
          name,
          value,
          risk,
          where,
          note: notes,
          searchTerm
        });
      }
      if (items.length) blocks.push({ group: `${sec.icon ? (sec.icon + ' ') : ''}${sec.label}`, items });
    }
    return blocks;
  };


  const mk = (group, items) => ({ group, items });

  // BIOS-only checklist recommendations (manual changes)
  const recsCompetitive = [];
  const recsBalanced = [];
  const recsExtreme = [];

  // Memory
  recsBalanced.push(mk("Memory (stability + performance)", [
    { name: cpuIsAMD ? "EXPO / DOCP (Profile 1)" : "XMP (Profile 1)", value: "Enabled (Profile 1)", risk:"Safe", where: routeHint(moboBrand, "OC"), note:"Use Profile 1 (usually most stable)." },
    { name: "DRAM Frequency", value: "Match XMP/EXPO rated speed", risk:"Safe", where: routeHint(moboBrand, "OC"), note:"Verify it actually applied." }
  ]));
  if (!cpuIsAMD) {
    recsCompetitive.push(mk("Memory latency (Intel)", [
      { name: "Gear Mode / MC DRAM Ratio", value: "DDR4: Gear 1  |  DDR5: Auto", risk:"Warning", where: routeHint(moboBrand, "OC"), note:"Gear 1 improves latency but may reduce max OC headroom." }
    ]));
  }

  // PCIe / GPU
  recsBalanced.push(mk("PCIe / GPU", [
    { name: "Above 4G Decoding", value: "Enabled", risk:"Safe", where: routeHint(moboBrand, "PCI"), note:"Required for Resizable BAR." },
    { name: "Resizable BAR", value: "Enabled (RTX 30+/RX 6000+)", risk:"Safe", where: routeHint(moboBrand, "PCI"), note:"Only helps on supported GPUs." },
    { name: "PCIe Power Saving (ASPM / Clock Gating)", value: "Disabled", risk:"Safe", where: routeHint(moboBrand, "PCI"), note:"Reduces latency spikes." }
  ]));

  // USB
  recsBalanced.push(mk("USB / Input", [
    { name: "XHCI Handoff", value: "Enabled", risk:"Safe", where: routeHint(moboBrand, "USB"), note:"Helps USB compatibility/latency." },
    { name: "Legacy USB Support", value: "Auto (or Disabled if stable)", risk:"Warning", where: routeHint(moboBrand, "USB"), note:"If a USB stick won’t show in BIOS, keep it Enabled/Auto." }
  ]));

  // Security / anti-cheat compatibility
  recsBalanced.push(mk("Security / Anti-cheat compatibility", [
    { name: "TPM (fTPM/PTT)", value: "Enabled", risk:"Warning", where: routeHint(moboBrand, "SEC"), note:"Some games (Valorant/Fortnite) require TPM/Secure Boot." },
    { name: "Secure Boot", value: "Enabled", risk:"Warning", where: routeHint(moboBrand, "SEC"), note:"Required by some anti-cheats; can break older OS installs." }
  ]));

  // CPU – Intel
  if (cpuIsIntel) {
    recsCompetitive.push(mk("CPU (Intel) – latency / boosting", [
      { name: "Multi-Core Enhancement", value: "Enabled (Remove All Limits)", risk:"Warning", where: routeHint(moboBrand, "OC"), note:"Raises power/heat; requires good cooling." },
      { name: "Adaptive Boost", value: "Disabled", risk:"Safe", where: routeHint(moboBrand, "OC"), note:"Usually not helpful for gaming latency." },
      { name: "Thermal Velocity Boost", value: "Disabled", risk:"Safe", where: routeHint(moboBrand, "OC"), note:"Optional; disable for consistency." }
    ]));

    recsCompetitive.push(mk("CPU Power Management (Intel)", [
      { name: "CPU C-States", value: "Disabled", risk:"Danger", where: routeHint(moboBrand, "ADV"), note:"Can raise temps/power draw significantly." },
      { name: "Thermal Monitor", value: "Enabled (recommended)", risk:"Danger", where: routeHint(moboBrand, "ADV"), note:"Disabling can risk overheating. Leave enabled unless you fully understand the risk." },
      { name: "Intel Speed Shift", value: "Disabled (test)", risk:"Warning", where: routeHint(moboBrand, "ADV"), note:"Can reduce latency on some systems, but can reduce efficiency." }
    ]));

    recsBalanced.push(mk("Virtualization (Intel)", [
      { name: "Intel Virtualization Technology / VT-d", value: "Enabled if you use Vanguard/FaceIT; otherwise optional", risk:"Warning", where: routeHint(moboBrand, "ADV"), note:"Some anti-cheats require it; disabling can improve attack surface but may not affect FPS." }
    ]));
  }

  // CPU – AMD
  if (cpuIsAMD) {
    recsCompetitive.push(mk("CPU (AMD) – PBO light tuning", [
      { name: "Precision Boost Overdrive (PBO)", value: "Advanced / Enhancement", risk:"Warning", where: routeHint(moboBrand, "OC"), note:"Light PBO can help FPS; watch temps." },
      { name: "CPU Boost Clock Override", value: "+200 (if stable)", risk:"Warning", where: routeHint(moboBrand, "OC"), note:"Do not use if unstable." }
    ]));
    recsCompetitive.push(mk("Latency (AMD)", [
      { name: "Global C-State Control", value: "Disabled", risk:"Danger", where: routeHint(moboBrand, "ADV"), note:"Raises idle power/temps; can improve consistency." },
      { name: "SVM Mode (virtualization)", value: "Enable if Vanguard/FaceIT; otherwise optional", risk:"Warning", where: routeHint(moboBrand, "ADV"), note:"Anti-cheat compatibility may require virtualization." }
    ]));
  }

  // Onboard devices
  recsBalanced.push(mk("Onboard devices (disable what you don’t use)", [
    { name: "Bluetooth / Wi‑Fi", value: "Disable if unused", risk:"Safe", where: routeHint(moboBrand, "ONB"), note:"Reduces background drivers/latency." },
    { name: "RGB / Extra controllers", value: "Disable if unused", risk:"Safe", where: routeHint(moboBrand, "ONB"), note:"Avoid vendor bloat." },
    { name: "Extra SATA/USB controllers", value: "Disable if unused", risk:"Warning", where: routeHint(moboBrand, "ONB"), note:"Only if you’re sure nothing is connected." }
  ]));

  // Extreme add-ons (for users who accept instability/temps)
  recsExtreme.push(mk("Extreme (test-only)", [
    { name: "Spread Spectrum", value: "Disabled", risk:"Warning", where: routeHint(moboBrand, "OC"), note:"Can reduce jitter; sometimes enabling helps in noisy EMI environments." },
    { name: "Efficiency cores (Intel Win10)", value: "Disable (Win10 only; test)", risk:"Danger", where: routeHint(moboBrand, "ADV"), note:"Can break scheduling for some workloads; Win11 handles E-cores better." }
  ]));

  const profiles = [
    { id:"balanced", label:"Balanced Gaming (recommended)", blocks: recsBalanced },
    { id:"competitive", label:"Competitive (low latency)", blocks: recsBalanced.concat(recsCompetitive) },
    { id:"extreme", label:"Extreme (risk/temps)", blocks: recsBalanced.concat(recsCompetitive).concat(recsExtreme) }
  ];

  const buildChecklistText = (profileId) => {
    const p = profiles.find(x=>x.id===profileId) || profiles[0];
    const lines = [];
    const useCatalog = !!(biosCatalog && biosCatalog.sections && biosCatalog.sections.length);
    const blocksForChecklist = useCatalog ? getCatalogBlocks(profileId, { query:"", onlyRelevant:false, allowedRisks:["Safe","Warning","Danger","Extreme"] }) : p.blocks;
    lines.push("Falcon BIOS Optimizer Checklist");
    lines.push("Profile: " + p.label);
    lines.push("CPU: " + cpuName);
    lines.push("Motherboard: " + moboLabel);
    lines.push("BIOS: " + biosVendor + " " + biosVer);
    lines.push("");
    lines.push("Detected status (best-effort):");
    lines.push("- Secure Boot: " + sb);
    lines.push("- TPM: " + tpm);
    lines.push("- Virtualization (Firmware): " + virtFw);
    lines.push("- Resizable BAR: " + rebar);
    lines.push("");
    for (const b of blocksForChecklist) {
      lines.push("[" + b.group + "]");
      for (const it of b.items) {
        lines.push("- " + it.name + " => " + it.value + "  (" + it.risk + ")");
        lines.push("  Where: " + (it.where || "BIOS") + (it.note ? (" | Note: " + it.note) : ""));
      }
      lines.push("");
    }
    lines.push("Reminder: Most BIOS settings must be changed manually inside UEFI. Falcon can apply only OS-side equivalents.");
    return lines.join("\n");
  };

  const renderBlocksHtml = (profileId, opts={}) => {
    const useCatalog = !!(biosCatalog && biosCatalog.sections && biosCatalog.sections.length);
    const blocks = useCatalog ? getCatalogBlocks(profileId, opts) : ((profiles.find(x=>x.id===profileId) || profiles[0]).blocks);

    const makeItems = (b) => (b.items||[]).map(it=>`
        <div class="bios-item">
          <div class="bios-item-main">
            <div class="bios-item-title">${escapeHtml(it.name)}</div>
            <div class="bios-item-sub">
              <span class="badge ${String(it.risk||'Safe').toLowerCase()}">${escapeHtml(it.risk||'Safe')}</span>
              <span class="bios-item-where">${escapeHtml(it.where||'BIOS')}</span>
              ${it.searchTerm ? `<span class="bios-item-where">• Search: ${escapeHtml(it.searchTerm)}</span>` : ``}
            </div>
          </div>
          <div class="bios-item-value">${escapeHtml(it.value)}</div>
          ${it.note ? `<div class="bios-item-note">${escapeHtml(it.note)}</div>` : ``}
        </div>
      `).join('');

    return blocks.map((b,i)=>{
      const openAttr = (opts && opts.expandAll) ? ' open' : '';
      return `
        <details class="card bios-block"${openAttr} data-biosblock="${i}">
          <summary class="bios-block-summary">
            <div class="bios-block-title">${escapeHtml(b.group||'Recommendations')}</div>
            <div class="bios-block-meta">${(b.items||[]).length} items</div>
          </summary>
          <div class="bios-list">${makeItems(b)}</div>
        </details>
      `;
    }).join('');
  };

  els.panel.innerHTML = `
    <div class="panel">
      <div class="bios-top">
        <div class="card">
          <div class="card-title">Firmware summary</div>
          <div class="card-desc">Detected from Windows (best-effort). BIOS settings themselves are mostly manual.</div>
          <div class="bios-kv"><span>Motherboard</span><strong id="biosMobo">${escapeHtml(moboLabel)}</strong></div>
          <div class="bios-kv"><span>BIOS</span><strong id="biosBios">${escapeHtml(biosVendor)} ${escapeHtml(biosVer)}</strong></div>
          <div class="bios-kv"><span>Secure Boot</span><strong>${escapeHtml(sb)}</strong></div>
          <div class="bios-kv"><span>TPM</span><strong>${escapeHtml(tpm)}</strong></div>
          <div class="bios-kv"><span>Virt (Firmware)</span><strong>${escapeHtml(virtFw)}</strong></div>
          <div class="bios-kv"><span>Resizable BAR</span><strong>${escapeHtml(rebar)}</strong></div>
          <div class="bios-actions">
            <button class="btn" id="btnRebootUEFI">Reboot to UEFI</button>
            <button class="btn" id="btnSaveChecklist">Save checklist</button>
            <button class="btn secondary" id="btnCopyChecklist">Copy checklist</button>
          </div>
          <div class="small-note">Tip: After applying BIOS changes, save a BIOS profile so you can restore quickly after CMOS reset.</div>
        </div>

        <div class="card">
          <div class="card-title">Profile</div>
          <div class="card-desc">Falcon generates a BIOS checklist + can apply OS-side equivalents that are safe to automate.</div>
          <select id="biosProfile" class="select">
            ${profiles.map(p=>`<option value="${p.id}">${escapeHtml(p.label)}</option>`).join('')}
          </select>

          <div class="divider"></div>

          <div class="card-title">OS-side equivalents</div>
          <div class="card-desc">These are Windows changes that mirror common BIOS latency goals. BIOS settings still must be changed manually.</div>
          <div class="bios-actions">
            <button class="btn" id="btnApplySafe">Apply (Safe)</button>
            <button class="btn" id="btnApplyCompetitive">Apply (Competitive)</button>
            <button class="btn danger" id="btnApplyExtreme">Apply (Extreme)</button>
          </div>
          <div id="biosApplyStatus" class="small-note"></div>
          <pre id="biosApplyLog" class="log-box" style="display:none;"></pre>
        </div>
      </div>

      
      <div class="card bios-toolbar">
        <div class="bios-toolbar-row">
          <input id="biosSearch" class="input" placeholder="Search BIOS settings (e.g. C-States, ASPM, XMP, Resizable BAR)" />
          <button class="btn secondary" id="btnExpandAll">Expand all</button>
          <button class="btn secondary" id="btnCollapseAll">Collapse all</button>
        </div>
        <div class="bios-toolbar-row">
          <label class="check"><input type="checkbox" id="biosOnlyRelevant" checked /> Show only relevant (Intel/AMD)</label>
          <span class="spacer"></span>
          <label class="check"><input type="checkbox" class="biosRisk" value="Safe" checked /> Safe</label>
          <label class="check"><input type="checkbox" class="biosRisk" value="Warning" checked /> Warning</label>
          <label class="check"><input type="checkbox" class="biosRisk" value="Danger" checked /> Danger</label>
          <label class="check"><input type="checkbox" class="biosRisk" value="Extreme" checked /> Extreme</label>
        </div>
      </div>

      <div id="biosBlocks"></div>


      <div class="card">
        <div class="card-title">Generated checklist</div>
        <div class="card-desc">Copy this into notes before rebooting into BIOS.</div>
        <textarea id="biosChecklist" class="textarea" rows="14" spellcheck="false"></textarea>
      </div>
    </div>
  `;

  const elProfile = document.getElementById('biosProfile');
  const elBlocks = document.getElementById('biosBlocks');
  const elChecklist = document.getElementById('biosChecklist');
  const elSearch = document.getElementById('biosSearch');
  const elOnlyRelevant = document.getElementById('biosOnlyRelevant');

  const getAllowedRisks = () => Array.from(document.querySelectorAll('.biosRisk'))
    .filter(x=>x.checked)
    .map(x=>x.value);

  const getOpts = () => ({
    query: elSearch ? elSearch.value : '',
    onlyRelevant: elOnlyRelevant ? elOnlyRelevant.checked : false,
    allowedRisks: getAllowedRisks()
  });

  const update = () => {
    const pid = elProfile.value || 'balanced';
    elBlocks.innerHTML = renderBlocksHtml(pid, getOpts());
    elChecklist.value = buildChecklistText(pid);
  };
  update();

  const debounce = (fn, ms=120) => {
    let t = null;
    return (...args) => {
      clearTimeout(t);
      t = setTimeout(()=>fn(...args), ms);
    };
  };

  elProfile.onchange = update;
  if (elSearch) elSearch.oninput = debounce(update, 120);
  if (elOnlyRelevant) elOnlyRelevant.onchange = update;
  document.querySelectorAll('.biosRisk').forEach(ch=> ch.onchange = update);

  const setAllDetailsOpen = (open) => {
    document.querySelectorAll('details.bios-block').forEach(d=>{ d.open = !!open; });
  };

  const btnExpandAll = document.getElementById('btnExpandAll');
  const btnCollapseAll = document.getElementById('btnCollapseAll');
  if (btnExpandAll) btnExpandAll.onclick = () => { setAllDetailsOpen(true); };
  if (btnCollapseAll) btnCollapseAll.onclick = () => { setAllDetailsOpen(false); };

  // Reboot to UEFI firmware setup
  document.getElementById('btnRebootUEFI').onclick = async () => {
    await showConfirmModal({
      title: "Reboot to UEFI",
      body: "This will reboot immediately into BIOS/UEFI setup (if supported by your system). Save your work first.",
      okText: "Reboot",
      cancelText: "Cancel"
    }).then(async (ok)=>{
      if(!ok) return;
      try{
        await window.falcon.runSteps({ steps:[{ type:'cmd', shell:'cmd', command:'shutdown /r /fw /t 0' }], meta:{ label:'Reboot to UEFI' } });
      }catch(e){
        await showAlertModal("Failed to reboot to UEFI: " + (e && e.message ? e.message : String(e)));
      }
    });
  };

  // Copy checklist
  document.getElementById('btnCopyChecklist').onclick = async () => {
    try{
      await navigator.clipboard.writeText(elChecklist.value || "");
      await showToast("Checklist copied.");
    }catch(_){
      // fallback
      elChecklist.select();
      document.execCommand('copy');
      await showToast("Checklist copied.");
    }
  };

  // Save checklist
  document.getElementById('btnSaveChecklist').onclick = async () => {
    try{
      const res = await window.falcon.saveTextFile("bios_checklist.txt", elChecklist.value || "");
      if (res && res.ok) await showToast("Saved: " + res.path);
      else await showAlertModal("Failed to save checklist.");
    }catch(e){
      await showAlertModal("Failed to save checklist: " + (e && e.message ? e.message : String(e)));
    }
  };

  const applyStatus = document.getElementById('biosApplyStatus');
  const applyLog = document.getElementById('biosApplyLog');

  const runPack = async (pack) => {
    applyLog.style.display = 'block';
    applyLog.textContent = '';
    applyStatus.textContent = 'Running…';
    try{
      const res = await window.falcon.runSteps({ steps: pack, meta:{ label:'BIOS Optimizer OS Pack' } });
      applyLog.textContent = (res && res.stdout ? res.stdout : '') + (res && res.stderr ? ('\n' + res.stderr) : '');
      applyStatus.textContent = (res && res.ok) ? 'Done.' : 'Failed (see log).';
    }catch(e){
      applyLog.textContent = String(e && e.message ? e.message : e);
      applyStatus.textContent = 'Failed (see log).';
    }
  };

  // Packs (OS-only)
  const packSafe = [
    { type:'cmd', shell:'cmd', command:'powercfg /setactive SCHEME_MIN' }
  ];

  const packCompetitive = [
    { type:'cmd', shell:'cmd', command:'powercfg /setactive SCHEME_MIN' },
    // disable core parking via registry (best-effort)
    { type:'powershell', command:`powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100; powercfg -setactive SCHEME_CURRENT` }
  ];

  const packExtreme = [
    { type:'cmd', shell:'cmd', command:'powercfg /setactive SCHEME_MIN' },
    { type:'powershell', command:`powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100; powercfg -setactive SCHEME_CURRENT` },
    // bcdedit tweaks (can impact stability/clock sources)
    { type:'cmd', shell:'cmd', command:'bcdedit /set disabledynamictick yes' }
  ];

  document.getElementById('btnApplySafe').onclick = async () => runPack(packSafe);
  document.getElementById('btnApplyCompetitive').onclick = async () => runPack(packCompetitive);

  document.getElementById('btnApplyExtreme').onclick = async () => {
    const ok = await showConfirmModal({
      title: "Extreme OS Pack",
      body: "This applies aggressive boot/power changes that may increase heat, reduce battery life, or cause instability. Only continue if you know how to revert boot settings (bcdedit).",
      okText: "Apply Extreme",
      cancelText: "Cancel"
    });
    if (!ok) return;
    await runPack(packExtreme);
  };
}






async function renderPerformanceLibrary(){
  const modeKey = 'falcon_perf_mode';
  const mode = (localStorage.getItem(modeKey) || 'falcon').toLowerCase();

  function modeBtn(id,label,desc){
    const active = (mode===id) ? 'btn-red' : 'btn-ghost';
    return `<button class="btn ${active}" data-pl-mode="${id}" style="min-width:140px;">
      <div style="font-weight:700; font-size:13px;">${label}</div>
      <div class="muted" style="font-size:11px; margin-top:2px;">${desc}</div>
    </button>`;
  }

  els.panel.innerHTML = `
    <div class="panel" style="margin-top:14px;">
      <div class="card-title">Performance Library</div>
      <div class="card-desc">Apply comprehensive actions with a selectable tuning goal. Default is update-safe and reversible where possible.</div>

      <div style="margin-top:12px;">
        <div class="muted" style="font-size:12px; margin-bottom:8px;">Optimization Mode</div>
        <div id="plModeRow" style="display:flex; gap:10px; flex-wrap:wrap;">
          ${modeBtn('falcon','Falcon','Your tuned defaults')}
          ${modeBtn('fps','FPS-Max','Max performance bias')}
          ${modeBtn('latency','Latency-Max','Lower input delay bias')}
          ${modeBtn('balanced','Balanced','Safe middle ground')}
          ${modeBtn('extreme','Extreme','Highest risk / optional')}
        </div>
      </div>

      <div style="display:flex; gap:10px; flex-wrap:wrap; margin-top:14px;">
        <button id="plApplySafe" class="btn btn-red">Apply All (Update-safe)</button>
        <button id="plApplyAgg" class="btn btn-ghost">Apply All (Aggressive)</button>
        <button id="plRestoreUpdates" class="btn btn-ghost">Restore Updates & Drivers</button>
      
      <div style="margin-top:10px; display:flex; align-items:center; gap:8px;">
        <input id="plAllowCritical" type="checkbox" />
        <label for="plAllowCritical" class="muted" style="font-size:12px;">Allow update/driver-critical service disables (high risk; can break GPU/Windows updates)</label>
      </div>

      <div class="divider" style="margin:14px 0;"></div>

      <div class="muted" style="font-size:12px; margin-bottom:8px;">Apply by category</div>
      <div style="display:flex; gap:10px; flex-wrap:wrap;">
        <button class="btn btn-ghost plCat" data-scope="gpu">GPU</button>
        <button class="btn btn-ghost plCat" data-scope="scheduler">Scheduler</button>
        <button class="btn btn-ghost plCat" data-scope="services">Services</button>
        <button class="btn btn-ghost plCat" data-scope="power">Power</button>
        <button class="btn btn-ghost plCat" data-scope="boot">Boot & Timer</button>
        <button class="btn btn-ghost plCat" data-scope="network">Network</button>
        <button class="btn btn-ghost plCat" data-scope="ui">UI</button>
        <button class="btn btn-ghost plCat" data-scope="cleanup">Cleanup</button>
      </div>

      <div id="plStatus" class="muted" style="margin-top:14px;"></div>
      <pre id="plLog" class="logbox" style="margin-top:10px; display:none;"></pre>
    </div>
  `;

  // mode buttons
  const row = document.getElementById('plModeRow');
  if (row) {
    row.querySelectorAll('[data-pl-mode]').forEach(btn=>{
      btn.onclick = ()=>{
        const id = String(btn.getAttribute('data-pl-mode')||'falcon').toLowerCase();
        localStorage.setItem(modeKey, id);
        refresh(false);
      };
    });
  }

  async function runPack(opts){
    const st = document.getElementById('plStatus');
    const log = document.getElementById('plLog');
    if (st) st.textContent = 'Running…';
    if (log){ log.style.display='block'; log.textContent=''; }

    try{
      const res = await window.falcon.performanceLibraryApply(opts);
      if (log) {
        log.textContent = (res.stdout || '') + (res.stderr ? ('\n' + res.stderr) : '');
      }
      if (st) st.textContent = res.ok ? ('Done. Log: ' + (res.logFile || '')) : ('Failed. See log: ' + (res.logFile || ''));
    }catch(e){
      if (log){ log.style.display='block'; log.textContent = String(e && e.message ? e.message : e); }
      if (st) st.textContent = 'Failed.';
    }
  }

  const allowKey = 'falcon_pl_allow_critical';
  const m = (localStorage.getItem(modeKey) || 'falcon').toLowerCase();
  const allowCritical = (localStorage.getItem(allowKey) === '1');
  const cb = document.getElementById('plAllowCritical');
  if (cb){ cb.checked = allowCritical; cb.onchange = ()=> localStorage.setItem(allowKey, cb.checked ? '1':'0'); }

  const safeBtn = document.getElementById('plApplySafe');
  const aggBtn = document.getElementById('plApplyAgg');
  const rstBtn = document.getElementById('plRestoreUpdates');
  if (safeBtn) safeBtn.onclick = ()=> runPack({ scope:'all', updateSafe:true, mode:m, allowCritical:false });
  if (aggBtn)  aggBtn.onclick  = ()=> runPack({ scope:'all', updateSafe:false, mode:m, allowCritical:(document.getElementById('plAllowCritical')?.checked||false) });
  if (rstBtn)  rstBtn.onclick  = ()=> runPack({ scope:'restore_updates', updateSafe:true, mode:m, allowCritical:true });

  document.querySelectorAll('.plCat').forEach(b=>{
    b.onclick = ()=>{
      const scope = String(b.getAttribute('data-scope')||'all');
      runPack({ scope, updateSafe:true, mode:m, allowCritical:false });
    };
  });
}


function renderHome(){
  els.panel.innerHTML = `

    <div class="panel" style="margin-top:14px;">
      <div class="card-title">Profiles</div>
      <div class="card-desc">Apply curated sets. Excluded items and Critical actions require extra confirmation.</div>
      <div id="profileButtons" style="display:flex; gap:10px; flex-wrap:wrap; margin-top:10px;"></div>
      <div id="batchProgressWrap" style="display:none; margin-top:12px;">
        <div class="progress-row"><div id="batchProgressLabel" class="muted">Running…</div><div id="batchProgressPct" class="muted">0%</div></div>
        
          </div>


        
        <div class="panel" style="margin-top:14px;">
          <div class="card-title-row">
            <div class="card-title">Security stack</div>
            <button class="btn inline small" id="homeSecurityRefreshBtn">Refresh</button>
          </div>
          <div class="card-desc">Reversible Defender controls + live health check. Protected services (like Windows Installer) are blocked from destructive packs.</div>

          <div class="grid" style="grid-template-columns: repeat(2, minmax(0,1fr)); gap:10px; margin-top:10px;">
            <div class="panel" style="margin:0; padding:12px;">
              <div class="muted" style="font-size:12px;">Tamper Protection</div>
              <div id="secTamper" style="font-size:14px; margin-top:4px;">Detecting…</div>
            </div>
            <div class="panel" style="margin:0; padding:12px;">
              <div class="muted" style="font-size:12px;">Windows Installer (msiserver)</div>
              <div id="secMsiserver" style="font-size:14px; margin-top:4px;">Detecting…</div>
            </div>
            <div class="panel" style="margin:0; padding:12px;">
              <div class="muted" style="font-size:12px;">Defender (WinDefend)</div>
              <div id="secWinDefend" style="font-size:14px; margin-top:4px;">Detecting…</div>
            </div>
            <div class="panel" style="margin:0; padding:12px;">
              <div class="muted" style="font-size:12px;">Security UI (SecurityHealthService / wscsvc)</div>
              <div id="secSecUI" style="font-size:14px; margin-top:4px;">Detecting…</div>
            </div>
          </div>

          <div class="row" style="gap:10px; flex-wrap:wrap; margin-top:12px;">
            <button class="btn" id="homeDefenderOnBtn">Defender: ON</button>
            <button class="btn secondary" id="homeDefenderOffBtn">Defender: OFF (Safe)</button>
            <button class="btn danger" id="homeDefenderAdvOffBtn">Permanent Disable (Advanced)</button>
            <button class="btn" id="homeMsiRepairBtn">Fix Windows Installer</button>
          </div>

          <div class="hint">If Defender OFF fails: turn off Tamper Protection in Windows Security, reboot, then try again. This stack never uses Start=4 for SecurityHealthService.</div>
        </div>

<div class="panel panel-topo" style="margin-top:14px;">
      <div class="card-title-row"><div class="card-title">PC overview</div><button class="btn inline small" id="homeSystemInfoBtn">System Info</button></div>
      <div class="card-desc">Live snapshot of your hardware plus deep, estimated esports telemetry.</div>

      <div class="pc-overview-layout">
        <div class="pc-overview-left">
          <div class="pc-specs-row">
            <div class="pc-spec">
              <div class="spec-label">CPU</div>
              <div class="spec-value" id="specCPU">Detecting…</div>
            </div>
            <div class="pc-spec">
              <div class="spec-label">GPU</div>
              <div class="spec-value" id="specGPU">Detecting…</div>
            </div>
            <div class="pc-spec">
              <div class="spec-label">RAM</div>
              <div class="spec-value" id="specRAM">Detecting…</div>
            </div>
            <div class="pc-spec">
              <div class="spec-label">GPU VRAM</div>
              <div class="spec-value" id="specVRAM">Detecting…</div>
            </div>
            <div class="pc-spec">
              <div class="spec-label">OS</div>
              <div class="spec-value" id="specOS">Detecting…</div>
            </div>
            <div class="pc-spec">
              <div class="spec-label">Motherboard</div>
              <div class="spec-value" id="specMotherboard">Detecting…</div>
            </div>
          </div>

          <div class="gpu-vendor-row">
            <div class="gpu-vendor-label">GPU vendor mode</div>
            <div class="gpu-vendor-chips">
              <button class="chip chip-small" data-gpu-vendor="auto">Auto</button>
              <button class="chip chip-small" data-gpu-vendor="nvidia">NVIDIA</button>
              <button class="chip chip-small" data-gpu-vendor="amd">AMD</button>
              <button class="chip chip-small" data-gpu-vendor="intel">Intel</button>
            </div>
          </div>

          <div class="spec-compare" id="specCompare">
            <div class="spec-compare-title">Hardware vs common gaming builds</div>
            <div class="spec-compare-row">
              <div class="spec-compare-label">CPU</div>
              <div class="spec-compare-bar">
                <div class="spec-compare-bar-fill" id="specCompareCpuFill"></div>
              </div>
            </div>
            <div class="spec-compare-row">
              <div class="spec-compare-label">GPU</div>
              <div class="spec-compare-bar">
                <div class="spec-compare-bar-fill" id="specCompareGpuFill"></div>
              </div>
            </div>
            <div class="spec-compare-row">
              <div class="spec-compare-label">RAM</div>
              <div class="spec-compare-bar">
                <div class="spec-compare-bar-fill" id="specCompareRamFill"></div>
              </div>
            </div>
            <div class="spec-compare-summary" id="specCompareSummary"></div>
          </div>

          <div class="fps-estimates" id="fpsEstimates">
            <div class="fps-row fps-row-header">
              <div class="fps-game">Game</div>
              <div class="fps-fps">Est. FPS (1080p low)</div>
            </div>
          </div>
          <div class="hint" id="fpsHint">Estimates assume 1080p, low settings, and no background load. Real performance will vary.</div>
        </div>

        <div class="pc-overview-right">
          <div class="pc-topology-label">Component topology</div>
          <div class="pc-topology-sub">Estimated load, headroom, and thermal pressure for each major part.</div>
          <div class="pc-topology-grid">
            <div class="pc-topo-card" data-part="cpu">
              <div class="pc-topo-header">
                <div class="pc-topo-title">CPU</div>
                <div class="pc-topo-tag" id="cpuTierLabel">Classifying…</div>
              </div>
              <div class="pc-topo-bars">
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Load at 1080p</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="cpuLoadBar"></div>
                  </div>
                </div>
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Headroom</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="cpuHeadroomBar"></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="pc-topo-card" data-part="gpu">
              <div class="pc-topo-header">
                <div class="pc-topo-title">GPU</div>
                <div class="pc-topo-tag" id="gpuTierLabel">Classifying…</div>
              </div>
              <div class="pc-topo-bars">
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Load at 1080p</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="gpuLoadBar"></div>
                  </div>
                </div>
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Headroom</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="gpuHeadroomBar"></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="pc-topo-card" data-part="ram">
              <div class="pc-topo-header">
                <div class="pc-topo-title">Memory</div>
                <div class="pc-topo-tag" id="ramTierLabel">Classifying…</div>
              </div>
              <div class="pc-topo-bars">
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Usage</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="ramLoadBar"></div>
                  </div>
                </div>
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Headroom</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="ramHeadroomBar"></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="pc-topo-card" data-part="storage">
              <div class="pc-topo-header">
                <div class="pc-topo-title">Storage</div>
                <div class="pc-topo-tag" id="storageTierLabel">Classifying…</div>
              </div>
              <div class="pc-topo-bars">
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Snappiness</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="storageSnapBar"></div>
                  </div>
                </div>
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Latency</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="storageLatencyBar"></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="pc-topo-card" data-part="network">
              <div class="pc-topo-header">
                <div class="pc-topo-title">Network</div>
                <div class="pc-topo-tag" id="netTierLabel">Classifying…</div>
              </div>
              <div class="pc-topo-bars">
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Stability</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="netStabilityBar"></div>
                  </div>
                </div>
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Latency</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="netLatencyBar"></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="pc-topo-card" data-part="thermals">
              <div class="pc-topo-header">
                <div class="pc-topo-title">Thermals</div>
                <div class="pc-topo-tag" id="thermTierLabel">Classifying…</div>
              </div>
              <div class="pc-topo-bars">
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Avg load temp</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="thermAvgBar"></div>
                  </div>
                </div>
                <div class="pc-topo-row">
                  <span class="pc-topo-row-label">Peak stress</span>
                  <div class="pc-topo-bar">
                    <div class="pc-topo-bar-fill" id="thermPeakBar"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

<div class="panel" style="margin-top:14px;">
      <div style="display:flex; gap:10px; align-items:center; justify-content:space-between; flex-wrap:wrap;">
        <div>
          <div class="card-title">Quickstart</div>
          <div class="card-desc">Create a backup → Apply a profile → Fine-tune individual toggles</div>
        </div>
        <div style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
          <label class="btn" style="display:flex; gap:10px; align-items:center;">
            <input type="checkbox" id="simToggle" ${simulationMode ? "checked":""} />
            <span>Simulation mode</span>
          </label>
          <button class="btn primary" id="homeBackupBtn">Create backup</button>
        </div>
      </div>
      <div id="homeBackupLog" style="margin-top:12px;"></div>
    </div><div class="progress"><div id="batchProgressBar" class="progress-bar" style="width:0%"></div></div>
      </div>
      <div id="profileLog" style="margin-top:12px;"></div>
    </div>

    <div class="panel" style="margin-top:14px;">
      <div class="card-title">Undo</div>
      <div class="card-desc">Revert tweaks that were applied by this app.</div>
      <div style="display:flex; gap:10px; flex-wrap:wrap; margin-top:10px;">
        <button class="btn" id="undoLastBtn">Undo last session</button>
        <button class="btn" id="undoAllBtn">Undo all</button>
        <button class="btn" id="viewHistBtn">View history</button>
      </div>
      <div id="undoLog" style="margin-top:12px;"></div>
    </div>

    <div class="panel" style="margin-top:14px;">
      <div class="card-title">Validate tweak library</div>
      <div class="card-desc">Runs the schema validator and auto-migrates known legacy keys.</div>
      <div style="display:flex; gap:10px; flex-wrap:wrap; margin-top:10px;">
        <button class="btn primary" id="validateBtn">Validate + migrate</button>
      </div>
      <div id="validateLog" style="margin-top:12px;"></div>
    </div>
  `;

  if (window.falcon && window.falcon.getSystemInfo) {
    loadPcSpecsAndFps().catch(() => {});
  }

  document.getElementById('simToggle').onchange = (e) => {
    setSimulationMode(!!e.target.checked);
    refresh(false);
  };


  const runHomeQuickTweak = async (file, tweakId, mode) => {
    try{
      const data = await loadJSON(file);
      const it = (data.items||[]).find(x => x && x.id === tweakId);
      if(!it || !it.apply || !Array.isArray(it.apply.steps)) {
        showToast(`Missing tweak: ${tweakId}`, 'error');
        return;
      }
      const steps = (String(mode||'apply').toLowerCase()==='revert')
        ? (it.revert && Array.isArray(it.revert.steps) ? it.revert.steps : [])
        : it.apply.steps;

      const res = await runTweakWithTimeout({
        id: it.id,
        mode: (String(mode||'apply').toLowerCase()==='revert') ? 'revert' : 'apply',
        steps,
        revertSteps: (it.revert && Array.isArray(it.revert.steps)) ? it.revert.steps : [],
        meta: { from: 'HomeQuick', source: file, name: it.name }
      }, 180000);

      if(res && res.ok) showToast(`${it.name}: done`, 'success');
      else showToast(`${it.name}: failed`, 'error');
    }catch(e){
      showToast(`Quick toggle failed: ${String(e&&e.message?e.message:e)}`, 'error');
    }
  };

  const btnOn = document.getElementById('homeDefenderOnBtn');
  if (btnOn) btnOn.onclick = () => runHomeQuickTweak('tweaks/advanced.security.json','adv.security.defender.restore_core','apply');

  const btnOff = document.getElementById('homeDefenderOffBtn');
  if (btnOff) btnOff.onclick = () => runHomeQuickTweak('tweaks/advanced.security.json','adv.security.defender.disable_core','apply');

  const btnMsi = document.getElementById('homeMsiRepairBtn');
  if (btnMsi) btnMsi.onclick = () => runHomeQuickTweak('tweaks/advanced.security.json','adv.security.windows_installer.repair','apply');


const refreshSecurityHome = async () => {
  try{
    const res = await window.falcon.securityHealthCheck();
    if(!res || !res.ok) throw new Error((res && res.error) ? res.error : 'health check failed');

    const tpEl = document.getElementById('secTamper');
    const msEl = document.getElementById('secMsiserver');
    const wdEl = document.getElementById('secWinDefend');
    const uiEl = document.getElementById('secSecUI');

    const byName = {};
    (res.services||[]).forEach(s => { if(s && s.name) byName[String(s.name)] = s; });

    const fmt = (s) => {
      if(!s) return 'Unknown';
      const st = String(s.startType||'UNKNOWN');
      const state = String(s.state||'UNKNOWN');
      return `${state} / ${st}`;
    };

    if (tpEl) tpEl.textContent = String(res.tamperProtection||'UNKNOWN');
    if (msEl) msEl.textContent = fmt(byName.msiserver);
    if (wdEl) wdEl.textContent = fmt(byName.WinDefend);
    if (uiEl) uiEl.textContent = `${fmt(byName.SecurityHealthService)} | ${fmt(byName.wscsvc)}`;
  }catch(e){
    // keep it quiet; user can press Refresh to try again
    const tpEl = document.getElementById('secTamper');
    if (tpEl) tpEl.textContent = 'Unknown';
  }
};

const btnAdv = document.getElementById('homeDefenderAdvOffBtn');
if (btnAdv) btnAdv.onclick = () => runHomeQuickTweak('tweaks/advanced.security.json','adv.security.defender.permanent_disable_advanced','apply');

const btnRef = document.getElementById('homeSecurityRefreshBtn');
if (btnRef) btnRef.onclick = () => refreshSecurityHome();

// Auto-refresh once when Home loads
refreshSecurityHome();





  document.getElementById('homeBackupBtn').onclick = async () => {
    const res = await window.falcon.createBackup({});
    document.getElementById('homeBackupLog').innerHTML = `<pre class="log">${__eh((res.stdout||'') + (res.stderr||''))}</pre>`;
  };

  document.getElementById('undoLastBtn').onclick = async () => {
    const res = await window.falcon.undoLastSession();
    document.getElementById('undoLog').innerHTML = `<pre class="log">${__eh((res.stdout||'') + (res.stderr||''))}</pre>`;
  };
  document.getElementById('undoAllBtn').onclick = async () => {
    const res = await window.falcon.undoAll();
    document.getElementById('undoLog').innerHTML = `<pre class="log">${__eh((res.stdout||'') + (res.stderr||''))}</pre>`;
  };
  document.getElementById('viewHistBtn').onclick = async () => {
    const h = await window.falcon.getHistory();
    document.getElementById('undoLog').innerHTML = `<pre class="log">${__eh(JSON.stringify(h,null,2))}</pre>`;
  };

  document.getElementById('validateBtn').onclick = async () => {
    const res = await window.falcon.validateTweaks();
    document.getElementById('validateLog').innerHTML = `<pre class="log">${__eh((res.stdout||'') + "\n" + (res.stderr||''))}</pre>`;
  };

  // Profiles
  (async () => {
    let prof;
    try { prof = await loadJSON('tweaks/profiles.json'); } catch(_) { prof = { profiles: [] }; }
    const btnWrap = document.getElementById('profileButtons');
    const logEl = document.getElementById('profileLog');
    const reasonLabel = {
      hidden: 'hidden/missing verification',
      low_hw_tier_risk: 'hardware tier risk guard',
      low_hw_tier_advanced: 'hardware tier advanced guard',
      risk_mismatch: 'risk mismatch',
      excluded_applyall: 'excludeFromApplyAll',
      not_toggle: 'not toggle',
      not_performance: 'not performance-targeted',
      vendor_mismatch: 'vendor mismatch',
      appearance: 'appearance/qol excluded',
      utility: 'utility/external excluded',
      delivery_optimization: 'delivery optimization excluded',
      desktop_machine_mismatch: 'desktop/laptop specialization mismatch',
      laptop_machine_mismatch: 'desktop/laptop specialization mismatch',
      laptop_safety_exclusion: 'laptop safety exclusion'
    };

    const machineProfile = await getStoredOrDetectedMachineProfile();

    const machineBtn = document.createElement('button');
    machineBtn.className = 'btn';
    machineBtn.textContent = machineProfile === 'laptop' ? 'Machine: Laptop (change)' : 'Machine: Desktop (change)';
    machineBtn.onclick = async () => {
      const chosen = await chooseMachineProfileForRun(await getStoredOrDetectedMachineProfile());
      const finalChoice = (chosen === 'laptop' ? 'laptop' : 'desktop');
      try { localStorage.setItem('falcon.machineProfile', finalChoice); } catch(_e) {}
      if (window.falcon) window.falcon.machineProfile = finalChoice;
      showToast('Machine profile set to ' + (finalChoice === 'laptop' ? 'Laptop' : 'Desktop') + '.', 'info');
      setTimeout(() => { window.location.reload(); }, 80);
    };
    btnWrap.appendChild(machineBtn);

    const rawProfiles = (prof.profiles || []).slice();
    const visibleProfiles = rawProfiles.filter((p) => {
      if (!Array.isArray(p.machineProfiles) || !p.machineProfiles.length) return true;
      return p.machineProfiles.includes(machineProfile);
    });

    visibleProfiles.sort((a, b) => {
      const aLaptop = Array.isArray(a.machineProfiles) && a.machineProfiles.includes('laptop');
      const bLaptop = Array.isArray(b.machineProfiles) && b.machineProfiles.includes('laptop');
      if (machineProfile === 'laptop' && aLaptop !== bLaptop) return aLaptop ? -1 : 1;
      return 0;
    });

    visibleProfiles.forEach(p => {
      const b = document.createElement('button');
      b.className = 'btn primary';
      b.textContent = p.name;
      b.onclick = async () => {
        try {
        if(p.requireTypedPhrase){
          const ok = await showConfirmModal({
            title: "All In (Risky)",
            body: "This profile includes Critical and excluded actions. A restore point is strongly recommended.",
            risk: "Critical",
            requireTyped: true
          });
          if(!ok) return;
        }
        const sources = [];
        Object.values(routes).forEach(r => (r.tabs||[]).forEach(t => sources.push(t.source)));
        const uniqueSources = [...new Set(sources)].filter(Boolean);

        const allItems = [];
        for(const src of uniqueSources){
          try{
            const data = await loadJSON(src);
            (data.items||[]).forEach(it => allItems.push(normalizeLibraryItem(it, src)));
          }catch(_){ }
        }

        const machineProfileForRun = await getStoredOrDetectedMachineProfile();
        const msg = machineProfileForRun === 'desktop'
          ? 'Machine profile: Desktop – maximum FPS and lowest latency.'
          : 'Machine profile: Laptop – balanced performance while respecting mobile power/thermals.';
        showToast(msg, 'info');

        const filterStats = {
          discovered: allItems.length,
          filteredIn: 0,
          reasons: {}
        };
        const bumpReason = (key) => {
          filterStats.reasons[key] = (filterStats.reasons[key] || 0) + 1;
        };

        const allowedRiskLevels = (Array.isArray(p.includeRiskLevels) && p.includeRiskLevels.length)
          ? p.includeRiskLevels.map(normalizeRiskLabel)
          : ["Safe", "Warning"].map(normalizeRiskLabel);

        const filtered = allItems.filter(it => {
          if(it && it.__hiddenReason) { bumpReason('hidden'); return false; }
          const risk = normRisk(it);

          const hwTierRaw = (window.falcon && window.falcon.hardwareTier) || "mid";
          const hwTier = String(hwTierRaw || "mid").toLowerCase();

          const id = String(it.id || "").toLowerCase();
          const cat = String(it.category || "").toLowerCase();
          const desc = String(it.description || "").toLowerCase();

          if (hwTier === "low" && riskRank(risk) >= 2) { bumpReason('low_hw_tier_risk'); return false; }
          if (hwTier === "mid" && riskRank(risk) >= 3) { bumpReason('low_hw_tier_risk'); return false; }

          if (hwTier === "low") {
            if (id.includes("gpu_nvidia_advanced") || id.includes("msi_mode") || id.includes("scheduler") || id.includes("paradime_advanced")) {
              bumpReason('low_hw_tier_advanced');
              return false;
            }
          }

          const allowed = allowedRiskLevels.includes(risk);
          if(!allowed) { bumpReason('risk_mismatch'); return false; }
          if(!p.includeExcluded && it.excludeFromApplyAll) { bumpReason('excluded_applyall'); return false; }
          if(it.type !== "toggle") { bumpReason('not_toggle'); return false; }

          const isPerformanceItem = hasFocusTag(it) || matchesPerformanceAllowlist(it);
          if(!isPerformanceItem) { bumpReason('not_performance'); return false; }

          if (currentGpuVendor && currentGpuVendor !== "auto" && currentGpuVendor !== "unknown") {
            const isNvidiaTweak = id.startsWith("gpu.nvidia");
            const isAmdTweak = id.startsWith("gpu.amd");
            if ((currentGpuVendor === "nvidia" && isAmdTweak) || (currentGpuVendor === "amd" && isNvidiaTweak)) {
              bumpReason('vendor_mismatch');
              return false;
            }
          }

          const isAppearance =
            cat.includes("ui & background") ||
            cat.includes("appearance") ||
            cat.includes("theme") ||
            cat.includes("qol") ||
            id.includes("ui.") ||
            id.includes("exp.ui.") ||
            id.includes("qol.") ||
            id.includes("appearance") ||
            id.includes("dark_mode") ||
            desc.includes("dark mode") ||
            desc.includes("theme");

          if(isAppearance) { bumpReason('appearance'); return false; }

          const isUtility = cat.includes("utility") || cat.includes("utilities") || id.startsWith("util.") || id.startsWith("external.");
          if (isUtility) { bumpReason('utility'); return false; }

          if(id.includes("core_disable_delivery_optimization") || id.includes("delivery_optimization")) {
            bumpReason('delivery_optimization');
            return false;
          }

          if(machineProfileForRun === "desktop" && (id.includes("laptop") || id.includes("_mobile") || id.includes("battery_saver"))) {
            bumpReason('desktop_machine_mismatch');
            return false;
          }
          if(machineProfileForRun === "laptop" && (id.includes("desktop") || id.includes("_desktop_only"))) {
            bumpReason('laptop_machine_mismatch');
            return false;
          }

          if (shouldExcludeForLaptopSafety(it, machineProfileForRun, p.id)) {
            bumpReason('laptop_safety_exclusion');
            return false;
          }

          filterStats.filteredIn++;
          return true;
        });

        const hasAggressive = filtered.some(it => itemRequiresAggressiveConsent(it));
        if (hasAggressive) {
          const accepted = await ensureAggressiveConsent('profile');
          if (!accepted) {
            logEl.innerHTML = `<pre class="log">${__eh('Profile run cancelled – aggressive tweaks require acceptance.')}</pre>`;
            setBatchProgress(false, 0, 0, "");
            return;
          }
        }

        const needsSnap = filtered.some(it => it.requiresSnapshot);
        if(needsSnap){
          const snap = await window.falcon.createBackup({});
          if(!snap.ok){
            logEl.innerHTML = `<pre class="log">${__eh("Snapshot failed; profile aborted.\n" + (snap.stdout||'') + "\n" + (snap.stderr||''))}</pre>`;
            return;
          }
        }

        let out = "";
        setBatchProgress(true, 0, filtered.length, 'Preparing…');
        const conf = resolveConflictGroups(filtered);
        const finalList = conf.kept;
        if(conf.skipped.length){
          out += `SKIP (conflict) ${conf.skipped.length} item(s) due to conflictGroup (kept first per group)
`;
        }

        const topReasons = Object.entries(filterStats.reasons)
          .sort((a,b) => b[1] - a[1])
          .slice(0, 8)
          .map(([k,v]) => `${reasonLabel[k] || k}: ${v}`)
          .join("\n");

        out += `FILTER SUMMARY
`;
        out += `- discovered: ${filterStats.discovered}
`;
        out += `- filtered in: ${filterStats.filteredIn}
`;
        out += `- after conflict resolution: ${finalList.length}
`;
        out += topReasons ? `- top filtered-out reasons:
${topReasons}

` : `- top filtered-out reasons: none

`;

        let idxRun = 0;
        let attempted = 0;
        let okCount = 0;
        let failCount = 0;
        let timeoutCount = 0;
        for(const it of finalList){
          idxRun++;
          setBatchProgress(true, idxRun, finalList.length, `${idxRun}/${finalList.length}  ${it.name}`);

          try {
            const risk = normRisk(it);

            if(isHighOrCritical(risk) || it.requireExplicitConfirm || it.requiresSnapshot){
              const ok = await showConfirmModal({
                title: it.warningTitle || `${risk} risk`,
                body: it.warningBody || it.description || it.name,
                risk,
                requireTyped: !!it.requireExplicitConfirm || risk==="Critical"
              });
              if(!ok) { out += `SKIP ${it.id}
`; continue; }
            }

            const applySteps = adjustStepsForHwProfile(it, 'apply', getStepsFor(it,'apply'));
            const revertSteps = adjustStepsForHwProfile(it, 'revert', getStepsFor(it,'revert'));

            if (!Array.isArray(applySteps) || applySteps.length === 0) {
              failCount++;
              out += `ERR ${it.id} (no apply steps)
`;
              continue;
            }

            attempted++;

            if(simulationMode){
              const plan = await window.falcon.dryRunSteps(applySteps);
              out += `SIM ${it.id} ${it.name}
${JSON.stringify(plan.plan,null,2)}

`;
            } else {
              const res = await runTweakWithTimeout({
                id: it.id,
                mode: "apply",
                steps: applySteps,
                revertSteps,
                meta: { profile: p.id, riskLevel: risk, hwProfile: currentHwProfile || 'auto' }
              }, 90000);
              const okFlag = !!(res && res.ok);
              if (okFlag) okCount++; else failCount++;
              if (res && res.timeout) timeoutCount++;

              out += `${res && res.ok ? "OK" : "ERR"} ${it.id}`;
              if (res && res.timeout) out += ' (timeout)';
              out += `
`;
              try {
                const nm = it && it.name ? it.name : it.id;
                showToast((nm || "Optimization") + (okFlag ? " applied successfully." : " failed or partially applied. Check log."), okFlag ? "success" : "error");
              } catch (toastErr) {
                console && console.warn && console.warn("profile tweak toast error", toastErr);
              }
            }
          } catch (itemErr) {
            failCount++;
            const itemMsg = String((itemErr && (itemErr.stack || itemErr.message)) || itemErr || 'Unknown item error');
            out += `ERR ${it && it.id ? it.id : '(unknown)'}
${itemMsg}
`;
            console && console.error && console.error('profile item failed', it && it.id, itemErr);
          }
        }
        const summaryLine = `SUMMARY Profile ${p.id || p.name || "(unnamed)"}: ${attempted} attempted, ${okCount} OK, ${failCount} failed, ${timeoutCount} timeouts.`;
        out += `
${summaryLine}
`;
        try {
          const mpLabel = machineProfileForRun === "desktop" ? "Desktop" : "Laptop";
          const toastText = `Profile ${p.name || p.id || "(unnamed)"} (${mpLabel}) completed: ${attempted} attempted, ${okCount} OK, ${failCount} failed, ${timeoutCount} timeouts.`;
          const hasError = (failCount > 0 || timeoutCount > 0);
          showToast(toastText, hasError ? "error" : "success");
        } catch (e) {
          console && console.warn && console.warn("profile summary toast error", e);
        }

        try {
          if (p && p.applyStretchDefault) {
            const applied = await applyDefaultStretchPreset();
            if (applied && applied.ok) {
              out += `
STRETCH OK  ${applied.label||''}
`;
            } else if (applied && applied.skipped) {
              out += `
STRETCH SKIP  ${applied.reason||''}
`;
            } else if (applied && applied.error) {
              out += `
STRETCH ERR  ${applied.error||''}
`;
            }
          }
        } catch(_e) {
          out += `
STRETCH ERR  unexpected error
`;
        }

        logEl.innerHTML = `<pre class="log">${__eh(out.trim()||"(no actions)")}</pre>`;
        } catch (e) {
          const errorText = String((e && (e.stack || e.message)) || e || 'Unknown profile error');
          console && console.error && console.error('profile run failed', e);
          try {
            logEl.innerHTML = `<pre class="log">${__eh("Profile run failed.\n\n" + errorText)}</pre>`;
          } catch(_logErr) {}
          try { showToast('Profile run failed. Check log for details.', 'error'); } catch(_e) {}
        } finally {
          setBatchProgress(false, 0, 0, "");
        }
      };
      btnWrap.appendChild(b);
    });
  })();
}



function renderLanguage(){
  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Language</div>
      <div class="card-desc">
        Choose how Falcon Optimizer labels and presents options. This does not change your Windows system language,
        only how Falcon shows text and descriptions.
      </div>
      <div class="field">
        <label class="field-label">UI language</label>
        <select id="falconLanguageSelect" class="input">
          <option value="system">Match Windows (System)</option>
          <option value="en">English (Recommended)</option>
        </select>
      </div>
      <div class="field">
        <label class="field-label">Detail level</label>
        <select id="falconLanguageDetail" class="input">
          <option value="full">Full descriptions</option>
          <option value="compact">Compact (short labels)</option>
        </select>
      </div>
      <p class="muted" style="margin-top:8px;">
        Language preferences are saved locally on this PC.
      </p>
    </div>
  `;

  try{
    const selectLang = document.getElementById('falconLanguageSelect');
    const selectDetail = document.getElementById('falconLanguageDetail');
    if (window.localStorage && selectLang && selectDetail) {
      const storedLang = window.localStorage.getItem('falcon.ui.language') || 'system';
      const storedDetail = window.localStorage.getItem('falcon.ui.languageDetail') || 'full';
      selectLang.value = storedLang;
      selectDetail.value = storedDetail;

      selectLang.onchange = () => {
        window.localStorage.setItem('falcon.ui.language', selectLang.value);
        showToast('Language preference saved: ' + selectLang.value, 'info');
      };
      selectDetail.onchange = () => {
        window.localStorage.setItem('falcon.ui.languageDetail', selectDetail.value);
        showToast('Description detail level saved: ' + selectDetail.value, 'info');
        // Re-render current view so all cards reflect the new detail level
        try { refresh(false); } catch(_e) {}
      };
    }
  }catch(e){
    console && console.warn && console.warn('renderLanguage failed', e);
  }
}

function renderBackups(){
  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Snapshots</div>
      <div class="card-desc">Creates a Restore Point (if allowed) and exports policy keys for revert support.</div>
      <div class="card-actions">
        <button class="btn primary" id="backupCreate">Create snapshot</button>
        <button class="btn" id="backupRestore">Restore latest</button>
      </div>
      <div id="backupLog" style="margin-top:12px;"></div>
    </div>
  `;
  const logEl = document.getElementById('backupLog');
  document.getElementById('backupCreate').onclick = async () => {
    const res = await window.falcon.createBackup({});
    logEl.innerHTML = `<pre class="log">${__eh((res.stdout||'') + (res.stderr||''))}</pre>`;
  };
  document.getElementById('backupRestore').onclick = async () => {
    const res = await window.falcon.restoreBackup({ mode:'latest' });
    logEl.innerHTML = `<pre class="log">${__eh((res.stdout||'') + (res.stderr||''))}</pre>`;
  };
}

async function renderStretchLab(){
  let stretchData = null;
  try { stretchData = await loadJSON('tweaks/game.stretchres.json'); }
  catch (_) { stretchData = { items: [] }; }

  const items = Array.isArray(stretchData.items) ? stretchData.items : [];
  let proDb = { entries: [] };
  try { proDb = await window.falcon.readJson('data/pro_res_db.json'); } catch(_) { proDb = { entries: [] }; }
  const proMap = new Map((proDb.entries||[]).map(e=>[String(e.key||'').toLowerCase(), e]));

  // Merge pro info onto items by resolution key (e.g. 1750x1080)
  for (const it of items){
    if(!it) continue;
    const ss = `${it.id||''} ${it.name||''} ${it.description||''}`;
    const m = ss.match(/\b(\d{3,4})\s*[xX]\s*(\d{3,4})\b/);
    if(!m) continue;
    const key = `${parseInt(m[1],10)}x${parseInt(m[2],10)}`.toLowerCase();
    const entry = proMap.get(key);
    if(entry){
      it.pros = Array.isArray(entry.pros) ? entry.pros : [];
      it.proSources = Array.isArray(entry.sources) ? entry.sources : [];
    }
  }

  const byGame = {
    fortnite: { label: 'Fortnite', match: 'Fortnite' },
    cs2: { label: 'CS2', match: 'CS2' },
    valorant: { label: 'Valorant', match: 'Valorant' },
    apex: { label: 'Apex Legends', match: 'Apex' },
    cod: { label: 'Call of Duty / Warzone', match: 'COD' },
    overwatch: { label: 'Overwatch 2', match: 'Overwatch' },
    rocket: { label: 'Rocket League', match: 'Rocket' },
    gta5: { label: 'GTA V', match: 'GTA' },
    any: { label: 'Any Game', match: 'Any Game' }
  };

  function guessGame(item){
    const cat = String(item.category||'');
    for (const k of Object.keys(byGame)){
      if (cat.toLowerCase().includes(byGame[k].match.toLowerCase())) return k;
    }
    return 'any';
  }

  const gameBuckets = {};
  for (const k of Object.keys(byGame)) gameBuckets[k] = [];
  for (const it of items){
    if(!it || !it.id) continue;
    const g = guessGame(it);
    gameBuckets[g].push(it);
  }

  const gameButtons = Object.keys(byGame).map(k => {
    const count = gameBuckets[k].length;
    return `<button class="pill" data-stretch-game="${k}">${byGame[k].label}<span class="pill-count">${count}</span></button>`;
  }).join("");

  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">StretchLab</div>
      <div class="card-desc">Resolution presets and true stretched scaling helpers. Fortnite presets apply directly. Other games provide launch options or safe copy/open tools.</div>

      <div class="stretch-wrap">
        <div class="stretch-left">
          <div class="stretch-title">Pick a game</div>
          <div class="pill-row" id="stretchGameRow">${gameButtons}</div>

          <div class="card" style="margin-top:12px;">
            <div class="card-title">Custom resolution</div>
            <div class="card-desc">Set a custom stretched resolution. Fortnite can apply directly. Steam games can copy launch options.</div>
            <div class="stretch-custom">
              <input class="input" id="stretchW" type="number" min="640" max="7680" step="1" placeholder="Width (e.g. 1750)" />
              <input class="input" id="stretchH" type="number" min="480" max="4320" step="1" placeholder="Height (e.g. 1080)" />
              <input class="input" id="stretchFps" type="number" min="30" max="600" step="1" placeholder="FPS cap (optional, e.g. 240)" />
            </div>
            <div class="row" style="margin-top:10px; align-items:center;">
              <div class="hint" style="margin:0 10px 0 0;">Apply INI/XML for:</div>
              <select class="input" id="stretchGameApply" style="max-width:240px;">
                <option value="fortnite">Fortnite (INI)</option>
                <option value="valorant">VALORANT (INI)</option>
                <option value="rocketleague">Rocket League (INI)</option>
                <option value="gtav">GTA V (settings.xml)</option>
              </select>
            </div>
            <div class="row" style="margin-top:10px; gap:10px; flex-wrap:wrap;">
              <button class="btn primary" id="btnStretchApply">Apply…</button>
              <button class="btn" id="btnResetDefaultRes">Reset to default (1920x1080)…</button>
            </div>
            <div class="hint">Apply… opens a clean menu: game INI (when supported), copy launch options, GPU scaling panel, or PC display.</div>
          </div>

          <div class="card" style="margin-top:12px;">
            <div class="card-title">GPU scaling panel</div>
            <div class="card-desc">Open NVIDIA/AMD scaling settings to enable Full-screen scaling (stretched) instead of aspect ratio.</div>
            <button class="btn" id="btnOpenScaling">Open GPU scaling panel</button>
          </div>
        </div>

        <div class="stretch-right">
          <div class="stretch-title" id="stretchRightTitle">Presets</div>
          <div class="stretch-cards hscroll-wheel" id="stretchCards"></div>
        </div>
      </div>
    </div>
  `;

  // Enable horizontal wheel scrolling for presets and cards
  try{
    const gr = document.getElementById('stretchGameRow');
    if(gr) gr.classList.add('hscroll-wheel');
    const sc = document.getElementById('stretchCards');
    if(sc) sc.classList.add('hscroll-wheel','stretch-hscroll');
    bindHorizontalWheelScroll(document);
  }catch(_){ }

  // Wire scaling tool (re-use existing item if present)
  const scalingItem = items.find(x => x.id === 'stretch_open_gpu_scaling_panel');
  document.getElementById('btnOpenScaling').onclick = async () => {
    if (!scalingItem) return;
    await runItem(scalingItem, 'apply');
  };

  function normalizeInt(v){
    const n = parseInt(String(v||'').trim(), 10);
    return Number.isFinite(n) ? n : null;
  }

  function parseResolutionFromItem(it){
    // Try id like *_1750x1080 or name containing 1750x1080
    const s = `${it.id||''} ${it.name||''} ${it.description||''}`;
    const m = s.match(/\b(\d{3,4})\s*[xX]\s*(\d{3,4})\b/);
    if (!m) return null;
    const w = parseInt(m[1],10), h = parseInt(m[2],10);
    if (!Number.isFinite(w) || !Number.isFinite(h)) return null;
    return { w, h };
  }

  async function copyTextToClipboard(txt){
    try { await navigator.clipboard.writeText(txt); toast('Copied to clipboard.'); }
    catch (_) { prompt('Copy:', txt); }
  }

  async function applyValorantResolution(w,h,fpsCap){
    const cmd =
      `$root = Join-Path $env:LOCALAPPDATA 'VALORANT\\Saved\\Config';`+
      `if (!(Test-Path $root)) { Write-Output 'VALORANT config root not found.'; exit 0 } `+
      `$ini = Get-ChildItem -Path $root -Recurse -Filter 'GameUserSettings.ini' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1;`+
      `if (-not $ini) { Write-Output 'GameUserSettings.ini not found.'; exit 0 } `+
      `$path = $ini.FullName; `+
      `$bakDir = Join-Path $env:ProgramData 'FalconOptimizer\\stretch_backups'; New-Item -ItemType Directory -Force -Path $bakDir | Out-Null; `+
      `$bak = Join-Path $bakDir ('VALORANT_GameUserSettings_' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.ini'); Copy-Item $path $bak -Force; `+
      `$content = Get-Content $path; `+
      `$kv = @{ 'ResolutionSizeX'='${w}'; 'ResolutionSizeY'='${h}'; 'LastUserConfirmedResolutionSizeX'='${w}'; 'LastUserConfirmedResolutionSizeY'='${h}'; 'FullscreenMode'='0' }; `+
      (fpsCap ? ` $kv['FrameRateLimit']='${fpsCap}'; `+` ` : ``) +
      `foreach($k in $kv.Keys){ $replacement = $k + '=' + $kv[$k]; $found = $false; $content = $content | ForEach-Object { if ($_ -like ($k + '=*')) { $found = $true; $replacement } else { $_ } }; if (-not $found) { $content += $replacement } } `+
      `Set-Content -Path $path -Value $content -Encoding ASCII; Write-Output 'Applied VALORANT resolution.'; Write-Output ('Backup: ' + $bak);`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
  }

  async function applyRocketLeagueResolution(w,h,fpsCap){
    const cmd =
      `$path = Join-Path $env:USERPROFILE 'Documents\\My Games\\Rocket League\\TAGame\\Config\\TASystemSettings.ini';`+
      `if (!(Test-Path $path)) { Write-Output 'TASystemSettings.ini not found.'; exit 0 } `+
      `$bakDir = Join-Path $env:ProgramData 'FalconOptimizer\\stretch_backups'; New-Item -ItemType Directory -Force -Path $bakDir | Out-Null; `+
      `$bak = Join-Path $bakDir ('RocketLeague_TASystemSettings_' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.ini'); Copy-Item $path $bak -Force; `+
      `$content = Get-Content $path; `+
      `$kv = @{ 'ResX'='${w}'; 'ResY'='${h}'; 'Fullscreen'='True' }; `+
      `foreach($k in $kv.Keys){ $replacement = $k + '=' + $kv[$k]; $found = $false; $content = $content | ForEach-Object { if ($_ -match ('^' + [regex]::Escape($k) + '\\s*=') ) { $found = $true; $replacement } else { $_ } }; if (-not $found) { $content += $replacement } } `+
      `Set-Content -Path $path -Value $content -Encoding ASCII; Write-Output 'Applied Rocket League resolution.'; Write-Output ('Backup: ' + $bak);`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
  }

  async function applyGtaVResolution(w,h,fpsCap){
    const cmd =
      `$path = Join-Path $env:USERPROFILE 'Documents\\Rockstar Games\\GTA V\\settings.xml';`+
      `if (!(Test-Path $path)) { Write-Output 'GTA V settings.xml not found.'; exit 0 } `+
      `$bakDir = Join-Path $env:ProgramData 'FalconOptimizer\\stretch_backups'; New-Item -ItemType Directory -Force -Path $bakDir | Out-Null; `+
      `$bak = Join-Path $bakDir ('GTAV_settings_' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.xml'); Copy-Item $path $bak -Force; `+
      `$xml = Get-Content $path -Raw; `+
      `$xml = $xml -replace '<screenWidth>\d+</screenWidth>', '<screenWidth>${w}</screenWidth>'; `+
      `$xml = $xml -replace '<screenHeight>\d+</screenHeight>', '<screenHeight>${h}</screenHeight>'; `+
      `Set-Content -Path $path -Value $xml -Encoding UTF8; Write-Output 'Applied GTA V resolution.'; Write-Output ('Backup: ' + $bak);`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
  }

  async function applyWindowsDisplayResolution(w,h){
    // Sets PRIMARY display resolution (best-effort) using ChangeDisplaySettings.
    // Saves current resolution to ProgramData\FalconOptimizer\stretch_backups\pc_display_last.json for restore.
    const cmd =
`$bakDir = Join-Path $env:ProgramData 'FalconOptimizer\\stretch_backups'; New-Item -ItemType Directory -Force -Path $bakDir | Out-Null;
$state = Join-Path $bakDir 'pc_display_last.json';

# Best-effort current resolution capture
$curW = $null; $curH = $null;
try {
  $vc = Get-CimInstance Win32_VideoController | Select-Object -First 1;
  if ($vc -and $vc.CurrentHorizontalResolution -and $vc.CurrentVerticalResolution) { $curW = [int]$vc.CurrentHorizontalResolution; $curH = [int]$vc.CurrentVerticalResolution; }
} catch {}

try {
  $obj = @{ width = $curW; height = $curH; time = (Get-Date).ToString('o') } | ConvertTo-Json -Depth 3;
  Set-Content -Path $state -Value $obj -Encoding UTF8;
} catch {}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DisplayUtil {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
  public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmDeviceName;
    public short dmSpecVersion;
    public short dmDriverVersion;
    public short dmSize;
    public short dmDriverExtra;
    public int dmFields;

    public int dmPositionX;
    public int dmPositionY;
    public int dmDisplayOrientation;
    public int dmDisplayFixedOutput;

    public short dmColor;
    public short dmDuplex;
    public short dmYResolution;
    public short dmTTOption;
    public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel;
    public int dmPelsWidth;
    public int dmPelsHeight;
    public int dmDisplayFlags;
    public int dmDisplayFrequency;

    public int dmICMMethod;
    public int dmICMIntent;
    public int dmMediaType;
    public int dmDitherType;
    public int dmReserved1;
    public int dmReserved2;

    public int dmPanningWidth;
    public int dmPanningHeight;
  }

  [DllImport("user32.dll", CharSet=CharSet.Ansi)]
  public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

  [DllImport("user32.dll", CharSet=CharSet.Ansi)]
  public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

  public const int ENUM_CURRENT_SETTINGS = -1;
  public const int CDS_UPDATEREGISTRY = 0x01;
  public const int DISP_CHANGE_SUCCESSFUL = 0;
  public const int DM_PELSWIDTH = 0x80000;
  public const int DM_PELSHEIGHT = 0x100000;
}
"@ -ErrorAction SilentlyContinue | Out-Null;

$dev = New-Object DisplayUtil+DEVMODE;
$dev.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dev);
[void][DisplayUtil]::EnumDisplaySettings($null, [DisplayUtil]::ENUM_CURRENT_SETTINGS, [ref]$dev);
$dev.dmFields = $dev.dmFields -bor [DisplayUtil]::DM_PELSWIDTH -bor [DisplayUtil]::DM_PELSHEIGHT;
$dev.dmPelsWidth = ${w};
$dev.dmPelsHeight = ${h};
$r = [DisplayUtil]::ChangeDisplaySettings([ref]$dev, [DisplayUtil]::CDS_UPDATEREGISTRY);
if ($r -eq [DisplayUtil]::DISP_CHANGE_SUCCESSFUL) { Write-Output 'Applied Windows display resolution.' } else { Write-Output ('Failed applying resolution. Code: ' + $r) }`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
  }

  async function restoreWindowsDisplayResolution(){
    const cmd =
`$state = Join-Path $env:ProgramData 'FalconOptimizer\\stretch_backups\\pc_display_last.json';
if (!(Test-Path $state)) { Write-Output 'No saved display state found.'; exit 0 }
$j = Get-Content $state -Raw | ConvertFrom-Json;
$w = [int]$j.width; $h = [int]$j.height;
if (-not $w -or -not $h) { Write-Output 'Saved state missing width/height.'; exit 0 }

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DisplayUtil {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
  public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmDeviceName;
    public short dmSpecVersion;
    public short dmDriverVersion;
    public short dmSize;
    public short dmDriverExtra;
    public int dmFields;

    public int dmPositionX;
    public int dmPositionY;
    public int dmDisplayOrientation;
    public int dmDisplayFixedOutput;

    public short dmColor;
    public short dmDuplex;
    public short dmYResolution;
    public short dmTTOption;
    public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel;
    public int dmPelsWidth;
    public int dmPelsHeight;
    public int dmDisplayFlags;
    public int dmDisplayFrequency;

    public int dmICMMethod;
    public int dmICMIntent;
    public int dmMediaType;
    public int dmDitherType;
    public int dmReserved1;
    public int dmReserved2;

    public int dmPanningWidth;
    public int dmPanningHeight;
  }

  [DllImport("user32.dll", CharSet=CharSet.Ansi)]
  public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

  [DllImport("user32.dll", CharSet=CharSet.Ansi)]
  public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

  public const int ENUM_CURRENT_SETTINGS = -1;
  public const int CDS_UPDATEREGISTRY = 0x01;
  public const int DISP_CHANGE_SUCCESSFUL = 0;
  public const int DM_PELSWIDTH = 0x80000;
  public const int DM_PELSHEIGHT = 0x100000;
}
"@ -ErrorAction SilentlyContinue | Out-Null;

$dev = New-Object DisplayUtil+DEVMODE;
$dev.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dev);
[void][DisplayUtil]::EnumDisplaySettings($null, [DisplayUtil]::ENUM_CURRENT_SETTINGS, [ref]$dev);
$dev.dmFields = $dev.dmFields -bor [DisplayUtil]::DM_PELSWIDTH -bor [DisplayUtil]::DM_PELSHEIGHT;
$dev.dmPelsWidth = $w;
$dev.dmPelsHeight = $h;
$r = [DisplayUtil]::ChangeDisplaySettings([ref]$dev, [DisplayUtil]::CDS_UPDATEREGISTRY);
if ($r -eq [DisplayUtil]::DISP_CHANGE_SUCCESSFUL) { Write-Output 'Restored Windows display resolution.' } else { Write-Output ('Failed restoring resolution. Code: ' + $r) }`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
  }


  function showStretchApplyModal(it, gameKey){
    const res = parseResolutionFromItem(it);
    const w = res?.w, h = res?.h;
    const fpsCap = (it && Number.isFinite(it.fpsCap) ? it.fpsCap : null);
    const title = `${it.name||it.id}`;
    const desc = it.description || '';
    const pros = Array.isArray(it.pros) ? it.pros : [];
    const sources = Array.isArray(it.proSources) ? it.proSources : [];
    const prosHtml = pros.length ? `<div class="chips" style="margin-top:10px;">${pros.map(p=>`<span class=\"chip\">${__eh(p)}</span>`).join('')}</div>` : '';
    const opts = [];
    // Always allow copy
    opts.push({ id:'copy_wxh', label:'Copy WxH', run: async()=> copyTextToClipboard(`${w}x${h}`) });
    opts.push({ id:'copy_steam', label:'Copy Steam launch opts', run: async()=> copySteamOpts(w,h) });
    if (scalingItem) opts.push({ id:'open_scaling', label:'Open GPU scaling panel', run: async()=> runItem(scalingItem,'apply') });
    opts.push({ id:'apply_pc_any', label:'Apply to PC display (system)', run: async()=> applyWindowsDisplayResolution(w,h) });
    opts.push({ id:'restore_pc_any', label:'Restore PC display (last saved)', run: async()=> restoreWindowsDisplayResolution() });
    // Auto-Apply integration: set this preset as default Stretch for profile runs
    opts.push({ id:'set_default_stretch', label:'Set as default for Auto Apply', run: async()=> {
      try {
        const payload = { w, h, gameKey: gameKey||'any', presetId: it.id||null, presetName: it.name||null, mode: (gameKey==='fortnite'?'fortnite':(gameKey==='valorant'?'valorant':(gameKey==='rocket'?'rocket':(gameKey==='gta5'?'gta5':'pc')))) };
        if (window.localStorage) window.localStorage.setItem('falcon.stretch.default', JSON.stringify(payload));
        toast('Default Stretch preset saved for Auto Apply.');
      } catch(_e) { toast('Could not save default Stretch preset.'); }
    }});
    // Game INI applies where implemented
    if (gameKey==='fortnite') opts.unshift({ id:'apply_fortnite', label:'Apply to Fortnite (INI)', run: async()=> runItem(it,'apply') });
    if (gameKey==='valorant') opts.unshift({ id:'apply_val', label:'Apply to VALORANT (INI)', run: async()=> applyValorantResolution(w,h,fpsCap) });
    if (gameKey==='rocket') opts.unshift({ id:'apply_rl', label:'Apply to Rocket League (INI)', run: async()=> applyRocketLeagueResolution(w,h,fpsCap) });
    if (gameKey==='any') {
      opts.unshift({ id:'restore_pc', label:'Restore PC display (last saved)', run: async()=> restoreWindowsDisplayResolution() });
      opts.unshift({ id:'apply_pc', label:'Apply to PC display (system)', run: async()=> applyWindowsDisplayResolution(w,h) });
      opts.unshift({ id:'open_display', label:'Open Windows Display Settings', run: async()=> window.falcon.runSteps({steps:[{type:'ps.run',command:'Start-Process ms-settings:display'}]}) });
    }
    if (gameKey==='gta5') opts.unshift({ id:'apply_gtav', label:'Apply to GTA V (settings.xml)', run: async()=> applyGtaVResolution(w,h,fpsCap) });
    // Basic open folders
    const folders = {
      fortnite: `$p=Join-Path $env:LOCALAPPDATA 'FortniteGame\\Saved\\Config\\WindowsClient'; if(Test-Path $p){Start-Process $p}else{Write-Output 'Not found.'}`,
      valorant: `$p=Join-Path $env:LOCALAPPDATA 'VALORANT\\Saved\\Config'; if(Test-Path $p){Start-Process $p}else{Write-Output 'Not found.'}`,
      rocket: `$p=Join-Path $env:USERPROFILE 'Documents\\My Games\\Rocket League\\TAGame\\Config'; if(Test-Path $p){Start-Process $p}else{Write-Output 'Not found.'}`,
      overwatch: `$p=Join-Path $env:USERPROFILE 'Documents\\Overwatch\\Settings'; if(Test-Path $p){Start-Process $p}else{Write-Output 'Not found.'}`,
      gta5: `$p=Join-Path $env:USERPROFILE 'Documents\\Rockstar Games\\GTA V'; if(Test-Path $p){Start-Process $p}else{Write-Output 'Not found.'}`,
    };
    if (folders[gameKey]) opts.push({ id:'open_folder', label:'Open config folder', run: async()=> window.falcon.runSteps({steps:[{type:'ps.run',command:folders[gameKey]}]}) });

    const modal = document.createElement('div');
    modal.className='modal-backdrop';
    const buttons = opts.map(o=>`<button class="btn ${o.id.startsWith('apply')?'primary':''}" data-act="${o.id}">${__eh(o.label)}</button>`).join('');
    modal.innerHTML = `
      <div class="modal">
        <div class="modal-title">${__eh(title)}</div>
        <div class="modal-desc">${__eh(desc)}</div>${prosHtml}<div id="proSrcRow"></div>
        <div class="modal-actions" style="flex-wrap:wrap; gap:10px;">
          ${buttons}
          <button class="btn" data-act="close">Close</button>
        </div>
        <div class="hint" style="margin-top:10px;">Tip: for best stretched look, enable Full-screen scaling in GPU control panel.</div>
      </div>`;
    document.body.appendChild(modal);
    // Render pro sources (if any)
    try {
      const row = modal.querySelector('#proSrcRow');
      if (row && sources && sources.length) {
        row.className = 'hint';
        row.style.marginTop = '8px';
        row.appendChild(document.createTextNode('Sources: '));
        sources.forEach((src, idx) => {
          if (idx) row.appendChild(document.createTextNode(' · '));
          const a = document.createElement('a');
          a.href = '#';
          a.className = 'link';
          a.textContent = String((src && src.label) ? src.label : 'source');
          a.onclick = (e) => { e.preventDefault(); if (src && src.url) window.falcon.openExternal(String(src.url)); };
          row.appendChild(a);
        });
      }
    } catch(_) {}

    modal.querySelectorAll('button[data-act]').forEach(b=>{
      b.onclick = async()=>{
        const act=b.getAttribute('data-act');
        if(act==='close'){ modal.remove(); return; }
        if(!w||!h){ toast('Resolution not detected on this preset.'); return; }
        const o=opts.find(x=>x.id===act);
        if(o){ try{ await o.run(); } finally{ modal.remove(); } }
      };
    });
    modal.onclick=(e)=>{ if(e.target===modal) modal.remove(); };
  }

  async function applyFortniteCustom(w,h){
    const cmd = `$path = Join-Path $env:LOCALAPPDATA 'FortniteGame\\Saved\\Config\\WindowsClient\\GameUserSettings.ini'; if (!(Test-Path $path)) { Write-Output 'GameUserSettings.ini not found.'; exit 0 } `
      + `$bakDir = Join-Path $env:ProgramData 'FalconOptimizer\\stretch_backups'; New-Item -ItemType Directory -Force -Path $bakDir | Out-Null; `
      + `$bak = Join-Path $bakDir ('GameUserSettings_' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.ini'); Copy-Item $path $bak -Force; `
      + `$content = Get-Content $path; `
      + `$kv = @{ 'ResolutionSizeX'='${w}'; 'ResolutionSizeY'='${h}'; 'LastUserConfirmedResolutionSizeX'='${w}'; 'LastUserConfirmedResolutionSizeY'='${h}'; 'DesiredScreenWidth'='${w}'; 'DesiredScreenHeight'='${h}'; 'LastUserConfirmedDesiredScreenWidth'='${w}'; 'LastUserConfirmedDesiredScreenHeight'='${h}'; 'FullscreenMode'='0' }; `
      + `foreach($k in $kv.Keys){ $replacement = $k + '=' + $kv[$k]; $found = $false; $content = $content | ForEach-Object { if ($_ -like ($k + '=*')) { $found = $true; $replacement } else { $_ } }; if (-not $found) { $content += $replacement } } `
      + `Set-Content -Path $path -Value $content -Encoding ASCII; Write-Output 'Applied Fortnite custom stretched resolution.'; Write-Output ('Backup: ' + $bak);`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
    showToast(`Applied ${w}x${h} to Fortnite (backup saved)`, 'success');
  }

  async function copySteamOpts(w,h){
    const cmd = `Set-Clipboard -Value "-w ${w} -h ${h} -fullscreen"; Write-Output "Copied Steam launch options to clipboard."`;
    await window.falcon.runSteps({ steps: [{ type: 'ps.run', command: cmd }] });
    showToast(`Copied: -w ${w} -h ${h} -fullscreen`, 'success');
  }

  // Clean Apply… menu for custom resolution (avoids clutter and prevents "Fortnite for all" fallbacks).
  document.getElementById('btnStretchApply').onclick = async () => {
    const w = normalizeInt(document.getElementById('stretchW').value);
    const h = normalizeInt(document.getElementById('stretchH').value);
    if(!w || !h) return alert('Enter Width and Height.');
    const g = (document.getElementById('stretchGameApply')||{}).value || 'fortnite';
    const fpsCap = normalizeInt(document.getElementById('stretchFps')?.value);

    const keyMap = { fortnite:'fortnite', valorant:'valorant', rocketleague:'rocket', gtav:'gta5' };
    const gameKey = keyMap[g] || 'any';
    const it = {
      fpsCap: fpsCap || null,
      id: `stretch_custom_${w}x${h}_${gameKey}`,
      name: `Custom ${w}x${h}`,
      description: `Apply ${w}x${h} using the method you choose (INI, launch options, GPU scaling, or PC display).`,
      pros: [],
      proSources: []
    };
    showStretchApplyModal(it, gameKey);
  };

  document.getElementById('btnResetDefaultRes').onclick = async () => {
    document.getElementById('stretchW').value = 1920;
    document.getElementById('stretchH').value = 1080;
    // Open a clean apply modal with the available methods for the currently selected game
    const dummy = { id:'stretch_default_1920x1080', name:'Reset to default (1920x1080)', description:'Restores native 1920x1080. Use the apply method below for your game.', pros:[] };
    showStretchApplyModal(dummy, selected);
  };

  function renderCards(gameKey){
    const list = (gameBuckets[gameKey] || []).slice();
    list.sort((a,b) => String(a.category||'').localeCompare(String(b.category||'')) || String(a.name||'').localeCompare(String(b.name||'')));

    document.getElementById('stretchRightTitle').textContent = `${byGame[gameKey].label} presets`;
    const host = document.getElementById('stretchCards');
    host.innerHTML = '';

    for (const it of list){
      const hasApply = (it.apply && Array.isArray(it.apply.steps) && it.apply.steps.length>0);
      const btnText = 'Apply';
      const el = document.createElement('div');
      el.className = 'card';
      el.innerHTML = `
        <div class="card-title">${__eh(it.name||it.id)}</div>
        <div class="card-desc">${__eh(it.description||'')}</div>
        <div class="row" style="margin-top:10px;">
          <button class="btn primary" data-run="${it.id}">${btnText}</button>
        </div>
      `;
      host.appendChild(el);
    }

    host.querySelectorAll('button[data-run]').forEach(btn=>{
      btn.onclick = async () => {
        const id = btn.getAttribute('data-run');
        const it = list.find(x=>x.id===id);
        if(!it) return;
        // Clean apply UI: show a single modal with game-specific apply/copy/open methods
        showStretchApplyModal(it, gameKey);
      };
    });
  }

  // default game
  let selected = 'fortnite';
  renderCards(selected);

  document.getElementById('stretchGameRow').querySelectorAll('button[data-stretch-game]').forEach(b=>{
    b.onclick = () => {
      document.getElementById('stretchGameRow').querySelectorAll('button[data-stretch-game]').forEach(x=>x.classList.remove('active'));
      b.classList.add('active');
      selected = b.getAttribute('data-stretch-game');
      renderCards(selected);
    };
  });
  // mark default active
  const firstBtn = document.querySelector('button[data-stretch-game="'+selected+'"]');
  if(firstBtn) firstBtn.classList.add('active');
}


// --- Auto-Apply integration: default Stretch preset ---
async function applyDefaultStretchPreset(){
  try {
    if (!window.localStorage) return { skipped:true, reason:'no localStorage' };
    const raw = window.localStorage.getItem('falcon.stretch.default');
    if (!raw) return { skipped:true, reason:'no default preset set' };
    let cfg = null;
    try { cfg = JSON.parse(raw); } catch(_e) { return { skipped:true, reason:'bad preset json' }; }
    const w = parseInt(cfg.w,10), h = parseInt(cfg.h,10);
    if (!Number.isFinite(w) || !Number.isFinite(h)) return { skipped:true, reason:'missing width/height' };

    const mode = String(cfg.mode||'pc').toLowerCase();

    // Reuse the same apply helpers used by StretchLab
    if (mode === 'fortnite') {
      // Find matching Stretch preset item and run its apply steps (Fortnite INI)
      try {
        const data = await loadJSON('tweaks/stretchlab.pro.res.json');
        const items = data.items || [];
        const it = items.find(x => (x.id && cfg.presetId && x.id === cfg.presetId)) || items.find(x => {
          const s = `${x.id||''} ${x.name||''} ${x.description||''}`;
          const m = s.match(/\b(\d{3,4})\s*[xX]\s*(\d{3,4})\b/);
          return m && parseInt(m[1],10)===w && parseInt(m[2],10)===h;
        });
        if (it) {
          await runItem(it,'apply');
          return { ok:true, label:`Fortnite INI ${w}x${h}` };
        }
      } catch(_e) {}
      // fallback: apply system display
      await applyWindowsDisplayResolution(w,h);
      return { ok:true, label:`PC display ${w}x${h} (fallback)` };
    }

    if (mode === 'valorant') { await applyValorantResolution(w,h,fpsCap); return { ok:true, label:`VALORANT INI ${w}x${h}` }; }
    if (mode === 'rocket')   { await applyRocketLeagueResolution(w,h,fpsCap); return { ok:true, label:`Rocket League INI ${w}x${h}` }; }
    if (mode === 'gta5')     { await applyGtaVResolution(w,h,fpsCap); return { ok:true, label:`GTA V XML ${w}x${h}` }; }

    await applyWindowsDisplayResolution(w,h);
    return { ok:true, label:`PC display ${w}x${h}` };
  } catch (e) {
    return { error: (e && e.message) ? e.message : String(e) };
  }
}


async function renderFixes(){
  const data = await loadJSON('tweaks/fixes.modules.json');
  const items = data.items || [];
  const q = (els.searchInput.value||'').toLowerCase().trim();
  const filtered = items.filter(i => !q || i.name.toLowerCase().includes(q) || (i.description||'').toLowerCase().includes(q));
  els.panel.innerHTML = `<div class="grid"></div><div class="panel"><div class="card-title">Last action output</div><pre class="log">${__eh(lastLog||'')}</pre></div>`;
  const grid = els.panel.querySelector('.grid');
  filtered.forEach(item=>{
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <div class="card-title">${__eh(item.name)}</div>
      <div class="card-desc">${__eh(formatDescription(item.description||''))}</div>
      <div class="badges">${riskBadge(item.riskLevel || item.risk || 'Safe')}</div>
      <div class="card-actions">
        <button class="btn primary">Fix now</button>
      </div>
    `;
    card.querySelector('button').onclick = async () => {
      showRunPanel('Running: ' + item.name);
      setProgress(10, 'Executing steps...');
      const res = await window.falcon.runAction({ action:'apply', tweak:item, meta:{ label: item.name || 'Fix' } });
      setProgress(100, res && res.ok ? 'Done' : 'Failed');
      renderResult(res);
      // Ensure the output panel always updates, even if renderResult fails for some edge payload.
      try{
        lastLog = ((res && (res.stdout || res.rawStdout)) ? String(res.stdout || res.rawStdout) : '')
               + ((res && (res.stderr || res.rawStderr)) ? ('\n' + String(res.stderr || res.rawStderr)) : '');
      }catch(_e){}
      hideRunPanel();
      refresh(false);
    };
    grid.appendChild(card);
  });
}



async function renderBoostPack(){
  els.panel.innerHTML = `
    <div class="grid">
<div class="card">
        <div class="card-title">Windows Defender – Full Restore (Boost Pack recovery)</div>
        <div class="card-desc">
          Removes policy locks commonly set by DefenderControl/DControl and restores only Defender/Security Center services + scheduled tasks.
          <br><br>
          If Windows Security still shows “managed by your organization”, reboot once after running.
        </div>
        <div class="badges">${riskBadge("Warning")}</div>
        <div class="card-actions">
          <button class="btn" id="btnDefenderRestore">Run Defender Full Restore</button>
          <button class="btn" id="btnOpenSecurity">Open Windows Security</button>
        </div>
      </div>

      <div class="card">
        <div class="card-title">Notes</div>
        <div class="card-desc">
          • Boost Pack logs: <code>C:\\Boost Pack Logs</code><br>
          • Falcon logs (actions): shown in the output panel / log file when available.
        </div>
      </div>
    </div>
    <div class="panel">
      <div class="card-title">Last action output</div>
      <pre class="log">${__eh(lastLog||'')}</pre>
    </div>
  `;

  const btnLaunch = document.getElementById('btnLaunchBoostPack');
  if(btnLaunch){
    btnLaunch.onclick = async () => {
      if(!st || !st.ok || !st.installed){
        alert("Boost Pack tool files missing. Reinstall/repair Falcon Optimizer package.");
        return;
      }
    };
  }

  const btnLaunchSafe = document.getElementById('btnLaunchBoostPackSafe');
  if(btnLaunchSafe){
    btnLaunchSafe.onclick = async () => {
      if(!st || !st.ok || !st.installed){
        alert("Boost Pack Safe tool files missing. Reinstall/repair Falcon Optimizer package.");
        return;
      }
    };
  }
  const btnRestore = document.getElementById('btnDefenderRestore');
  if(btnRestore){
    btnRestore.onclick = async () => {
      showRunPanel('Running: Defender Full Restore');
      setProgress(10, 'Executing restore steps...');
      const res = await window.falcon.runAction({ steps: [{ type:'ps.file', path:'scripts/security/defender-full-restore.ps1' }] });
      hideRunPanel();
      toastRunResult('Defender Full Restore', res);
      lastLog = (res && (res.stdout || res.rawStdout) ? (res.stdout || res.rawStdout) : '') + (res && (res.stderr || res.rawStderr) ? ("\n" + (res.stderr || res.rawStderr)) : '');
      refresh(false);
    };
  }

  const btnOpen = document.getElementById('btnOpenSecurity');
  if(btnOpen){
    btnOpen.onclick = () => {
      // opens Windows Security UI
      window.falcon.runAction({ steps: [{ type:'cmd.run', command:'start "" "windowsdefender:"' }] });
      showToast('Opening Windows Security…','info');
    };
  }
}

async function renderCoolingDashboard(){
  // Dedicated cooling UI: live temp graph + fan curve presets (FanControl integration).
  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Cooling & Fan Control</div>
      <div class="card-desc">Live thermals, cooling presets, and a fan curve builder (export for FanControl). Direct BIOS/EC fan writes are vendor-specific, so Falcon provides safe OS-side controls + FanControl integration.</div>

      <div class="grid" style="grid-template-columns: 1.2fr 0.8fr; gap:14px;">
        <div class="card">
          <div class="card-title">Live thermals</div>
          <div class="card-desc">Polls available sensors and plots last ~2 minutes. If a sensor is missing on your system, it will show as N/A.</div>
          <canvas id="coolingTempCanvas" height="220" style="width:100%; border-radius:14px; background: rgba(255,255,255,0.03);"></canvas>
          <div id="coolingTempLegend" class="muted" style="margin-top:10px; line-height:1.35;"></div>
        </div>

        <div class="card">
          <div class="card-title">Cooling presets</div>
          <div class="card-desc">Safe OS-side behavior. For real fan curves, use FanControl (recommended) or vendor utilities.</div>
          <div class="row" style="gap:10px; flex-wrap:wrap; margin-top:10px;">
            <button class="btn" id="coolPresetSilent">Silent</button>
            <button class="btn" id="coolPresetBalanced">Balanced</button>
            <button class="btn primary" id="coolPresetPerf">Performance</button>
          </div>
          <div class="hint" style="margin-top:10px;">
            Silent: avoids boost spikes. Balanced: daily driver. Performance: keeps clocks high (more noise/heat).
          </div>

          <div class="divider" style="margin:14px 0;"></div>

          <div class="card-title" style="font-size:14px;">Fan curve builder</div>
          <div class="card-desc">Set % fan vs temperature. Save presets and export a simple mapping for FanControl.</div>

          <div id="fanCurveEditor" style="margin-top:10px;"></div>

          <div class="row" style="gap:10px; flex-wrap:wrap; margin-top:12px;">
            <button class="btn" id="fanPresetQuiet">Quiet curve</button>
            <button class="btn" id="fanPresetAggressive">Aggressive curve</button>
            <button class="btn" id="fanSave">Save</button>
            <button class="btn" id="fanExport">Export</button>
          </div>

          <div class="row" style="gap:10px; flex-wrap:wrap; margin-top:12px;">
            <button class="btn" id="openFanControlFolder">Open FanControl folder</button>
            <button class="btn" id="openCoolingGuide">Open cooling guide</button>
          </div>
        </div>
      </div>
    </div>
  `;

  // ---- curve state ----
  function clamp(n,min,max){ return Math.max(min, Math.min(max, n)); }
  function defaultCurve(){ return [{t:35,p:20},{t:50,p:35},{t:65,p:55},{t:75,p:75},{t:85,p:100}]; }
  let curve = defaultCurve();
  try{
    const saved = JSON.parse(localStorage.getItem('falcon.fan.curve')||'null');
    if(Array.isArray(saved) && saved.length>=3) curve = saved.map(x=>({t:clamp(parseInt(x.t,10)||0,20,100), p:clamp(parseInt(x.p,10)||0,0,100)})).sort((a,b)=>a.t-b.t);
  }catch{}

  function renderCurve(){
    const host = document.getElementById('fanCurveEditor');
    host.innerHTML = '';
    const wrap = document.createElement('div');
    wrap.className = 'fan-curve';
    wrap.innerHTML = curve.map((pt,idx)=>`
      <div class="fan-pt">
        <div class="muted">Point ${idx+1}</div>
        <div class="row" style="gap:10px; flex-wrap:wrap;">
          <label class="field-label">Temp °C
            <input class="input fan-t" type="number" min="20" max="100" step="1" value="${pt.t}" data-idx="${idx}">
          </label>
          <label class="field-label">Fan %
            <input class="input fan-p" type="number" min="0" max="100" step="1" value="${pt.p}" data-idx="${idx}">
          </label>
          <button class="btn fan-del" data-idx="${idx}" ${curve.length<=3?'disabled':''}>Remove</button>
        </div>
      </div>
    `).join('') + `
      <div class="row" style="gap:10px; flex-wrap:wrap; margin-top:10px;">
        <button class="btn" id="fanAddPoint">Add point</button>
        <button class="btn" id="fanSort">Sort by temp</button>
      </div>
    `;
    host.appendChild(wrap);

    host.querySelectorAll('input.fan-t').forEach(inp=>{
      inp.oninput=()=>{ const i=parseInt(inp.dataset.idx,10); curve[i].t=clamp(parseInt(inp.value,10)||curve[i].t,20,100); };
    });
    host.querySelectorAll('input.fan-p').forEach(inp=>{
      inp.oninput=()=>{ const i=parseInt(inp.dataset.idx,10); curve[i].p=clamp(parseInt(inp.value,10)||curve[i].p,0,100); };
    });
    host.querySelectorAll('button.fan-del').forEach(btn=>{
      btn.onclick=()=>{ const i=parseInt(btn.dataset.idx,10); if(curve.length>3){ curve.splice(i,1); renderCurve(); } };
    });
    document.getElementById('fanAddPoint').onclick=()=>{
      curve.push({t:70,p:60}); renderCurve();
    };
    document.getElementById('fanSort').onclick=()=>{
      curve.sort((a,b)=>a.t-b.t); renderCurve();
    };
  }
  renderCurve();

  document.getElementById('fanPresetQuiet').onclick=()=>{ curve=[{t:35,p:15},{t:55,p:30},{t:70,p:50},{t:80,p:70},{t:90,p:95}]; renderCurve(); toast('Quiet curve loaded.'); };
  document.getElementById('fanPresetAggressive').onclick=()=>{ curve=[{t:30,p:25},{t:45,p:45},{t:60,p:70},{t:72,p:90},{t:80,p:100}]; renderCurve(); toast('Aggressive curve loaded.'); };
  document.getElementById('fanSave').onclick=()=>{ localStorage.setItem('falcon.fan.curve', JSON.stringify(curve)); toast('Fan curve saved.'); };
  document.getElementById('fanExport').onclick=()=>{
    const payload = { curve, note: 'Import manually into FanControl: create a custom curve with these (Temp°C -> Fan%).' };
    copyTextToClipboard(JSON.stringify(payload, null, 2));
    toast('Export copied to clipboard.');
  };

  // Presets (OS-side)
  async function runPs(cmd){
    await window.falcon.runSteps({ steps: [{ type:'ps.run', command: cmd }] });
  }
  document.getElementById('coolPresetSilent').onclick=()=>runPs("powercfg /setactive SCHEME_BALANCED; powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 85; powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5; powercfg /setactive SCHEME_CURRENT");
  document.getElementById('coolPresetBalanced').onclick=()=>runPs("powercfg /setactive SCHEME_BALANCED; powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100; powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5; powercfg /setactive SCHEME_CURRENT");
  document.getElementById('coolPresetPerf').onclick=()=>runPs("powercfg /setactive SCHEME_MIN; powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100; powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100; powercfg /setactive SCHEME_CURRENT");

  document.getElementById('openFanControlFolder').onclick=()=>runPs("$p=Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\\FanControl'; if(!(Test-Path $p)){New-Item -ItemType Directory -Force -Path $p|Out-Null}; Start-Process $p");
  document.getElementById('openCoolingGuide').onclick=()=>runPs("$p=Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\\cooling.md'; if(Test-Path $p){Start-Process $p}else{Write-Output 'Cooling guide missing.'}");

  // ---- live temp graph ----
  const canvas = document.getElementById('coolingTempCanvas');
  const ctx = canvas.getContext('2d');
  const legend = document.getElementById('coolingTempLegend');

  const maxPoints = 120; // ~2 min @ 1s
  const series = {}; // name -> [temps]
  const ts = []; // timestamps (ms)

  function draw(){
    const w = canvas.width = canvas.clientWidth * (window.devicePixelRatio||1);
    const h = canvas.height = 220 * (window.devicePixelRatio||1);

    ctx.clearRect(0,0,w,h);

    // background grid
    const pad = 18 * (window.devicePixelRatio||1);
    const left = pad, top = pad, right = w-pad, bottom = h-pad;

    ctx.globalAlpha = 0.35;
    ctx.beginPath();
    for(let i=0;i<6;i++){
      const y = top + (bottom-top)*i/5;
      ctx.moveTo(left,y); ctx.lineTo(right,y);
    }
    ctx.stroke();
    ctx.globalAlpha = 1;

    // compute min/max
    let all=[];
    for(const k of Object.keys(series)){ all = all.concat(series[k].filter(v=>Number.isFinite(v))); }
    let minT = all.length ? Math.min(...all) : 20;
    let maxT = all.length ? Math.max(...all) : 100;
    minT = Math.floor(Math.min(minT, 30)/5)*5;
    maxT = Math.ceil(Math.max(maxT, 80)/5)*5;
    if(maxT-minT < 20){ maxT = minT + 20; }

    // axes labels
    ctx.globalAlpha = 0.9;
    ctx.fillText(`${maxT}°C`, left, top-6);
    ctx.fillText(`${minT}°C`, left, bottom+12);
    ctx.globalAlpha = 1;

    const keys = Object.keys(series);
    keys.forEach((k,ki)=>{
      const arr = series[k];
      ctx.beginPath();
      for(let i=0;i<arr.length;i++){
        const v = arr[i];
        if(!Number.isFinite(v)) continue;
        const x = left + (right-left) * (i/(maxPoints-1));
        const y = bottom - (bottom-top) * ((v-minT)/(maxT-minT));
        if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
      }
      ctx.stroke();
    });

    // legend
    const parts = keys.map(k=>{
      const arr=series[k]; const last = arr.length?arr[arr.length-1]:null;
      return `${k}: ${Number.isFinite(last)?(last.toFixed(0)+'°C'):'N/A'}`;
    });
    legend.textContent = parts.join('   •   ');
  }

  async function poll(){
    try{
      const payload = await window.falcon.getThermals();
      const sensors = (payload && payload.sensors) ? payload.sensors : [];
      const now = Date.now();
      ts.push(now);
      if(ts.length>maxPoints) ts.shift();

      // Keep only a few common series
      const allowed = new Set(['CPU','GPU','ThermalZone']);
      for(const s of sensors){
        const name = String(s.name||'').trim();
        const key = name || 'ThermalZone';
        if(!(key in series)) series[key]=[];
        series[key].push(Number.isFinite(s.tempC)?s.tempC:null);
        if(series[key].length>maxPoints) series[key].shift();
      }
      // Ensure stable display keys
      if(!sensors.length){
        if(!('ThermalZone' in series)) series['ThermalZone']=[];
        series['ThermalZone'].push(null);
        if(series['ThermalZone'].length>maxPoints) series['ThermalZone'].shift();
      }
      draw();
    }catch(e){
      // keep drawing with N/A
      if(!('ThermalZone' in series)) series['ThermalZone']=[];
      series['ThermalZone'].push(null);
      if(series['ThermalZone'].length>maxPoints) series['ThermalZone'].shift();
      draw();
    }
  }

  // start
  draw();
  poll();
  const iv = setInterval(poll, 1000);
  // stop polling if user navigates away
  const prevRoute = currentRoute;
  const prevTabId = currentTab && currentTab.id;
  const stopIf = setInterval(()=>{
    if(currentRoute!==prevRoute || !(currentTab && currentTab.id===prevTabId)){
      clearInterval(iv); clearInterval(stopIf);
    }
  }, 600);
}

async function renderTweaksFromSource(source){
  // Always re-sync toggle state from the main process so UI reflects the last successful apply/revert.
  // This prevents cases where a tweak applied successfully but the visual switch didn't update.
  try {
    toggles = await window.falcon.getState();
    if (!toggles || typeof toggles !== 'object') toggles = {};
  } catch(_e) {
    if (!toggles || typeof toggles !== 'object') toggles = {};
  }
  // Special routed panels
  if (source === 'tweaks/game.priority.scheduler.json') {
    buildGamePrioritySchedulerPanel();
    return;
  }
  if (source === 'tweaks/network.priority.json') {
    buildNetworkPriorityPanel();
    return;
  }
  if (source === 'tweaks/windows.power.json') {
    buildPowerPlansPanel();
    return;
  }

  const data = await loadJSON(source);

  let extraTopHtml = '';
  if (source === 'tweaks/performance.library.json') {
    extraTopHtml = `
      <div class="panel boost-toolbar">
        <div class="card-title">Presets</div>
        <div class="card-desc">Apply a fast preset baseline, then use the Library below to fine-tune. Presets run multiple actions in sequence.</div>
        <div class="boost-toolbar-actions">
          <button class="btn secondary" id="plPresetBalanced">Apply Balanced preset</button>
          <button class="btn primary" id="plPresetLatency">Apply Latency preset</button>
          <button class="btn secondary" id="plPresetFps">Apply FPS preset</button>
        </div>
        <div class="muted" style="margin-top:8px; font-size:12px;">Tip: You can still run any single optimization card below, including custom-value cards.</div>
      </div>
    `;
  }
  // Support both schemas: {items:[...]} and legacy {tweaks:[...]}.
  const rawItems = (data.items || data.tweaks || []).map((it)=>{
    if (!it.type) {
      if (it.apply && it.revert) it.type = 'toggle';
      else it.type = 'action';
    }
    return it;
  });

  // Hide "clone" cards that just hard-set Win32PrioritySeparation (keeps the single consolidated card).
  // This avoids clutter like "Sets Win32PrioritySeparation to 0x2a" scattered across pages.
  const hasPrioritySepMain = rawItems.some(it => it && it.id === 'core.set_win32_priority_sep');
  function isPrioritySepClone(it){
    if (!it || !it.apply || !Array.isArray(it.apply.steps)) return false;
    if (it.id === 'core.set_win32_priority_sep') return false;
    // Only filter if the consolidated controller exists in this catalog.
    if (!hasPrioritySepMain) return false;
    return it.apply.steps.some(st => st && st.type === 'registry.set'
      && String(st.path||'').toLowerCase() === 'hklm\system\currentcontrolset\control\prioritycontrol'
      && String(st.name||'').toLowerCase() === 'win32priorityseparation');
  }
  const filteredItems = rawItems.filter(it => !isPrioritySepClone(it));

  // De-dupe common "numbered clones" like "Export snapshot 7/8/9..." while keeping the first.
  // This prevents UI bloat when a pack accidentally contains repeated variants.
  function dedupeNumberedClones(arr){
    const seen = new Set();
    const out = [];
    for (const it of (arr||[])){
      if(!it) continue;
      const name = String(it.name||'').trim();
      const desc = String(it.description||'').trim();
      const keyName = name.replace(/\s+#?\d+\s*$/,'').replace(/\s+\d+\s*$/,'').toLowerCase();
      const keyDesc = desc.replace(/\s+/g,' ').toLowerCase();
      const key = `${keyName}::${keyDesc}`;
      if(seen.has(key)) continue;
      seen.add(key);
      out.push(it);
    }
    return out;
  }


// Inline custom-value UIs: hide variant cards when the parent controller exists in the same section.
const hiddenIds = new Set();
const idsInSection = new Set(filteredItems.map(x => x && x.id).filter(Boolean));

if (idsInSection.has('core.timer_set')) {
  [
    'pass2_timer_start_latency','pass2_timer_start_balanced','pass2_timer_start_fps','pass2_timer_start_custom',
    'pass2_timer_startup_enable_latency','pass2_timer_startup_enable_balanced','pass2_timer_startup_enable_fps','pass2_timer_startup_enable_custom',
    'core.timer_start_persistent','core.timer_stop_persistent'
  ].forEach(id => { if (idsInSection.has(id)) hiddenIds.add(id); });
}
if (idsInSection.has('core.set_win32_priority_sep')) {
  ['lib.prioritysep.fps','lib.prioritysep.latency','lib.prioritysep.balanced','lib.prioritysep.custom']
    .forEach(id => { if (idsInSection.has(id)) hiddenIds.add(id); });
}

const items = dedupeNumberedClones(filteredItems).filter(it => !hiddenIds.has(it.id));

  const q = (els.searchInput.value||'').toLowerCase().trim();
  const filtered = items.filter(i => !q || i.name.toLowerCase().includes(q) || (i.description||'').toLowerCase().includes(q));

  const isSpeedCoreSource = (source === 'tweaks/speed.boost.json' || source === 'tweaks/speed.integrity.json');
  const isGameModeSource = (source === 'tweaks/gamemode.runtime.json' || source === 'tweaks/game.mode.json');
  const isBulkSource = isSpeedCoreSource || isGameModeSource;
  const isDebloatSource = (source === 'tweaks/debloat.cleaner.json' || source === 'tweaks/debloat.services.json' || source === 'tweaks/debloat.tasks.json' || source === 'tweaks/debloat.autoruns.json' || source === 'tweaks/debloat.uninstall.json');

  let gmSelectedIds = new Set();
  if (isGameModeSource) {
    try {
      if (window.localStorage) {
        const raw = window.localStorage.getItem('falcon.gm.selected');
        if (raw) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr)) gmSelectedIds = new Set(arr);
        }
      }
    } catch(_e) {}
  }

  const detailsPanelHtml = `
    <div class="panel">
      <div class="card-title">Tweak details</div>
      <div class="card-desc">Inspect steps, commands, and last output for an individual tweak. Use the "View" button on supported cards.</div>
      <pre class="log" id="tweakDetails">${__eh(lastLog ? '' : 'Select a tweak with View to preview its details.')}</pre>
    </div>
    <div class="panel">
      <div class="card-title">Last action output</div>
      <div class="card-desc">Most recent PowerShell output</div>
      <pre class="log" id="lastLogBody">${__eh(lastLog||'')}</pre>
    </div>
  `;

  let toolbarHtml = '';
  if (isSpeedCoreSource) {
    toolbarHtml = `
      <div class="panel boost-toolbar">
        <div class="card-title">Speed Core – batch optimizations</div>
        <div class="card-desc">Select multiple deep latency / scheduler optimizations and run them together. These tweaks are advanced and focus purely on performance.</div>
        <div class="boost-toolbar-actions">
          <button class="btn secondary" id="boostSelectAll">Select all Speed Core optimizations</button>
          <button class="btn primary" id="boostRunBtn">Run selected Speed Core optimizations</button>
        </div>
      </div>
    `;
  } else if (isGameModeSource) {
    toolbarHtml = `
      <div class="panel boost-toolbar">
        <div class="card-title">Game Mode – build your own preset</div>
        <div class="card-desc">Select exactly which runtime optimizations you want, then <b>Start</b> to apply them. Use <b>Stop</b> to revert whatever can be safely reverted (items without a revert step will be left as-is).</div>
        <div class="boost-toolbar-actions">
          <button class="btn secondary" id="gmSelectAll">Select all</button>
          <button class="btn primary" id="gmStart">Start Game Mode</button>
          <button class="btn" id="gmStop">Stop Game Mode</button>
        </div>
      </div>
    `;
    if (source === 'tweaks/gamemode.runtime.json') {
      toolbarHtml += `
        <div class="panel" id="gmPhotoPanel">
          <div class="card-title">Game Mode – photo optimizations</div>
          <div class="card-desc">Optional visual helpers you can tie into Game Mode. Select which photo/display tweaks you want included when running Game Mode batch.</div>
          <div class="gm-photo-list" id="gmPhotoList"></div>
        </div>
      `;
    }
  }


  else if (isDebloatSource) {
    // Debloat packs: choose which packs to run, then run every item in the selected packs.
    toolbarHtml = `
      <div class="panel boost-toolbar">
        <div class="card-title">Debloat – batch packs</div>
        <div class="card-desc">Select the packs you want to run. Falcon will execute every optimization in the selected packs (apply only), in a safe order.</div>
        <div class="debloat-pack-list" style="display:flex; gap:12px; flex-wrap:wrap; margin-top:10px;">
          <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
            <input type="checkbox" class="db-pack" data-pack="cleaner" /> System Cleaner
          </label>
          <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
            <input type="checkbox" class="db-pack" data-pack="services" /> Services
          </label>
          <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
            <input type="checkbox" class="db-pack" data-pack="tasks" /> Tasks
          </label>
          <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
            <input type="checkbox" class="db-pack" data-pack="autoruns" /> Autoruns
          </label>
          <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
            <input type="checkbox" class="db-pack" data-pack="uninstall" /> Uninstall (aggressive)
          </label>
        </div>
        <div class="boost-toolbar-actions" style="margin-top:10px;">
          <button class="btn secondary" id="dbSelectAllPacks">Select all packs</button>
          <button class="btn primary" id="dbRunPacks">Run selected debloat packs</button>
        </div>
        <div class="muted" style="margin-top:8px; font-size:12px;">Tip: Start with Cleaner/Tasks/Autoruns. Only add Uninstall if you understand what it removes.</div>
      </div>
    `;
  }

  els.panel.innerHTML = `
    ${toolbarHtml}
    ${extraTopHtml}
    <div class="grid" id="grid"></div>
    ${detailsPanelHtml}
  `;

  const grid = document.getElementById('grid');
  // Performance Library presets
  if (source === 'tweaks/performance.library.json') {
    const byId = new Map(items.map(it => [it.id, it]));
    async function runPreset(ids){
      let okCount=0;
      for (const id of ids){
        const it = byId.get(id);
        if (!it) continue;
        try{
          const applySteps = getApplyStepsWithVerify(it);
          const revertSteps = getStepsFor(it, 'revert');
          const res = await runTweakWithTimeout({ id: it.id, mode:'apply', steps: applySteps, revertSteps, meta:{ riskLevel: normRisk(it), from:'Preset' } }, 120000);
          if(res && res.ok) okCount++;
          lastLog = (res.stdout||'') + (res.stderr||'');
          const logEl = document.getElementById('lastLogBody');
          if (logEl) logEl.textContent = lastLog;
        }catch(e){
          showToast('Preset step failed: ' + id, 'error');
        }
      }
      showToast('Preset finished ('+okCount+'/'+ids.length+').', 'success');
      refresh(false);
    }
    const btnB = document.getElementById('plPresetBalanced');
    const btnL = document.getElementById('plPresetLatency');
    const btnF = document.getElementById('plPresetFps');
    if (btnB) btnB.onclick = ()=> runPreset([
      'lib.prioritysep.balanced',
      'core_bcd_disable_dynamic_tick',
      'exp.boot.reset_timer_flags'
    ]);
    if (btnL) btnL.onclick = ()=> runPreset([
      'lib.prioritysep.latency',
      'core_bcd_disable_dynamic_tick',
      'exp.boot.useplatformclock_off',
      'exp.boot.reset_timer_flags'
    ]);
    if (btnF) btnF.onclick = ()=> runPreset([
      'lib.prioritysep.fps',
      'core_bcd_disable_dynamic_tick',
      'exp.boot.reset_timer_flags'
    ]);
  }

  const bulkHandlers = isBulkSource ? {} : null;

  if (source === "tweaks/game.specific.json") {
    // Lightweight per-title helper banner.
    buildGameDetectionBanner(grid);
  }

  if (isGameModeSource) {
    // Build Game Mode photo optimizations panel and helper.
    const photoPanel = document.getElementById('gmPhotoPanel');
    const photoHost = document.getElementById('gmPhotoList');
    if (source === 'tweaks/gamemode.runtime.json' && photoPanel && photoHost && Array.isArray(gameModePhotoOptimizations) && gameModePhotoOptimizations.length) {
      const selectedIds = new Set(loadGameModePhotoSelection());
      photoHost.innerHTML = '';
      gameModePhotoOptimizations.forEach((opt) => {
        const row = document.createElement('label');
        row.className = 'gm-photo-item';
        const checked = selectedIds.has(opt.id);
        row.innerHTML = `
          <input type="checkbox" class="gm-photo-select" data-id="${__eh(opt.id)}" ${checked ? 'checked' : ''} />
          <div>
            <div class="gm-photo-item-title">${__eh(opt.name)}</div>
            <div class="gm-photo-item-desc">${__eh(opt.description || '')}</div>
          </div>
        `;
        photoHost.appendChild(row);
      });

      const persistSelection = () => {
        const boxes = Array.from(document.querySelectorAll('.gm-photo-select'));
        const enabled = new Set();
        boxes.forEach((b) => {
          if (b.checked) {
            const id = b.getAttribute('data-id');
            if (id) enabled.add(id);
          }
        });
        saveGameModePhotoSelection(enabled);
      };

      photoHost.addEventListener('change', persistSelection);

      window.__falconRunSelectedGameModePhotos = async function() {
        const boxes = Array.from(document.querySelectorAll('.gm-photo-select')).filter((b) => b.checked);
        if (!boxes.length) return 0;
        let applied = 0;
        for (const box of boxes) {
          const id = box.getAttribute('data-id');
          const opt = gameModePhotoOptimizations.find((o) => o.id === id);
          if (!opt || !Array.isArray(opt.steps) || !opt.steps.length) continue;
          try {
            const res = await runTweakWithTimeout({
              id: opt.id,
              mode: 'apply',
              steps: opt.steps,
              revertSteps: [],
              meta: { riskLevel: opt.riskLevel || 'Safe', from: 'GameModePhoto' }
            }, 90000);
            if (res && res.ok) applied++;
            lastLog = ((res && (res.stdout || res.stderr)) || '') || lastLog;
            const logEl = document.getElementById('lastLogBody');
            if (logEl && res) logEl.textContent = (res.stdout || '') + (res.stderr || '');
          } catch (e) {
            // keep going on errors
          }
        }
        return applied;
      };
    } else {
      // No photo panel on this view; provide a no-op helper so callers can safely await it.
      window.__falconRunSelectedGameModePhotos = async function() { return 0; };
    }
  }

  // Rendering many cards at once can cause jank. Render in small batches.
  
  // Inline controllers for cards that have expanded panels (custom value creators, helpers, etc.)
  function attachInlineControllers(card, item, isOn){
    try{
      if(!card || !item) return;

      // Timer resolution helper (core.timer_set)
      if(item.id === 'core.timer_set'){
        const pill = card.querySelector('[data-timer-status]');
        const sel  = card.querySelector('[data-timer-preset]');
        const inp  = card.querySelector('[data-timer-custom]');
        const btnStart = card.querySelector('[data-timer-start]');
        const btnStop  = card.querySelector('[data-timer-stop]');
        const btnInstall = card.querySelector('[data-timer-install]');
        const btnRemove  = card.querySelector('[data-timer-remove]');

        const getUs = () => {
          const v = sel ? String(sel.value || '') : '';
          if (v.toLowerCase() === 'custom') {
            const raw = inp ? String(inp.value || inp.placeholder || '').trim() : '';
            const n = parseInt(raw, 10);
            return (Number.isFinite(n) && n > 0) ? n : 5000;
          }
          const n = parseInt(v, 10);
          return (Number.isFinite(n) && n > 0) ? n : 5000;
        };

        const setPill = (s) => { if(pill) pill.textContent = s; };

        const refreshStatus = async () => {
          try{
            const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/timer-control.ps1', args:{ Action:'status' } }]);
            const out = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
            if(out.startsWith('RUNNING')) setPill('Status: RUNNING');
            else if(out.startsWith('STOPPED')) setPill('Status: STOPPED');
            else setPill('Status: …');
          }catch(_e){ setPill('Status: …'); }
        };

        if(sel){
          sel.addEventListener('change', ()=>{
            // keep input editable; when preset chosen, hint with that value
            try{
              if(String(sel.value).toLowerCase() !== 'custom' && inp){
                inp.value = '';
                inp.placeholder = String(sel.value);
              }
            }catch(_e){}
          });
        }

        if(btnStart){
          btnStart.onclick = async () => {
            const us = getUs();
            setPill('Status: starting…');
            await window.falcon.runSteps([{ type:'ps.file', path:'scripts/timer-control.ps1', args:{ Action:'start', Resolution: us } }]);
            await refreshStatus();
          };
        }
        if(btnStop){
          btnStop.onclick = async () => {
            setPill('Status: stopping…');
            await window.falcon.runSteps([{ type:'ps.file', path:'scripts/timer-control.ps1', args:{ Action:'stop' } }]);
            await refreshStatus();
          };
        }
        if(btnInstall){
          btnInstall.onclick = async () => {
            const us = getUs();
            await window.falcon.runSteps([{ type:'ps.file', path:'scripts/timer-control.ps1', args:{ Action:'installTask', Resolution: us } }]);
            showToast('Startup timer task installed');
          };
        }
        if(btnRemove){
          btnRemove.onclick = async () => {
            await window.falcon.runSteps([{ type:'ps.file', path:'scripts/timer-control.ps1', args:{ Action:'removeTask' } }]);
            showToast('Startup timer task removed');
          };
        }

        // initial status (only when panel is visible)
        if(isOn) setTimeout(()=>refreshStatus(), 0);
      }

      // Guided Controller Overclock (Polling Rate)
      if(item.id === 'exp.usb.controller_overclock'){
        const pill = card.querySelector('[data-co-status]');
        const selDev = card.querySelector('[data-co-dev]');
        const selRate = card.querySelector('[data-co-rate]');
        const chkWin11 = card.querySelector('[data-co-win11]');
        const btnRefresh = card.querySelector('[data-co-refresh]');
        const btnApply = card.querySelector('[data-co-apply]');
        const btnRevert = card.querySelector('[data-co-revert]');

        const setPill = (s)=>{ if(pill) pill.textContent = s; };

        const loadDevices = async ()=>{
          try{
            setPill('Status: scanning…');
            const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/controller-overclock.ps1', args:{ Action:'list' } }]);
            const raw = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
            const obj = raw ? JSON.parse(raw) : null;
            const devs = (obj && obj.ok && Array.isArray(obj.devices)) ? obj.devices : [];
            if(selDev){
              selDev.innerHTML = '';
              devs.forEach(d=>{
                const opt = document.createElement('option');
                opt.value = d.instanceId;
                opt.textContent = `${d.name} (${d.type || 'Other'})`;
                selDev.appendChild(opt);
              });
            }
            setPill(devs.length ? `Status: ready (${devs.length} found)` : 'Status: no controllers found');
          }catch(e){
            setPill('Status: error');
          }
        };

        if(btnRefresh){ btnRefresh.onclick = loadDevices; }

        if(btnApply){
          btnApply.onclick = async ()=>{
            try{
              const id = selDev ? String(selDev.value||'') : '';
              const hz = selRate ? parseInt(String(selRate.value||'1000'), 10) : 1000;
              const win11 = !!(chkWin11 && chkWin11.checked);
              if(!id){ showToast('Select a controller first'); return; }
              setPill('Status: applying…');
              const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/controller-overclock.ps1', args:{ Action:'apply', InstanceId:id, RateHz: hz, Win11Fix: win11 } }]);
              const raw = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
              const obj = raw ? JSON.parse(raw) : null;
              if(obj && obj.ok){
                setPill(obj.deviceRestarted ? 'Status: applied (device restarted)' : 'Status: applied (replug/reboot if needed)');
                showToast('Applied controller polling rate');
              } else {
                setPill('Status: failed');
                showToast((obj && obj.error) ? obj.error : 'Apply failed');
              }
            }catch(_e){
              setPill('Status: failed');
            }
          };
        }

        if(btnRevert){
          btnRevert.onclick = async ()=>{
            try{
              const id = selDev ? String(selDev.value||'') : '';
              if(!id){ showToast('Select a controller first'); return; }
              setPill('Status: reverting…');
              const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/controller-overclock.ps1', args:{ Action:'revert', InstanceId:id } }]);
              const raw = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
              const obj = raw ? JSON.parse(raw) : null;
              if(obj && obj.ok){
                setPill(obj.deviceRestarted ? 'Status: reverted (device restarted)' : 'Status: reverted');
                showToast('Reverted controller overclock');
              } else {
                setPill('Status: failed');
                showToast((obj && obj.error) ? obj.error : 'Revert failed');
              }
            }catch(_e){
              setPill('Status: failed');
            }
          };
        }

        if(isOn) setTimeout(()=>loadDevices(), 0);
      }

      // Guided MSI Mode (GPU + Audio)
      if(item.id === 'adv.msi.auto_gpu_audio'){
        const pill = card.querySelector('[data-msi-status]');
        const list = card.querySelector('[data-msi-list]');
        const btnRefresh = card.querySelector('[data-msi-refresh]');
        const btnApply = card.querySelector('[data-msi-apply]');
        const btnRevert = card.querySelector('[data-msi-revert]');

        const setPill = (s)=>{ if(pill) pill.textContent = s; };

        const renderList = (devs)=>{
          if(!list) return;
          list.innerHTML = '';
          devs.forEach(d=>{
            const row = document.createElement('label');
            row.className = 'row';
            row.style.gap = '10px';
            row.style.alignItems = 'center';
            row.style.margin = '6px 0';
            const cb = document.createElement('input');
            cb.type = 'checkbox';
            cb.checked = true;
            cb.dataset.instanceId = d.instanceId;
            const sp = document.createElement('span');
            sp.textContent = `${d.name || d.instanceId} (${d.pnpClass || ''})`;
            row.appendChild(cb); row.appendChild(sp);
            list.appendChild(row);
          });
        };

        const load = async ()=>{
          try{
            setPill('Status: scanning…');
            const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/msi-mode.ps1', args:{ Action:'list', Class:'Display', IncludeAudio:true } }]);
            const raw = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
            const obj = raw ? JSON.parse(raw) : null;
            const devs = (obj && obj.ok && Array.isArray(obj.devices)) ? obj.devices : [];
            renderList(devs);
            setPill(devs.length ? `Status: ready (${devs.length} supported)` : 'Status: no MSI-capable devices found');
          }catch(_e){ setPill('Status: error'); }
        };

        const getSelected = ()=>{
          if(!list) return [];
          const ids = [];
          list.querySelectorAll('input[type="checkbox"]').forEach(cb=>{
            if(cb.checked && cb.dataset.instanceId) ids.push(cb.dataset.instanceId);
          });
          return ids;
        };

        if(btnRefresh) btnRefresh.onclick = load;
        if(btnApply){
          btnApply.onclick = async ()=>{
            const ids = getSelected();
            if(!ids.length){ showToast('Select at least one device'); return; }
            setPill('Status: applying…');
            const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/msi-mode.ps1', args:{ Action:'apply', Class:'Display', IncludeAudio:true, InstanceIds: ids } }]);
            const raw = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
            const obj = raw ? JSON.parse(raw) : null;
            if(obj && obj.ok){
              setPill('Status: applied (reboot required)');
              showToast('MSI Mode applied (reboot required)');
            } else {
              setPill('Status: failed');
              showToast((obj && obj.error) ? obj.error : 'Apply failed');
            }
          };
        }
        if(btnRevert){
          btnRevert.onclick = async ()=>{
            const ids = getSelected();
            if(!ids.length){ showToast('Select at least one device'); return; }
            setPill('Status: reverting…');
            const res = await window.falcon.runSteps([{ type:'ps.file', path:'scripts/msi-mode.ps1', args:{ Action:'revert', Class:'Display', IncludeAudio:true, InstanceIds: ids } }]);
            const raw = (res && (res.stdout || res.rawStdout || '')) ? String(res.stdout || res.rawStdout).trim() : '';
            const obj = raw ? JSON.parse(raw) : null;
            if(obj && obj.ok){
              setPill('Status: reverted (reboot required)');
              showToast('MSI Mode reverted (reboot required)');
            } else {
              setPill('Status: failed');
              showToast((obj && obj.error) ? obj.error : 'Revert failed');
            }
          };
        }

        if(isOn) setTimeout(()=>load(), 0);
      }

      // Priority Separation custom value helper (core.set_win32_priority_sep)
      if(item.id === 'core.set_win32_priority_sep'){
        const sel = card.querySelector('[data-ps-mode]');
        const inp = card.querySelector('[data-ps-custom]');
        if(sel && inp){
          const presetToHex = (m)=>{
            const mode = String(m||'balanced').toLowerCase();
            if(mode === 'latency') return '0x24';
            if(mode === 'fps') return '0x2A';
            return '0x26';
          };
          const sync = ()=>{
            try{
              const mode = String(sel.value||'balanced').toLowerCase();
              if(mode !== 'custom'){
                inp.value = presetToHex(mode);
              } else {
                if(!String(inp.value||'').trim()) inp.value = '0x26';
              }
            }catch(_e){}
          };
          sel.addEventListener('change', sync);
          // initialize
          setTimeout(sync, 0);
        }
      }
    }catch(_e){}
  }

const buildCard = (item) => {
    const isToggle = item.type === 'toggle';
    const isOn = !!toggles[item.id];
    const hasApply = !!(item && item.apply && Array.isArray(item.apply.steps) && item.apply.steps.length);
    const primaryLabel = isToggle
      ? (isOn ? 'Revert' : 'Apply')
      : (item.primaryLabel || 'Run');
    const isViewPrimary = (primaryLabel || '').toLowerCase() === 'view';
    const isViewSecondary = item.secondaryAction && (item.secondaryAction.label || '').toLowerCase() === 'view';

    const card = document.createElement('div');
    card.className = isBulkSource ? 'card speedboost-card' : 'card';
    const preChecked = (isGameModeSource && item.id && gmSelectedIds.has(item.id));
    const selectHtml = (isBulkSource ? `<label class="boost-check"><input type="checkbox" class="boost-select" data-id="${__eh(item.id || '')}" ${preChecked ? 'checked' : ''} /></label>` : '');
    const showToggle = isToggle && !isBulkSource;
    const safeName = item.name || item.id || '(unnamed tweak)';
    
const safeDesc = item.description || '';
let inlineHtml = '';
if (item && item.id === 'core.timer_set') {
  inlineHtml = `
    <div class="inline-panel" data-inline="timer" style="margin-top:10px; display:${isOn?'block':'none'};">
      <div class="row" style="gap:10px; align-items:center; flex-wrap:wrap;">
        <span class="pill" data-timer-status>Status: …</span>
        <label class="field" style="min-width:200px;">
          <span class="field-label">Preset</span>
          <select class="select" data-timer-preset>
            <option value="5000">0.5 ms (5000 µs)</option>
            <option value="5040">0.504 ms (5040 µs)</option>
            <option value="5070">0.507 ms (5070 µs)</option>
            <option value="custom">Custom</option>
          </select>
        </label>
        <label class="field" style="min-width:160px;">
          <span class="field-label">Custom (µs)</span>
          <input class="input" data-timer-custom type="number" min="1000" step="10" placeholder="5000" />
        </label>

        <button class="btn" data-timer-start>Start</button>
        <button class="btn" data-timer-stop>Stop</button>
        <button class="btn" data-timer-install>Enable startup</button>
        <button class="btn" data-timer-remove>Disable startup</button>
      </div>
      <div class="muted" style="margin-top:8px; font-size:12px; line-height:1.3;">
        Tip: Pick a preset (or custom µs), then press <b>Start</b>. Turning this optimization on/off uses the chosen value.
      </div>
    </div>
  `;
} else if (item && item.id === 'exp.usb.controller_overclock') {
  inlineHtml = `
    <div class="inline-panel" data-inline="controlleroc" style="margin-top:10px; display:${isOn?'block':'none'};">
      <div class="row" style="gap:10px; align-items:center; flex-wrap:wrap;">
        <span class="pill" data-co-status>Status: …</span>
        <label class="field" style="min-width:320px;">
          <span class="field-label">Controller</span>
          <select class="select" data-co-dev></select>
        </label>
        <label class="field" style="min-width:200px;">
          <span class="field-label">Polling rate</span>
          <select class="select" data-co-rate>
            <option value="125">125 Hz (default-ish)</option>
            <option value="250">250 Hz</option>
            <option value="500">500 Hz</option>
            <option value="1000" selected>1000 Hz (recommended PS4/PS5)</option>
            <option value="2000">2000 Hz (DualSense only, experimental)</option>
            <option value="4000">4000 Hz (DualSense only, experimental)</option>
            <option value="8000">8000 Hz (DualSense only, experimental)</option>
          </select>
        </label>
        <label class="row" style="gap:8px; align-items:center;">
          <input type="checkbox" data-co-win11 />
          <span class="muted" style="font-size:12px;">Windows 11 driver-load fix (Error 577/secure boot situations)</span>
        </label>
        <button class="btn" data-co-refresh>Refresh</button>
        <button class="btn" data-co-apply>Apply</button>
        <button class="btn" data-co-revert>Revert</button>
      </div>
      <div class="muted" style="margin-top:8px; font-size:12px; line-height:1.3;">
        Notes: Xbox controllers often cannot truly overclock due to firmware locks. After apply/revert, unplug/replug the controller or reboot if it doesn’t reconnect.
      </div>
    </div>
  `;
} else if (item && item.id === 'adv.msi.auto_gpu_audio') {
  inlineHtml = `
    <div class="inline-panel" data-inline="msiguide" style="margin-top:10px; display:${isOn?'block':'none'};">
      <div class="row" style="gap:10px; align-items:center; flex-wrap:wrap;">
        <span class="pill" data-msi-status>Status: …</span>
        <button class="btn" data-msi-refresh>Refresh</button>
        <button class="btn" data-msi-apply>Apply selected</button>
        <button class="btn" data-msi-revert>Revert selected</button>
      </div>
      <div data-msi-list style="margin-top:10px;"></div>
      <div class="muted" style="margin-top:8px; font-size:12px; line-height:1.3;">
        This only lists devices that already expose MSI support in the registry (avoids line-based devices). Reboot required after apply/revert.
      </div>
    </div>
  `;
} else if (item && item.id === 'core.set_win32_priority_sep') {
  inlineHtml = `
    <div class="inline-panel" data-inline="prioritysep" style="margin-top:10px; display:${isOn?'block':'none'};">
      <div class="row" style="gap:10px; align-items:flex-end; flex-wrap:wrap;">
        <label class="field" style="min-width:220px;">
          <span class="field-label">Preset</span>
          <select class="select" data-ps-mode>
            <option value="balanced">Balanced</option>
            <option value="latency">Latency</option>
            <option value="fps">FPS</option>
            <option value="custom">Custom</option>
          </select>
        </label>
        <label class="field" style="min-width:180px;">
          <span class="field-label">Custom (decimal or hex)</span>
          <input class="input" data-ps-custom placeholder="e.g. 38 or 0x26" />
        </label>
        <div class="muted" style="font-size:12px; margin-bottom:2px; line-height:1.25;">Values: Balanced <b>0x26</b> (default-like), Latency <b>0x24</b> (more foreground/input bias), FPS <b>0x2A</b> (more throughput/longer slices). Custom accepts decimal or hex.</div>
      </div>
    </div>
  `;
}


if (item && item.id === 'pass2_bcd_apply_custom') {
  inlineHtml = `
    <div class="inline-panel" data-inline="bcd" style="margin-top:10px; display:${isOn?'block':'none'};">
      <div class="row" style="gap:10px; align-items:center; flex-wrap:wrap;">
        <label class="small-muted">BCDEdit preset</label>
        <select class="select" data-bcd-mode>
          <option value="latency">Latency</option>
          <option value="balanced">Balanced</option>
          <option value="fps">FPS</option>
          <option value="custom">Custom</option>
        </select>
        <button class="btn secondary" data-bcd-open type="button">Open Overrides</button>
      </div>

      <div class="row" data-bcd-custom style="margin-top:10px; gap:16px; align-items:center; flex-wrap:wrap; display:none;">
        <label class="chk"><input type="checkbox" data-bcd-ddt /> DisableDynamicTick</label>
        <label class="chk"><input type="checkbox" data-bcd-upt /> UsePlatformTick</label>
        <label class="chk"><input type="checkbox" data-bcd-upc /> UsePlatformClock</label>
        <span class="small-muted">Unchecked = "no" (removes the key)</span>
      </div>
    </div>
  `;
}

if (item && item.id === 'pl.net.custom.apply') {
  inlineHtml = `
    <div class="inline-panel" data-inline="netcustom" style="margin-top:10px;">
      <div class="row" style="gap:10px; align-items:center; flex-wrap:wrap;">
        <label class="small-muted">TCP autotuning</label>
        <select class="select" data-net-aut>
          <option value="disabled">disabled</option>
          <option value="highlyrestricted">highlyrestricted</option>
          <option value="restricted">restricted</option>
          <option value="normal" selected>normal</option>
          <option value="experimental">experimental</option>
        </select>

        <label class="small-muted">ECN</label>
        <select class="select" data-net-ecn>
          <option value="disabled" selected>disabled</option>
          <option value="enabled">enabled</option>
        </select>

        <label class="small-muted">Timestamps</label>
        <select class="select" data-net-ts>
          <option value="disabled" selected>disabled</option>
          <option value="enabled">enabled</option>
        </select>

        <label class="small-muted">RSS</label>
        <select class="select" data-net-rss>
          <option value="enabled" selected>enabled</option>
          <option value="disabled">disabled</option>
        </select>

        <button class="btn secondary" data-net-open type="button">Open Overrides</button>
      </div>
      <div class="small-muted" style="margin-top:6px;">These values apply when you press Apply on this card.</div>
    </div>
  `;
}

if (item && item.id === 'mem_pagefile_custom_4096_16384') {
  inlineHtml = `
    <div class="inline-panel" data-inline="pagefile" style="margin-top:10px; display:${isOn?'block':'none'};">
      <div class="row" style="gap:10px; align-items:center; flex-wrap:wrap;">
        <label class="small-muted">Preset</label>
        <select class="select" data-pf-preset>
          <option value="4096,16384" selected>Custom: 4096 / 16384 MB</option>
          <option value="8192,16384">Custom: 8192 / 16384 MB</option>
          <option value="16384,16384">Custom: 16384 / 16384 MB</option>
          <option value="custom">Custom values…</option>
        </select>

        <label class="small-muted">Min (MB)</label>
        <input class="input" type="number" min="256" step="256" value="4096" data-pf-min style="width:120px;" />
        <label class="small-muted">Max (MB)</label>
        <input class="input" type="number" min="256" step="256" value="16384" data-pf-max style="width:120px;" />
      </div>
      <div class="small-muted" style="margin-top:6px;">Turning this ON applies the selected Min/Max. Reboot required.</div>
    </div>
  `;
}

card.innerHTML = `

      ${selectHtml}
      <div class="card-title">${__eh(safeName)}</div>
      <div class="card-desc">${__eh(formatDescription(safeDesc||''))}</div>
      <div class="badges">
        ${riskBadge(item.riskLevel || item.risk || 'Safe')}
        ${item.requiresReboot ? `<span class="badge">Reboot</span>` : ``}
      </div>
      ${showToggle ? `
        <label class="fo-switch" title="Toggle">
          <input class="fo-switch-input" type="checkbox" ${isOn ? 'checked' : ''} />
          <span class="fo-switch-track"><span class="fo-switch-thumb"></span></span>
        </label>
      ` : ``}
      ${inlineHtml}
      <div class="card-actions">
        <button class="btn primary">${__eh(primaryLabel)}</button>
        ${item.secondaryAction ? `<button class="btn">${__eh(item.secondaryAction.label)}</button>` : ``}
      </div>
    `;

    // For Speed Core / Game Mode bulk sources, allow clicking the whole card to toggle the checkbox
    if (isBulkSource) {
      const checkbox = card.querySelector('.boost-select');
      if (checkbox) {
        card.addEventListener('click', (ev) => {
          // Ignore clicks on actual buttons inside the card
          const target = ev.target;
          if (target.closest && target.closest('.card-actions')) return;
          checkbox.checked = !checkbox.checked;
        });
      }
    }

    try{ attachInlineControllers(card, item, isOn); }catch(_e){}

    async function run(action, opts){
      const skipRefresh = !!(opts && opts.skipRefresh);
      // Fast-path for UI actions that just open a URL or a folder/file.
      if(item.type !== 'toggle'){
        const steps = (item.apply && item.apply.steps) ? item.apply.steps : [];
        if(steps.length === 1 && steps[0].type === 'open.url' && steps[0].url){
          await window.falcon.openExternal(steps[0].url);
          lastLog = 'Opened: ' + steps[0].url;
          const logEl = document.getElementById('lastLogBody');
          if (logEl) logEl.textContent = lastLog;
          if(!skipRefresh) return refresh(false);
          return;
        }
        if(steps.length === 1 && steps[0].type === 'open.path' && steps[0].path){
          await window.falcon.openPath(steps[0].path);
          lastLog = 'Opened: ' + steps[0].path;
          const logEl = document.getElementById('lastLogBody');
          if (logEl) logEl.textContent = lastLog;
          if(!skipRefresh) return refresh(false);
          return;
        }
      }
      // Safety gating
      const risk = normRisk(item);
      if (itemRequiresAggressiveConsent(item)) {
        const accepted = await ensureAggressiveConsent("tweak");
        if (!accepted) return;
      }
      const needsConfirm = isHighOrCritical(risk) || item.requiresSnapshot || item.requireExplicitConfirm || item.excludeFromApplyAll;
      if(needsConfirm){
        const ok = await showConfirmModal({
          title: item.warningTitle || (risk === "Critical" ? "CRITICAL ACTION" : "Warning"),
          body: item.warningBody || item.description || item.name,
          risk,
          requireTyped: !!item.requireExplicitConfirm || risk==="Critical"
        });
        if(!ok) return;
      }

      if(item.requiresSnapshot){
        const snap = await window.falcon.createBackup({});
        if(!snap.ok){
          lastLog = "Snapshot failed; action blocked.\n" + (snap.stdout||'') + "\n" + (snap.stderr||'');
          const logEl = document.getElementById('lastLogBody');
          if (logEl) logEl.textContent = lastLog;
          return refresh(false);
        }
      }


const applySteps = getStepsFor(item, action === "revert" ? "revert" : "apply");

// Inline custom controllers (timer + priority separation)
if (action === "apply" && item && item.id === "core.timer_set") {
  try {
    const preset = card.querySelector('[data-timer-preset]');
    const custom = card.querySelector('[data-timer-custom]');
    let us = 5000;
    if (preset) {
      if (String(preset.value||'').toLowerCase() === 'custom') {
        const raw = String((custom && (custom.value || custom.placeholder)) ? (custom.value || custom.placeholder) : '5000').trim();
        const n = parseInt(raw, 10);
        us = (Number.isFinite(n) && n > 0) ? n : 5000;
      } else {
        const n = parseInt(String(preset.value||'5000'), 10);
        us = (Number.isFinite(n) && n > 0) ? n : 5000;
      }
    }
    // Ensure the apply payload carries the selected microseconds to the backend runner.
    applySteps.length = 0;
    applySteps.push({ type: 'timer.set', microseconds: us });
  } catch(_e) {}
}


if (action === "apply" && item && item.id === "core.set_win32_priority_sep") {
  try {
    const modeSel = card.querySelector('[data-ps-mode]');
    const custom = card.querySelector('[data-ps-custom]');
    let val = 38; // Balanced (0x26)
    const mode = modeSel ? String(modeSel.value || 'balanced').toLowerCase() : 'balanced';
    if (mode === 'latency') val = 36;       // 0x24
    else if (mode === 'fps') val = 42;      // 0x2A
    else if (mode === 'custom') {
      const raw = String((custom && custom.value) ? custom.value : '').trim();
      if (raw) {
        if (/^0x[0-9a-f]+$/i.test(raw)) val = parseInt(raw, 16);
        else val = parseInt(raw, 10);
      }
    }
    if (!isFinite(val) || val < 0) val = 38;
    // Replace apply steps with selected value (keeps the same target key).
    applySteps.length = 0;
    applySteps.push({
      type: 'registry.set',
      path: 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\PriorityControl',
      name: 'Win32PrioritySeparation',
      value: val,
      valueType: 'DWord'
    });
  } catch(_e) {}
}

// More inline custom controllers (BCDEdit + Network custom + Pagefile)
if (action === "apply" && item && item.id === "pass2_bcd_apply_custom") {
  try {
    const modeSel = card.querySelector('[data-bcd-mode]');
    const chkDDT = card.querySelector('[data-bcd-ddt]');
    const chkUPT = card.querySelector('[data-bcd-upt]');
    const chkUPC = card.querySelector('[data-bcd-upc]');
    const mode = modeSel ? String(modeSel.value || 'latency').toLowerCase() : 'latency';

    let ddt = "yes", upt = "yes", upc = "no"; // latency defaults
    if (mode === 'fps') { ddt="no"; upt="no"; upc="no"; }
    else if (mode === 'balanced') { ddt="yes"; upt="no"; upc="no"; }
    else if (mode === 'custom') {
      ddt = (chkDDT && chkDDT.checked) ? "yes" : "no";
      upt = (chkUPT && chkUPT.checked) ? "yes" : "no";
      upc = (chkUPC && chkUPC.checked) ? "yes" : "no";
    }

    if (window.falcon && window.falcon.setLatencyOverrides) {
      await window.falcon.setLatencyOverrides({ bcdedit: { disabledynamictick: ddt, useplatformtick: upt, useplatformclock: upc } });
    }
    // Keep the existing apply steps (script reads overrides and applies). No step replacement needed.
  } catch(_e) {}
}

if (action === "apply" && item && item.id === "pl.net.custom.apply") {
  try {
    const aut = card.querySelector('[data-net-aut]');
    const ecn = card.querySelector('[data-net-ecn]');
    const ts  = card.querySelector('[data-net-ts]');
    const rss = card.querySelector('[data-net-rss]');
    const vAut = aut ? String(aut.value || 'normal') : 'normal';
    const vEcn = ecn ? String(ecn.value || 'disabled') : 'disabled';
    const vTs  = ts  ? String(ts.value  || 'disabled') : 'disabled';
    const vRss = rss ? String(rss.value || 'enabled') : 'enabled';

    const ps = `
$dir = Join-Path $env:ProgramData "FalconOptimizer"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$fn = Join-Path $dir "network_overrides.json"
$cfg = @{
  profile = "custom"
  tcp = @{ autotuning = "${vAut}"; ecn = "${vEcn}"; timestamps = "${vTs}"; rss = "${vRss}" }
  notes = "Generated by Falcon Optimizer UI."
}
$cfg | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $fn -Encoding UTF8
`;
    applySteps.length = 0;
    applySteps.push({ type:'ps.run', command: ps });
    applySteps.push({ type:'ps.file', path:'scripts/network/falcon-network-profiles.ps1', args:{ Action:'apply', Profile:'custom' } });
  } catch(_e) {}
}

if (action === "apply" && item && item.id === "mem_pagefile_custom_4096_16384") {
  try {
    const preset = card.querySelector('[data-pf-preset]');
    const minEl = card.querySelector('[data-pf-min]');
    const maxEl = card.querySelector('[data-pf-max]');
    let minMb = 4096, maxMb = 16384;
    if (preset && preset.value && preset.value !== 'custom') {
      const parts = String(preset.value).split(',');
      const a = parseInt(parts[0]||'4096',10);
      const b = parseInt(parts[1]||'16384',10);
      if (isFinite(a)) minMb = a;
      if (isFinite(b)) maxMb = b;
    } else {
      const a = parseInt((minEl && minEl.value) ? minEl.value : '4096', 10);
      const b = parseInt((maxEl && maxEl.value) ? maxEl.value : '16384', 10);
      if (isFinite(a)) minMb = a;
      if (isFinite(b)) maxMb = b;
    }
    if (maxMb < minMb) { const tmp = minMb; minMb = maxMb; maxMb = tmp; }

    const ps = `
Write-Output "Setting custom pagefile on C: (${minMb}-${maxMb} MB)..."
try {
  wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False | Out-Null
  wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=${minMb},MaximumSize=${maxMb} | Out-Null
  Write-Output "Custom pagefile set. Reboot required."
} catch {
  try {
    wmic pagefileset create name="C:\\pagefile.sys" InitialSize=${minMb},MaximumSize=${maxMb} | Out-Null
    Write-Output "Custom pagefile created. Reboot required."
  } catch {
    Write-Output ("Failed: {0}" -f $_.Exception.Message)
  }
}
`;
    applySteps.length = 0;
    applySteps.push({ type:'ps.run', command: ps });
  } catch(_e) {}
}




      // UI-driven custom values (prompt + step injection)
      if (item && item.ui && item.ui.prompt && item.ui.uiKey) {
        try {
          const raw = window.prompt(item.ui.prompt, '');
          if (raw === null) return; // cancelled
          let v = String(raw).trim();
          if (!v) return;
          let n = 0;
          if (/^0x[0-9a-f]+$/i.test(v)) n = parseInt(v, 16);
          else n = parseInt(v, 10);
          if (!Number.isFinite(n) || Number.isNaN(n)) throw new Error('Invalid number');
          for (const s of applySteps) {
            if (s && (s.uiKey === item.ui.uiKey) && (s.value === '__UI_NUMBER__' || typeof s.value === 'string')) {
              s.value = n;
            }
          }
        } catch (e) {
          showToast('Custom value cancelled/invalid.', 'error');
          return;
        }
      }

      const revertSteps = getStepsFor(item, "revert");

      if(simulationMode){
        const plan = await window.falcon.dryRunSteps(applySteps);
        lastLog = JSON.stringify(plan.plan, null, 2);
        const logEl = document.getElementById('lastLogBody');
        if (logEl) logEl.textContent = lastLog;
        return refresh(false);
      }

      const res = await runTweakWithTimeout({
        id: item.id,
        mode: action,
        steps: applySteps,
        revertSteps,
        meta: { riskLevel: risk, requiresSnapshot: !!item.requiresSnapshot }
      }, 90000);

      try {
        const ok = !!(res && res.ok);
        const nm = item && item.name ? item.name : item.id;
        showToast((nm || "Optimization") + (ok ? " applied successfully." : " failed or partially applied. Check log."), ok ? "success" : "error");
      } catch (toastErr) {
        console && console.warn && console.warn("single tweak toast error", toastErr);
      }

      lastLog = (res.stdout||'') + (res.stderr||'');
      if (item.id) {
        tweakLogsById[item.id] = { mode: action, text: lastLog };
      }
      const logEl = document.getElementById('lastLogBody');
      if (logEl) logEl.textContent = lastLog;
      if (isToggle) {
        const okApply = !!(res && res.ok);
        if (okApply) {
          // Update local state immediately, then persist via IPC.
          try {
            if (!toggles || typeof toggles !== 'object') toggles = {};
            if (item && item.id) toggles[item.id] = (action === 'apply');
          } catch(_e) {}
          try {
            toggles = await window.falcon.setState(item.id, action === 'apply');
            if (!toggles || typeof toggles !== 'object') toggles = {};
          } catch(_e) {}

          // Immediately reflect state in UI (without waiting for a re-render).
          try {
            const input = card.querySelector('.fo-switch-input');
            if (input) input.checked = (action === 'apply');
            const b = card.querySelector('.card-actions .btn.primary');
            if (b) b.textContent = (action === 'apply') ? 'Revert' : 'Apply';
          } catch(_e) {}
        }
      }
      if(!skipRefresh) refresh(false);
      return res;
    }

    const btns = card.querySelectorAll('.card-actions .btn');
    const mainBtn = btns[0];
    const secBtn = btns.length > 1 ? btns[1] : null;
    const toggleInputEl = showToggle ? card.querySelector('.fo-switch-input') : null;

    if (isViewPrimary) {
      if (mainBtn) mainBtn.onclick = () => renderTweakDetails(item);
      if (item.secondaryAction && secBtn && !isViewSecondary) {
        secBtn.onclick = () => run(item.secondaryAction.action || 'apply');
      }
    } else if (isViewSecondary) {
      if (mainBtn) {
        if (isSpeedCoreSource) {
          mainBtn.onclick = () => run('apply', { skipRefresh: true });
        } else if (isToggle) {
          // Primary button toggles based on current state (do NOT capture stale isOn).
          mainBtn.onclick = () => {
            const nowOn = !!(toggles && item && item.id && toggles[item.id]);
            return run(nowOn ? 'revert' : 'apply');
          };
          if (toggleInputEl) {
            toggleInputEl.onchange = async () => {
              const desiredOn = !!toggleInputEl.checked;
              const nowOn = !!(toggles && item && item.id && toggles[item.id]);
              if (desiredOn === nowOn) return;
              const res = await run(desiredOn ? 'apply' : 'revert', { skipRefresh: true });
              // If it failed, roll the switch back.
              if (!(res && res.ok)) {
                toggleInputEl.checked = nowOn;
              } else {
                // Ensure label updates without waiting for a full refresh.
                try {
                  if (mainBtn) mainBtn.textContent = desiredOn ? 'Revert' : 'Apply';
                } catch(_e) {}
              }
              // Full re-render to keep everything consistent.
              refresh(false);
            };
          }
        } else {
          mainBtn.onclick = () => run('apply');
        }
      }
      if (secBtn) {
        secBtn.onclick = () => renderTweakDetails(item);
      }
      if (bulkHandlers) {
        bulkHandlers[item.id] = () => run('apply', { skipRefresh: true });
      }
    } else if (isBulkSource) {
      if (mainBtn) mainBtn.onclick = () => run('apply', { skipRefresh: true });
      if (item.secondaryAction && secBtn) {
        secBtn.onclick = () => run(item.secondaryAction.action || 'apply');
      }
      if (bulkHandlers) {
        bulkHandlers[item.id] = () => run('apply', { skipRefresh: true });
      }
    } else if(isToggle){
      // Fallback toggle wiring (non-secondary views)
      const doToggle = () => {
        const nowOn = !!(toggles && item && item.id && toggles[item.id]);
        return run(nowOn ? 'revert' : 'apply');
      };
      if(mainBtn) mainBtn.onclick = doToggle;
      if (toggleInputEl) {
        toggleInputEl.onchange = async () => {
          const desiredOn = !!toggleInputEl.checked;
          const nowOn = !!(toggles && item && item.id && toggles[item.id]);
          if (desiredOn === nowOn) return;
          const res = await run(desiredOn ? 'apply' : 'revert', { skipRefresh: true });
          if (!(res && res.ok)) toggleInputEl.checked = nowOn;
          else {
            try { if (mainBtn) mainBtn.textContent = desiredOn ? 'Revert' : 'Apply'; } catch(_e) {}
          }
          refresh(false);
        };
      }
      if(item.secondaryAction && secBtn){
        secBtn.onclick = () => run(item.secondaryAction.action || 'apply');
      }
    } else {
      if(mainBtn) mainBtn.onclick = () => run('apply');
      if(item.secondaryAction && secBtn){
        secBtn.onclick = () => run(item.secondaryAction.action || 'apply');
      }
    }

    if(isSpeedCoreSource && bulkHandlers){
      // handled above, but keep for safety
      if (!bulkHandlers[item.id]) {
        bulkHandlers[item.id] = () => run('apply', { skipRefresh: true });
      }
    }

    grid.appendChild(card);
  };

  const BATCH = 12;
  let idx = 0;
  const renderBatch = () => {
    for (let c = 0; c < BATCH && idx < filtered.length; c++, idx++) {
      buildCard(filtered[idx]);
    }
    if (idx < filtered.length) {
      requestAnimationFrame(renderBatch);
    }
  };
  renderBatch();


  if(isDebloatSource){
    const packSources = {
      cleaner: 'tweaks/debloat.cleaner.json',
      services: 'tweaks/debloat.services.json',
      tasks: 'tweaks/debloat.tasks.json',
      autoruns: 'tweaks/debloat.autoruns.json',
      uninstall: 'tweaks/debloat.uninstall.json'
    };

    // Default selection: safe-ish packs (no uninstall)
    let selected = new Set(['cleaner','services','tasks','autoruns']);
    try{
      if(window.localStorage){
        const raw = window.localStorage.getItem('falcon.debloat.packs');
        if(raw){
          const arr = JSON.parse(raw);
          if(Array.isArray(arr) && arr.length) selected = new Set(arr);
        }
      }
    }catch(_e){}

    const packBoxes = Array.from(document.querySelectorAll('input.db-pack'));
    packBoxes.forEach(b=>{
      const p = b.getAttribute('data-pack');
      b.checked = selected.has(p);
      b.onchange = () => {
        const id = b.getAttribute('data-pack');
        if(b.checked) selected.add(id); else selected.delete(id);
        try{
          if(window.localStorage) window.localStorage.setItem('falcon.debloat.packs', JSON.stringify(Array.from(selected)));
        }catch(_e){}
      };
    });

    const selectAllBtn = document.getElementById('dbSelectAllPacks');
    if(selectAllBtn){
      selectAllBtn.onclick = () => {
        const anyUnchecked = packBoxes.some(b => !b.checked);
        packBoxes.forEach(b => {
          b.checked = anyUnchecked;
          const id = b.getAttribute('data-pack');
          if(anyUnchecked) selected.add(id); else selected.delete(id);
        });
        try{ if(window.localStorage) window.localStorage.setItem('falcon.debloat.packs', JSON.stringify(Array.from(selected))); }catch(_e){}
      };
    }

    const runBtn = document.getElementById('dbRunPacks');
    if(runBtn){
      runBtn.onclick = async () => {
        const picks = packBoxes.filter(b=>b.checked).map(b=>b.getAttribute('data-pack'));
        if(!picks.length){
          showToast('Select at least one Debloat pack to run.', 'error');
          return;
        }
        try{ if(window.localStorage) window.localStorage.setItem('falcon.debloat.packs', JSON.stringify(picks)); }catch(_e){}

        const order = ['cleaner','uninstall','tasks','services','autoruns'];
        const runPacks = order.filter(p=>picks.includes(p));

        try {
          showRunPanel('Debloat – running selected packs');
          setProgress(0, 'Preparing Debloat batch…');
          setBatchProgress(true, 0, 1, 'Preparing…');
        } catch(_e) {}

        let runnable = [];
        for(const p of runPacks){
          try{
            const data = await loadJSON(packSources[p]);
            const its = (data.items || data.tweaks || []).map(it=>{
              if(!it.type){
                if(it.apply && it.revert) it.type='toggle'; else it.type='action';
              }
              return it;
            });
            for(const it of its){
              const st = (it.apply && Array.isArray(it.apply.steps)) ? it.apply.steps : [];
              if(st.length) runnable.push({ pack:p, it });
            }
          }catch(e){
            showToast('Failed to load pack: ' + p, 'error');
          }
        }

        const total = runnable.length;
        if(!total){
          showToast('No runnable items found in selected packs.', 'error');
          try{ setBatchProgress(false); }catch(_e){}
          return;
        }

        let attempted = 0, okCount = 0, failCount = 0;
        const update = (label) => {
          try{
            setBatchProgress(true, attempted, total, label || `Running ${attempted}/${total}`);
            const pct = Math.round((attempted/total)*100);
            setProgress(pct, `Debloat: ${attempted}/${total}`);
          }catch(_e){}
        };

        for(const r of runnable){
          const it = r.it;
          const pack = r.pack;
          update(`${pack}: ${it.name || it.id}`);

          const timeout = (pack === 'uninstall' ? 240000 : 180000);
          try{
            const applySteps = getApplyStepsWithVerify(it);
            const revertSteps = getStepsFor(it, 'revert');
            const res = await runTweakWithTimeout(
              { id: it.id, mode:'apply', steps: applySteps, revertSteps, meta:{ riskLevel: normRisk(it), from:`Debloat:${pack}` } },
              timeout
            );
            if(res && res.ok) okCount++; else failCount++;
            lastLog = (res && (res.stdout || res.stderr)) ? ((res.stdout||'') + (res.stderr||'')) : lastLog;
            const logEl = document.getElementById('lastLogBody');
            if (logEl) logEl.textContent = lastLog || '';
          } catch(e){
            failCount++;
          }
          attempted++;
        }

        try{
          setBatchProgress(false);
          setProgress(100, 'Debloat batch complete.');
        }catch(_e){}

        showToast(`Debloat complete: ${okCount} ok, ${failCount} failed.`, failCount ? 'error' : 'success');
        refresh(false);
      };
    }
  }


  if(isSpeedCoreSource){
    const selectAllBtn = document.getElementById('boostSelectAll');
    const runBtn = document.getElementById('boostRunBtn');
    const getCheckboxes = () => Array.from(document.querySelectorAll('.boost-select'));

    if(selectAllBtn){
      selectAllBtn.onclick = () => {
        const boxes = getCheckboxes();
        const anyUnchecked = boxes.some(b => !b.checked);
        boxes.forEach(b => { b.checked = anyUnchecked; });
      };
    }
    if(runBtn){
      runBtn.onclick = async () => {
        const boxes = getCheckboxes().filter(b => b.checked);
        if(!boxes.length){
          showToast('Select at least one optimization to run.', 'error');
          return;
        }

        const total = boxes.length;
        let attempted = 0;
        let okCount = 0;
        let failCount = 0;

        try {
          showRunPanel('Speed Core – running selected optimizations');
          setProgress(0, 'Preparing Speed Core batch…');
        } catch(_e) {}

        const updateProg = () => {
          const pct = total > 0 ? Math.round((attempted / total) * 100) : 0;
          try {
            setProgress(pct, 'Running Speed Core: ' + attempted + '/' + total);
          } catch(_e) {}
        };

        for(const box of boxes){
          const id = box.getAttribute('data-id');
          const fn = bulkHandlers[id];
          if(typeof fn === 'function'){
            try {
              const res = await fn();
              attempted++;
              if (res && res.ok) okCount++; else failCount++;
            } catch(e){
              attempted++;
              failCount++;
            }
            updateProg();
          }
        }

        try {
          setProgress(100, 'Speed Core batch complete.');
        } catch(_e) {}

        if (attempted > 0) {
          const msg = 'Speed Core run: ' + attempted + ' item(s), ' + okCount + ' OK, ' + failCount + ' failed.';
          const kind = failCount > 0 ? 'error' : 'success';
          showToast(msg, kind);
        } else {
          showToast('No Speed Core optimizations were executed.', 'error');
        }
        refresh(false);
      };
    }
  }

  if(isGameModeSource && bulkHandlers){
    const selectAllBtn = document.getElementById('gmSelectAll');
    const runBtn = document.getElementById('gmStart');
    const stopBtn = document.getElementById('gmStop');

    const getBoxes = () => Array.from(document.querySelectorAll('.boost-select'));

    // Persist Game Mode selection so your choices are remembered between sessions
    const persistSelection = () => {
      try {
        const ids = getBoxes()
          .filter(b => b.checked)
          .map(b => b.getAttribute('data-id'))
          .filter(Boolean);
        if (window.localStorage) {
          window.localStorage.setItem('falcon.gm.selected', JSON.stringify(ids));
        }
      } catch(_e) {}
    };

    // Also persist when boxes change individually
    const gridEl = document.getElementById('grid');
    if (gridEl) {
      gridEl.addEventListener('change', (ev) => {
        const t = ev.target;
        if (t && t.classList && t.classList.contains('boost-select')) {
          persistSelection();
        }
      });
    }


    if (selectAllBtn) {
      selectAllBtn.onclick = () => {
        const boxes = getBoxes();
        const allSelected = boxes.every(b => b.checked);
        boxes.forEach(b => { b.checked = !allSelected; });
        persistSelection();
      };
    }

    if (runBtn) {
      runBtn.onclick = async () => {
        const boxes = getBoxes().filter(b => b.checked);
        if (!boxes.length) {
          showToast('Select at least one Game Mode tweak to run.', 'error');
          return;
        }

        // Remember what we activated so Stop can revert it later
        try {
          const activeIds = boxes.map(b => b.getAttribute('data-id')).filter(Boolean);
          if (window.localStorage) window.localStorage.setItem('falcon.gm.active', JSON.stringify(activeIds));
        } catch(_e) {}

        // Show a real progress panel for Game Mode runs
        try {
          showRunPanel('Game Mode – running selected tweaks');
          setProgress(0, 'Preparing Game Mode batch…');
        } catch(_e) {}

        const photoBoxes = Array.from(document.querySelectorAll('.gm-photo-select')).filter(b => b.checked);
        const totalPlanned = boxes.length + photoBoxes.length;

        let attempted = 0;
        let okCount = 0;
        let failCount = 0;

        const updateProg = () => {
          const pct = totalPlanned > 0 ? Math.round((attempted / totalPlanned) * 100) : 0;
          try {
            setProgress(pct, 'Running Game Mode tweaks… ' + attempted + '/' + totalPlanned);
          } catch(_e) {}
        };

        for (const box of boxes) {
          const id = box.getAttribute('data-id');
          const fn = bulkHandlers[id];
          if (!fn) continue;
          try {
            const res = await fn();
            attempted++;
            if (res && res.ok) okCount++; else failCount++;
          } catch (e) {
            attempted++;
            failCount++;
          }
          updateProg();
        }

        let photoApplied = 0;
        try {
          if (typeof window.__falconRunSelectedGameModePhotos === 'function') {
            photoApplied = await window.__falconRunSelectedGameModePhotos();
            attempted += photoApplied;
            okCount += photoApplied; // photo helpers only count successes
            updateProg();
          }
        } catch (e) {
          // ignore errors from photo helpers to avoid breaking the batch
        }

        try {
          setProgress(100, 'Game Mode batch complete.');
        } catch(_e) {}

        const total = attempted;
        if (total > 0) {
          const msg = 'Game Mode run: ' + total + ' item(s), ' + okCount + ' OK, ' + failCount + ' failed.';
          const kind = failCount > 0 ? 'error' : 'success';
          showToast(msg, kind);
        } else {
          showToast('Select at least one Game Mode tweak to run.', 'error');
        }
      };
    }

if (stopBtn) {
  stopBtn.onclick = async () => {
    let activeIds = [];
    try {
      const raw = window.localStorage ? window.localStorage.getItem('falcon.gm.active') : null;
      if (raw) {
        const arr = JSON.parse(raw);
        if (Array.isArray(arr)) activeIds = arr;
      }
    } catch(_e) {}
    if (!activeIds.length) {
      showToast('No active Game Mode session found. Start Game Mode first.', 'error');
      return;
    }

    try {
      showRunPanel('Game Mode – stopping (reverting)');
      setProgress(0, 'Preparing revert…');
    } catch(_e) {}

    try {
      const data = await loadJSON(source);

  let extraTopHtml = '';
  if (source === 'tweaks/performance.library.json') {
    extraTopHtml = `
      <div class="panel boost-toolbar">
        <div class="card-title">Presets</div>
        <div class="card-desc">Apply a fast preset baseline, then use the Library below to fine-tune. Presets run multiple actions in sequence.</div>
        <div class="boost-toolbar-actions">
          <button class="btn secondary" id="plPresetBalanced">Apply Balanced preset</button>
          <button class="btn primary" id="plPresetLatency">Apply Latency preset</button>
          <button class="btn secondary" id="plPresetFps">Apply FPS preset</button>
        </div>
        <div class="muted" style="margin-top:8px; font-size:12px;">Tip: You can still run any single optimization card below, including custom-value cards.</div>
      </div>
    `;
  }
      const rawItems = (data.items || data.tweaks || []);
      const byId = new Map(rawItems.map(it => [String(it.id||''), it]));
      const activeItems = activeIds.map(id => byId.get(String(id))).filter(Boolean);

      let attempted = 0;
      let okCount = 0;
      let failCount = 0;

      const total = activeItems.length;
      const updateProg = () => {
        const pct = total > 0 ? Math.round((attempted / total) * 100) : 0;
        try { setProgress(pct, 'Reverting… ' + attempted + '/' + total); } catch(_e) {}
      };

      for (const it of activeItems) {
        attempted++;
        updateProg();
        const steps = (it.revert && Array.isArray(it.revert.steps)) ? it.revert.steps : [];
        if (!steps.length) continue;
        const res = await runTweakWithTimeout({ id: it.id, mode: 'revert', steps, meta: { source, name: it.name } }, 120000);
        if (res && res.ok) okCount++; else failCount++;
      }

      try { if (window.localStorage) window.localStorage.removeItem('falcon.gm.active'); } catch(_e) {}
      showToast('Game Mode stopped. Reverted: ' + okCount + ' | Failed: ' + failCount, (failCount ? 'error' : 'success'));
      try { setProgress(100, 'Stopped'); } catch(_e) {}
    } catch (e) {
      showToast('Stop Game Mode failed: ' + (e && e.message ? e.message : String(e)), 'error');
    }
  };
}
  }
}



const PROCESS_LAB_CORE_PROCESSES = [
  'system', 'registry', 'smss.exe', 'csrss.exe', 'wininit.exe', 'services.exe',
  'lsass.exe', 'winlogon.exe', 'fontdrvhost.exe', 'dwm.exe', 'sihost.exe',
  'explorer.exe', 'audiodg.exe', 'runtimebroker.exe', 'conhost.exe', 'ctfmon.exe',
  'startmenuexperiencehost.exe', 'searchindexer.exe', 'spoolsv.exe', 'svchost.exe',
  'securityhealthservice.exe', 'securityhealthsystray.exe', 'defender.exe',
  'msmpeng.exe', 'mssense.exe', 'csrss.exe', 'winhttpautoproxysvc.exe',
  'falconoptimizer.exe', 'electron.exe', 'node.exe'
];

function classifyProcessForLab(name){
  const n = (name || '').toLowerCase();
  if (!n) return { core:false, tier:'unknown', note:'Unknown process. Only close if you recognize it.' };
  if (PROCESS_LAB_CORE_PROCESSES.includes(n)) {
    return { core:true, tier:'core', note:'Core Windows / Falcon process – hidden from termination list.' };
  }
  // Common launchers / overlays / sync clients
  if (n.includes('discord')) return { core:false, tier:'recommended', note:'Discord / overlay. Often safe to close while gaming if not using voice.' };
  if (n.includes('steam')) return { core:false, tier:'recommended', note:'Steam client. Safe to close after launching games (reopen later if needed).' };
  if (n.includes('epicgames') || n.includes('egs-launcher') || n.includes('fortnite launcher')) return { core:false, tier:'recommended', note:'Epic Games launcher. Safe to close after launching the game.' };
  if (n.includes('origin') || n.includes('ea desktop') || n.includes('eadesktop')) return { core:false, tier:'recommended', note:'EA / Origin launcher. Safe to close after launching games.' };
  if (n.includes('battle.net') || n.includes('battlenet')) return { core:false, tier:'recommended', note:'Battle.net launcher. Safe to close once games are running.' };
  if (n.includes('riotclient') || n.includes('valorant')) return { core:false, tier:'caution', note:'Riot client. Only close if you know the game is fully launched and stable.' };
  if (n.includes('onedrive')) return { core:false, tier:'recommended', note:'OneDrive sync. Often safe to close while gaming to reduce background I/O.' };
  if (n.includes('dropbox')) return { core:false, tier:'recommended', note:'Dropbox sync. Often safe to close during gaming sessions.' };
  if (n.includes('googledrivesync') || n.includes('googledrive')) return { core:false, tier:'recommended', note:'Google Drive sync. Often safe to close while gaming.' };
  if (n.includes('spotify')) return { core:false, tier:'recommended', note:'Spotify. Closing can slightly reduce CPU usage; only if you do not need music.' };
  if (n.includes('cortana')) return { core:false, tier:'recommended', note:'Cortana / search helper. Can usually be closed safely.' };
  if (n.includes('teams')) return { core:false, tier:'recommended', note:'Microsoft Teams. Often safe to close outside of meetings.' };
  if (n.includes('slack')) return { core:false, tier:'recommended', note:'Slack. Often safe to close while gaming.' };
  if (n.includes('chrome.exe') || n === 'chrome' || n.includes('msedge') || n.includes('opera') || n.includes('firefox')) {
    return { core:false, tier:'recommended', note:'Browser. Closing extra browser windows reduces RAM/CPU usage.' };
  }
  // Security / AV – treat with caution
  if (n.includes('avast') || n.includes('avg') || n.includes('eset') || n.includes('kaspersky') || n.includes('bitdefender')) {
    return { core:false, tier:'caution', note:'Third‑party antivirus. Closing can improve latency but reduces protection.' };
  }
  // Default
  return { core:false, tier:'unknown', note:'Unknown or mixed‑purpose process. Only close if you know what it is.' };
}

async function renderProcessLab(){
  const allowed = await ensureAggressiveConsent('processLab');
  if (!allowed) {
    els.panel.innerHTML = `
      <div class="panel">
        <div class="card-title">Process Lab</div>
        <div class="card-desc">You must accept the Aggressive Tweaks / BIOS warning before using Process Lab. Re-open this section and accept to continue.</div>
      </div>
    `;
    return;
  }

  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Process Lab</div>
      <div class="card-desc">Audit running processes and close non-essential background apps. This does <strong>not</strong> uninstall anything – it just calls taskkill on selected processes. Used correctly, it helps push background process count toward sub-40 for competitive play.</div>
      <div class="card" id="procSummaryCard">
        <div class="card-title">Snapshot</div>
        <div class="card-desc" id="procSummaryText">Detecting running processes…</div>
        <label class="field-label" style="margin-top:8px;display:flex;align-items:center;gap:6px;">
          <input type="checkbox" id="procShowRecommended" /> Show only recommended launchers / overlays / sync apps
        </label>
      </div>
    </div>
    <div class="panel" id="procListPanel">
      <div class="card-title">Background process list</div>
      <div class="card-desc">These are non-core processes. Recommended items are common launchers, overlays, sync tools, and apps that can usually be closed during gaming. Unknown items should only be closed if you recognize them.</div>
      <div id="procList" class="grid"></div>
      <div class="card-actions" style="margin-top:12px;display:flex;flex-wrap:wrap;gap:8px;">
        <button class="btn primary" id="procTerminateSelected">Terminate selected processes</button>
        <button class="btn" id="procRefresh">Refresh list</button>
      </div>
    </div>
    <div class="panel" id="procPresetsPanel">
      <div class="card-title">Process Lab presets (services / background trimming)</div>
      <div class="card-desc">These presets use Falcon's service helpers and your imported script to disable background services and apps that impact latency. They are gated behind the Aggressive Tweaks warning and assume you are running Falcon as Administrator. Extreme preset targets the lowest possible background process count and is intended for local Windows accounts used only for gaming.</div>
      <div class="card">
        <div class="card-title">Choose preset</div>
        <div class="card-desc">All presets prioritize input latency and frame-time stability over comfort features. Read the notes before applying.</div>
        <ul class="bios-note" style="margin-bottom:8px;">
          <li><strong>Safe:</strong> Uses Falcon's built-in safe services helper. Minimal risk; good starting point.</li>
          <li><strong>Competitive:</strong> Adds your deeper telemetry/sensor/compatibility trimming on top of Safe.</li>
          <li><strong>Extreme (sub-40 target):</strong> Chains every supported helper to push process count as low as possible. May disable some Windows features and store apps.</li>
        </ul>
        <div class="card-actions" style="display:flex;flex-wrap:wrap;gap:8px;">
          <button class="btn" id="procPresetSafe">Apply Safe preset</button>
          <button class="btn" id="procPresetComp">Apply Competitive preset</button>
          <button class="btn primary" id="procPresetExtreme">Apply Extreme preset</button>
          <button class="btn" id="procRestore">Restore Process Lab snapshot</button>
          <button class="btn" id="procOpenFixes">Open Fixes / compatibility</button>
        </div>
        <p class="bios-note" style="margin-top:8px;">Tip: after running a preset, use the live process list above to close any remaining launchers (Opera GX, Steam, Discord, etc.) and verify your process count in Task Manager. Aim for &lt; 40 total background processes on a dedicated gaming account.</p>
      </div>

    <div class="panel" id="procCustomPanel">
      <div class="card-title">Custom service matrix (max debloat)</div>
      <div class="card-desc">
        Build your own Process Lab preset on top of a base mode. This lets you push Windows services and features as far as you are comfortable,
        with clear labels for what each service touches (Store, Defender screens, Wi-Fi helpers, sensors, etc.).
        Use <strong>Extreme + custom overrides</strong> on a dedicated local gaming account only.
      </div>
      <div class="card">
        <div class="card-title">Base mode and overrides</div>
        <div class="card-desc">
          1) Pick a base mode (Safe / Competitive / Extreme).<br>
          2) Click <strong>Load catalog</strong> to load every known Process Lab service entry.<br>
          3) Use the table to force-disable or change startup type for individual services, based on their risk notes.<br>
          4) Click <strong>Run custom preset</strong> to apply your plan. A snapshot is taken automatically before changes.
        </div>
        <div class="card-actions" style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">
          <label class="field-label" for="procCustomBase" style="margin-right:4px;">Base mode:</label>
          <select id="procCustomBase" class="field" style="width:auto;min-width:140px;">
            <option value="safe">Safe</option>
            <option value="competitive">Competitive</option>
            <option value="extreme" selected>Extreme</option>
          </select>
          <button class="btn" id="procCustomLoad">Load catalog</button>
          <button class="btn primary" id="procCustomRun">Run custom preset</button>
        </div>
      </div>
      <div class="card" id="procCustomMatrixHost">
        <div class="card-title">Service / feature catalog</div>
        <div class="card-desc">
          Each row below represents a Windows service or feature that Falcon Process Lab can touch.
          Risk badges and condition tags (Store, MS account, Wi-Fi, laptop-unsafe, etc.) describe what you are trading for lower process count.
        </div>
        <div id="procCustomMatrix" class="scroll-y" style="max-height:520px;overflow-y:auto;margin-top:8px;"></div>
      </div>
    </div>
  `;

  const summaryEl = document.getElementById('procSummaryText');
  if (summaryEl) summaryEl.textContent = 'Click "Refresh list" to scan background processes.';
  const listEl = document.getElementById('procList');
  const chkRecommended = document.getElementById('procShowRecommended');

  let isLoadingProcs = false;

  async function loadAndRender(){
    if (isLoadingProcs) return;
    isLoadingProcs = true;
    if (!window.falcon || !window.falcon.listProcesses) {
      if (summaryEl) summaryEl.textContent = 'Process API not available on this build.';
      isLoadingProcs = false;
      return;
    }
    if (listEl) listEl.classList.add('proc-loading');
    try {
      const res = await window.falcon.listProcesses();
      if (!res || !res.ok) {
        if (summaryEl) summaryEl.textContent = 'Could not list processes. Try running Falcon as Administrator.';
        return;
      }
      const raw = res.processes || [];
      const annotated = raw.map(p => {
        const meta = classifyProcessForLab(p.name);
        return { ...p, ...meta };
      });

      const cores = annotated.filter(p => p.core);
      let candidates = annotated.filter(p => !p.core);
      const total = annotated.length;
      const coreCount = cores.length;
      const candCount = candidates.length;

      if (summaryEl) {
        summaryEl.innerHTML = `Detected <strong>${total}</strong> processes. <strong>${coreCount}</strong> are protected core / Windows processes; <strong>${candCount}</strong> are background candidates. Use the checkboxes below to close the ones you do not need.`;
      }

      function renderRows(){
        if (!listEl) return;
        const onlyRecommended = !!(chkRecommended && chkRecommended.checked);
        let view = candidates.slice();
        if (onlyRecommended) view = view.filter(p => p.tier === 'recommended');
        view.sort((a,b) => {
          const order = (t) => t === 'recommended' ? 0 : (t === 'caution' ? 1 : 2);
          const oa = order(a.tier), ob = order(b.tier);
          if (oa !== ob) return oa - ob;
          return (a.name || '').localeCompare(b.name || '');
        });
        if (!view.length) {
          listEl.innerHTML = '<div class="notice">No matching background candidates. Either everything is core/unknown, or you disabled recommended filtering.</div>';
          return;
        }
        listEl.innerHTML = view.map(p => {
          const badge = p.tier === 'recommended'
            ? '<span class="badge">Recommended</span>'
            : (p.tier === 'caution' ? '<span class="badge risk-warning">Caution</span>' : '<span class="badge">Unknown</span>');
          return `
            <div class="card process-row" data-pid="${p.pid}" data-name="${__eh(p.name||'')}">
              <div class="row" style="align-items:flex-start;gap:10px;">
                <label style="margin-top:4px;"><input type="checkbox" class="proc-checkbox" /></label>
                <div style="flex:1;min-width:0;">
                  <div class="card-title" style="margin-bottom:2px;">${__eh(p.name || '')}</div>
                  <div class="muted">PID ${p.pid}</div>
                  <div class="card-desc" style="margin-top:6px;">${__eh(p.note || '')}</div>
                </div>
                <div>${badge}</div>
              </div>
            </div>
          `;
        }).join('');
      }

      renderRows();
      if (chkRecommended) {
        chkRecommended.onchange = () => renderRows();
      }
    } catch (e) {
      if (summaryEl) summaryEl.textContent = 'Process listing failed: ' + (e && e.message ? e.message : String(e));
    } finally {
      if (listEl) listEl.classList.remove('proc-loading');
      isLoadingProcs = false;
    }
  }

  // Initial load is manual now; use the Refresh button to populate the process list.

  // --- Custom Process Matrix logic (catalog-driven) ---

  const customBaseSel = document.getElementById('procCustomBase');
  const customLoadBtn = document.getElementById('procCustomLoad');
  const customRunBtn  = document.getElementById('procCustomRun');
  const customMatrix  = document.getElementById('procCustomMatrix');

  let customCatalog = [];
  let customOverrides = {};

  async function loadProcessLabCatalog(){
    try {
      const res = await fetch('tweaks/processlab.services.catalog.json');
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const data = await res.json();
      return Array.isArray(data.services) ? data.services : [];
    } catch (e) {
      showToast('Failed to load Process Lab catalog: ' + (e && e.message ? e.message : String(e)), 'error');
      return [];
    }
  }

  function describeConditions(cond){
    if (!cond) return '';
    const bits = [];
    if (cond.requiresLocalAccount) bits.push('Local account recommended');
    if (cond.breaksMicrosoftStore) bits.push('May break Microsoft Store');
    if (cond.breaksMicrosoftAccountLogin) bits.push('May break MS account login');
    if (cond.laptopUnsafe) bits.push('Aggressive on laptops');
    if (cond.desktopOnly) bits.push('Desktop-only tweak');
    return bits.join(' • ');
  }

  function makeRiskBadge(level){
    const lv = (level || '').toLowerCase();
    if (!lv) return '';
    let cls = 'badge';
    if (lv === 'danger') cls += ' badge-danger';
    else if (lv === 'warning') cls += ' badge-warning';
    else cls += ' badge-safe';
    return `<span class="${cls}" style="font-size:10px;padding:2px 6px;border-radius:999px;">${__eh(level)}</span>`;
  }

  function renderCustomMatrix(){
    if (!customMatrix) return;
    if (!customCatalog || !customCatalog.length) {
      customMatrix.innerHTML = '<div style="padding:12px;font-size:12px;color:var(--muted);">No catalog entries loaded yet.</div>';
      return;
    }

    const rows = customCatalog.map((svc) => {
      const name = svc.serviceName || '';
      const disp = svc.displayName || name;
      const cat  = svc.category || '';
      const risk = svc.riskLevel || '';
      const cond = svc.conditions || {};
      const dm   = svc.defaultModes || {};
      const overrideVal = customOverrides[name] || 'inherit';
      const condText = describeConditions(cond);
      const desc = svc.description || '';

      const safeMode = dm.safe || 'unchanged';
      const compMode = dm.competitive || 'unchanged';
      const extMode  = dm.extreme || 'unchanged';

      return `
        <div class="row" data-service-name="${__eh(name)}" style="display:flex;align-items:flex-start;padding:8px 10px;border-bottom:1px solid rgba(255,255,255,0.03);gap:8px;">
          <div style="flex:2;min-width:0;">
            <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap;">
              <div class="card-title" style="margin:0;font-size:13px;">${__eh(disp)}</div>
              ${makeRiskBadge(risk)}
            </div>
            <div class="muted" style="font-size:11px;margin-top:2px;">${__eh(name)}${cat ? ' • ' + escapeHtml(cat) : ''}</div>
            ${condText ? `<div class="muted" style="font-size:10px;margin-top:2px;">${__eh(condText)}</div>` : ''}
            ${desc ? `<div class="card-desc" style="font-size:11px;margin-top:4px;">${__eh(desc)}</div>` : ''}
          </div>
          <div style="flex:0 0 140px;font-size:10px;">
            <div><strong>Safe:</strong> ${__eh(safeMode)}</div>
            <div><strong>Comp:</strong> ${__eh(compMode)}</div>
            <div><strong>Extreme:</strong> ${__eh(extMode)}</div>
          </div>
          <div style="flex:0 0 120px;">
            <label class="field-label" style="font-size:11px;display:block;margin-bottom:2px;">Override</label>
            <select class="procCustomOverride" data-service="${__eh(name)}" style="width:100%;">
              <option value="inherit"${overrideVal === 'inherit' ? ' selected' : ''}>Inherit from base</option>
              <option value="disabled"${overrideVal === 'disabled' ? ' selected' : ''}>Force disabled</option>
              <option value="manual"${overrideVal === 'manual' ? ' selected' : ''}>Force manual</option>
              <option value="automatic"${overrideVal === 'automatic' ? ' selected' : ''}>Force automatic</option>
            </select>
          </div>
        </div>
      `;
    }).join('');

    customMatrix.innerHTML = `
      <div style="background:rgba(0,0,0,0.2);backdrop-filter:blur(12px);">
        <div style="display:flex;font-size:11px;font-weight:600;padding:6px 10px;border-bottom:1px solid rgba(255,255,255,0.06);">
          <div style="flex:2;">Service</div>
          <div style="flex:0 0 140px;">Preset defaults</div>
          <div style="flex:0 0 120px;">Custom override</div>
        </div>
        ${rows}
      </div>
    `;

    const selects = customMatrix.querySelectorAll('.procCustomOverride');
    selects.forEach(sel => {
      sel.onchange = () => {
        const svcName = sel.getAttribute('data-service') || '';
        const val = sel.value || 'inherit';
        if (!svcName) return;
        if (val === 'inherit') {
          delete customOverrides[svcName];
        } else {
          customOverrides[svcName] = val;
        }
      };
    });
  }

  async function loadCustomMatrix(){
    customCatalog = await loadProcessLabCatalog();
    customOverrides = customOverrides || {};
    renderCustomMatrix();
  }

  async function runCustomPreset(){
    if (!window.falcon || !window.falcon.runProcessCustomPreset) {
      showToast('Custom Process Lab runner not available on this build.', 'error');
      return;
    }
    const baseMode = customBaseSel ? (customBaseSel.value || 'competitive') : 'competitive';

    const overrideKeys = Object.keys(customOverrides || {});
    const dangerCount = (customCatalog || []).filter(svc => {
      if (!svc || !svc.serviceName) return false;
      const name = svc.serviceName;
      if (!overrideKeys.includes(name)) return false;
      return String(svc.riskLevel || '').toLowerCase() === 'danger';
    }).length;

    const okModal = await showConfirmModal({
      title: 'Run custom Process Lab preset?',
      body: 'Base mode: ' + baseMode + '. Overrides: ' + overrideKeys.length + ' services' + (dangerCount ? (' (' + dangerCount + ' marked as DANGER)') : '') + '.\\n\\nThis can disable telemetry, sensors, UX features, and some Windows components. Use Restore Process Lab snapshot if it feels too aggressive.',
      risk: dangerCount ? 'High' : 'Medium',
      requireTyped: dangerCount > 0
    });
    if (!okModal) return;

    const progressHost = document.getElementById('procPresetsPanel');
    let progressBar = null;
    let progressBarInner = null;
    let prog = 0;
    let progTimer = null;

    if (progressHost) {
      progressBar = document.createElement('div');
      progressBar.className = 'progress-bar-host';
      progressBar.style.marginTop = '12px';
      progressBar.innerHTML = `
        <div class="progress-label" style="font-size:12px;margin-bottom:4px;">Running custom Process Lab preset…</div>
        <div class="progress-bar" style="width:100%;height:6px;border-radius:999px;background:rgba(255,255,255,0.06);overflow:hidden;">
          <div class="progress-bar-fill" style="width:0%;height:100%;border-radius:999px;background:linear-gradient(90deg, rgba(255,200,0,0.9), rgba(255,80,0,0.9));transition:width 0.15s ease-out;"></div>
        </div>
      `;
      progressHost.appendChild(progressBar);
      progressBarInner = progressBar.querySelector('.progress-bar-fill');
      prog = 0;
      progTimer = window.setInterval(() => {
        if (!progressBarInner) return;
        if (prog < 90) {
          prog += 5;
          if (prog > 90) prog = 90;
        }
        progressBarInner.style.width = prog + '%';
      }, 180);
    }

    try {
      const res = await window.falcon.runProcessCustomPreset(baseMode, customOverrides);
      const ok = res && res.ok;
      const stdout = res && res.stdout ? res.stdout : '';
      if (progressBarInner) {
        prog = 100;
        progressBarInner.style.width = '100%';
      }
      let msg = 'Custom Process Lab preset ' + (ok ? 'completed.' : 'finished with errors – check log or adjust overrides.');
      if (stdout && stdout.indexOf('UserSessionProcessCount') >= 0) {
        msg += ' ' + stdout;
      }
      showToast(msg, ok ? 'success' : 'error');
      await loadAndRender();
    } catch (e) {
      showToast('Custom preset failed: ' + (e && e.message ? e.message : String(e)), 'error');
    } finally {
      if (progTimer) {
        window.clearInterval(progTimer);
      }
      if (progressBar && progressBar.parentNode) {
        progressBar.parentNode.removeChild(progressBar);
      }
    }
  }

  if (customLoadBtn) customLoadBtn.onclick = () => loadCustomMatrix();
  if (customRunBtn) customRunBtn.onclick  = () => runCustomPreset();


  const btnRefresh = document.getElementById('procRefresh');
  if (btnRefresh) btnRefresh.onclick = () => loadAndRender();

  const btnKill = document.getElementById('procTerminateSelected');
  if (btnKill) {
    btnKill.onclick = async () => {
      const rows = Array.from(document.querySelectorAll('.process-row'));
      const selected = [];
      for (const row of rows) {
        const cb = row.querySelector('.proc-checkbox');
        if (cb && cb.checked) {
          const pid = parseInt(row.getAttribute('data-pid') || '0', 10) || 0;
          const name = row.getAttribute('data-name') || '';
          if (pid > 0) selected.push({ pid, name });
        }
      }
      if (!selected.length) {
        showToast('No processes selected.', 'error');
        return;
      }
      const okModal = await showConfirmModal({
        title: 'Terminate selected processes?',
        body: 'Falcon will call taskkill /F on ' + selected.length + ' selected background processes. This can reduce CPU/RAM usage and latency, but will close apps immediately. Make sure you recognize every process in the list.',
        risk: 'Warning',
        requireTyped: false
      });
      if (!okModal) return;

      try {
        if (!window.falcon || !window.falcon.terminateProcesses) {
          showToast('Terminate API not available.', 'error');
          return;
        }
        const res = await window.falcon.terminateProcesses(selected);
        const results = (res && res.results) || [];
        const okCount = results.filter(r => r.ok).length;
        const failCount = results.length - okCount;
        showToast('Process Lab terminated ' + okCount + ' process(es); ' + failCount + ' failed or were already closed.', okCount > 0 && failCount === 0 ? 'success' : 'info');
        await loadAndRender();
      } catch (e) {
        showToast('Process termination failed: ' + (e && e.message ? e.message : String(e)), 'error');
      }
    };
  }

  const btnSafe = document.getElementById('procPresetSafe');
  const btnComp = document.getElementById('procPresetComp');
  const btnExtreme = document.getElementById('procPresetExtreme');
  const btnCustom = document.getElementById('procPresetCustom');
  const btnFixes = document.getElementById('procOpenFixes');
  const btnRestore = document.getElementById('procRestore');

  async function runPreset(mode, label){
    if (!window.falcon || !window.falcon.runProcessPreset) {
      showToast('Process preset engine not available on this build.', 'error');
      return;
    }
    const okModal = await showConfirmModal({
      title: 'Apply ' + label + ' preset?',
      body: 'This will run the ' + label + ' Process Lab preset. It can disable background services, telemetry, and non-essential background apps. Continue only if you understand that Windows features and store apps may be affected.',
      risk: 'High',
      requireTyped: true
    });
    if (!okModal) return;

    const progressHost = document.getElementById('procPresetsPanel');
    let progressBar = null;
    let progressBarInner = null;
    let progressLabel = null;
    let prog = 0;
    let progTimer = null;

    if (progressHost) {
      progressBar = document.createElement('div');
      progressBar.className = 'progress-bar-host';
      progressBar.style.marginTop = '12px';
      progressBar.innerHTML = `
        <div class="progress-label" style="font-size:12px;margin-bottom:4px;">Applying ` + label + ` preset…</div>
        <div class="progress-bar" style="width:100%;height:6px;border-radius:999px;background:rgba(255,255,255,0.06);overflow:hidden;">
          <div class="progress-bar-fill" style="width:0%;height:100%;border-radius:999px;background:linear-gradient(90deg, rgba(0,200,255,0.9), rgba(0,255,150,0.9));transition:width 0.15s ease-out;"></div>
        </div>
      `;
      progressHost.appendChild(progressBar);
      progressLabel = progressBar.querySelector('.progress-label');
      progressBarInner = progressBar.querySelector('.progress-bar-fill');
      prog = 0;
      progTimer = window.setInterval(() => {
        if (!progressBarInner) return;
        // Ease toward ~90% while work is running to show life without pretending exact steps
        if (prog < 90) {
          prog += 5;
          if (prog > 90) prog = 90;
        }
        progressBarInner.style.width = prog + '%';
      }, 180);
    }

    try {
      const res = await window.falcon.runProcessPreset(mode);
      const ok = res && res.ok;
      const stdout = res && res.stdout ? res.stdout : '';
      // Snap bar to 100% on completion
      if (progressBarInner) {
        prog = 100;
        progressBarInner.style.width = '100%';
      }
      let msg = 'Process Lab ' + label + ' preset ' + (ok ? 'completed.' : 'finished with errors – check log or rerun specific fixes.');
      if (stdout && stdout.indexOf('UserSessionProcessCount') >= 0) {
        msg += ' ' + stdout;
      }
      showToast(msg, ok ? 'success' : 'error');
      await loadAndRender();
    } catch (e) {
      showToast('Preset failed: ' + (e && e.message ? e.message : String(e)), 'error');
    } finally {
      if (progTimer) {
        window.clearInterval(progTimer);
      }
      if (progressBar && progressBar.parentNode) {
        progressBar.parentNode.removeChild(progressBar);
      }
    }
  }

  async function restoreProcessLabSnapshot(){
    if (!window.falcon || !window.falcon.restoreProcessLab) {
      showToast('Process Lab restore engine not available on this build.', 'error');
      return;
    }
    const okModal = await showConfirmModal({
      title: 'Restore Process Lab snapshot?',
      body: 'This will restore service startup types and key Process Lab registry values from the last Process Lab run snapshot. Use this if a preset felt too aggressive or broke features.',
      risk: 'Medium',
      requireTyped: false
    });
    if (!okModal) return;
    try {
      const res = await window.falcon.restoreProcessLab();
      const ok = res && res.ok;
      const stdout = res && res.stdout ? res.stdout : '';
      if (ok && stdout.indexOf('ProcessLabRestore=OK') >= 0) {
        showToast('Process Lab snapshot restored.', 'success');
      } else if (stdout.indexOf('ProcessLabRestore=NoSnapshot') >= 0) {
        showToast('No Process Lab snapshot found yet.', 'warning');
      } else {
        showToast('Process Lab restore did not finish cleanly. Check logs if needed.', ok ? 'warning' : 'error');
      }
      await loadAndRender();
    } catch (e) {
      showToast('Restore failed: ' + (e && e.message ? e.message : String(e)), 'error');
    }
  }

  if (btnSafe) btnSafe.onclick = () => runPreset('safe', 'Safe');
  if (btnComp) btnComp.onclick = () => runPreset('competitive', 'Competitive');
  if (btnExtreme) btnExtreme.onclick = () => runPreset('extreme', 'Extreme');
  if (btnCustom) btnCustom.onclick = () => {
    const panel = document.getElementById('procCustomPanel');
    if (panel && panel.scrollIntoView) {
      panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };
  if (btnRestore) btnRestore.onclick = () => restoreProcessLabSnapshot();
  if (btnFixes) btnFixes.onclick = () => {
    try {
      setRoute('fixes');
      refresh(true);
    } catch(_e) {}
  };

}

async function refresh(resetTabs=true){
  try {
    let cfg = routes[currentRoute];
    if (!cfg) {
      // Fallback – if route is unknown, drop back to home instead of throwing.
      currentRoute = 'home';
      cfg = routes[currentRoute];
      if (!cfg) {
        els.pageTitle.textContent = 'Falcon Optimizer';
        els.pageSub.textContent = 'Navigation error – route not found.';
        els.panel.innerHTML = `<div class="notice notice-error"><strong>Navigation error:</strong> Unknown route. Please restart Falcon or report this.</div>`;
        return;
      }
    }

    els.pageTitle.textContent = cfg.title || 'Falcon Optimizer';
    els.pageSub.textContent = cfg.sub || '';

    if (resetTabs) {
      if (cfg.tabs && cfg.tabs.length > 0) currentTab = cfg.tabs[0];
      else currentTab = null;
    }
    renderTabs(currentRoute);

    if (currentRoute === 'home')       return await renderHome();
    if (currentRoute === 'backups')    return await renderBackups();
    if (currentRoute === 'fixes')      return await renderFixes();
    if (currentRoute === 'stretchLab') return await renderStretchLab();
    if (currentRoute === 'processLab') return await renderProcessLab();
    if (currentRoute === 'bios')       return await renderBiosHelper();
    if (currentRoute === 'themes')     return await renderThemes();
    if (currentRoute === 'explore')    return await renderExplore();
    if (currentRoute === 'fortnite')   return await renderGameProfiles();
    if (currentRoute === 'language')   return await renderLanguage();

    if (currentRoute === 'thermal' && currentTab && currentTab.id === 'cooling') return await renderCoolingDashboard();


    if (currentTab && currentTab.source) {
      return await renderTweaksFromSource(currentTab.source);
    }

    els.panel.innerHTML = `<div class="notice"><strong>Missing data:</strong> No items configured for this section yet.</div>`;
  } catch (e) {
    console.error('Refresh/navigation error', e);
    els.panel.innerHTML = `<div class="notice notice-error"><strong>Navigation error:</strong> ` + escapeHtml(String(e && e.message ? e.message : e)) + `</div>`;
  }
}
function setRoute(route){
  currentRoute = route;
  setActiveNav(route);
  refresh(true);
}

document.querySelectorAll('.nav-item').forEach(btn=>{
  btn.addEventListener('click', () => setRoute(btn.dataset.route));
});
document.getElementById('refreshBtn').onclick = () => refresh(false);
// Debounce search to avoid re-rendering on every keystroke.
els.searchInput.addEventListener('input', debounce(() => refresh(false), 140));

(async function boot(){
  toggles = await window.falcon.getState();
  setRoute('home');
})();



async function renderExplore(){
  // Phase 2: global optimization explorer (Balanced-safe by default)
  els.panel.innerHTML = `
    <div class="panel" style="margin-top:14px;">
      <div class="card-title">Explore</div>
      <div class="card-desc">Search and run optimizations across the entire catalog. Balanced-safe by default.</div>

      <div style="display:flex; gap:10px; flex-wrap:wrap; margin-top:12px;">
        <input id="exSearch" class="input" placeholder="Search all optimizations…" style="flex:1; min-width:220px;" />
        <select id="exRisk" class="input" style="min-width:160px;">
          <option value="">Risk: Any</option>
          <option value="safe">Risk: Safe</option>
          <option value="warning">Risk: Warning</option>
          <option value="high">Risk: High</option>
          <option value="critical">Risk: Critical</option>
        </select>
        <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
          <input id="exHasRevert" type="checkbox" /> Has revert
        </label>
        <label class="muted" style="display:flex; align-items:center; gap:6px; font-size:12px;">
          <input id="exReboot" type="checkbox" /> Reboot required
        </label>
        <select id="exSort" class="input" style="min-width:170px;">
          <option value="relevance">Sort: Relevance</option>
          <option value="az">Sort: A → Z</option>
          <option value="risk">Sort: Risk (low→high)</option>
        </select>
        <button id="exReload" class="btn btn-ghost">Reload</button>
      </div>

      <div class="divider" style="margin:14px 0;"></div>

      <div style="display:grid; grid-template-columns: 1.25fr 1fr; gap:12px;">
        <div class="card" style="padding:10px;">
          <div class="muted" style="font-size:12px; margin-bottom:8px;">Results</div>
          <div id="exResults" style="max-height:520px; overflow:auto;"></div>
        </div>
        <div class="card" style="padding:10px;">
          <div class="muted" style="font-size:12px; margin-bottom:8px;">Details</div>
          <div id="exDetails" class="muted">Select a result to see details and run it.</div>
        </div>
      </div>
    </div>
  `;

  const els2 = {
    q: document.getElementById('exSearch'),
    risk: document.getElementById('exRisk'),
    hasRevert: document.getElementById('exHasRevert'),
    reboot: document.getElementById('exReboot'),
    sort: document.getElementById('exSort'),
    reload: document.getElementById('exReload'),
    results: document.getElementById('exResults'),
    details: document.getElementById('exDetails')
  };

  const riskOrder = { safe:0, warning:1, high:2, critical:3 };

  function normRisk(x){
    const r = String(x||'').toLowerCase();
    if(!r) return 'safe';
    if(r.includes('critical')) return 'critical';
    if(r.includes('high')) return 'high';
    if(r.includes('warn')) return 'warning';
    return 'safe';
  }

  function extractItems(node, ctx, out){
    if(!node) return;
    if(Array.isArray(node)){
      node.forEach(n=>extractItems(n, ctx, out));
      return;
    }
    if(typeof node !== 'object') return;

    const hasApply = node.apply && Array.isArray(node.apply.steps) && node.apply.steps.length;
    const hasRevert = node.revert && Array.isArray(node.revert.steps) && node.revert.steps.length;

    // Many catalogs use "items" nesting
    if(Array.isArray(node.items) && node.items.length){
      const nextCtx = { ...ctx };
      if(node.title) nextCtx.path = (ctx.path ? ctx.path + ' → ' : '') + String(node.title);
      if(node.label && !node.title) nextCtx.path = (ctx.path ? ctx.path + ' → ' : '') + String(node.label);
      extractItems(node.items, nextCtx, out);
    }

    // Leaf item heuristic
    if(node.id && (hasApply || Array.isArray(node.steps))) {
      const title = String(node.title || node.label || node.name || node.id);
      const desc = String(node.desc || node.description || '');
      out.push({
        id: String(node.id),
        title,
        desc,
        file: ctx.file,
        path: ctx.path || ctx.file,
        risk: normRisk(node.risk || node.level || node.severity),
        reboot: !!(node.rebootRequired || node.reboot || node.requiresReboot),
        hasRevert: !!hasRevert,
        steps: (hasApply ? node.apply.steps : (Array.isArray(node.steps) ? node.steps : [])),
        revertSteps: (hasRevert ? node.revert.steps : [])
      });
    }
  }

  async function loadIndex(){
    const manifest = await window.falcon.readJson('tweaks/_manifest.json');
    const files = (manifest && Array.isArray(manifest.files)) ? manifest.files : [];
    const out = [];
    for (const f of files){
      // Skip perf raw catalog; it is a step dump without per-item metadata.
      if(String(f).includes('/_performance_library/')) continue;
      let j = null;
      try { j = await window.falcon.readJson(f); } catch(_e){ continue; }
      const ctx = { file: f.replace('tweaks/',''), path: '' };
      extractItems(j, ctx, out);
    }
    return out;
  }

  let index = [];
  let lastQuery = '';
  let selected = null;

  function matches(item, q){
    if(!q) return true;
    const s = (item.title + ' ' + item.desc + ' ' + item.path + ' ' + item.file).toLowerCase();
    return s.includes(q);
  }

  function score(item, q){
    if(!q) return 0;
    let sc = 0;
    const t = item.title.toLowerCase();
    const d = item.desc.toLowerCase();
    if(t.includes(q)) sc += 8;
    if(d.includes(q)) sc += 3;
    if((item.path||'').toLowerCase().includes(q)) sc += 2;
    // shorter title hits slightly higher
    sc += Math.max(0, 6 - Math.floor(item.title.length/12));
    return sc;
  }

  function renderResults(){
    const q = String(els2.q.value||'').trim().toLowerCase();
    const risk = String(els2.risk.value||'');
    const wantRevert = !!els2.hasRevert.checked;
    const wantReboot = !!els2.reboot.checked;
    const sort = String(els2.sort.value||'relevance');

    let items = index.filter(it=>{
      if(risk && it.risk !== risk) return false;
      if(wantRevert && !it.hasRevert) return false;
      if(wantReboot && !it.reboot) return false;
      return matches(it, q);
    });

    if(sort === 'az') items.sort((a,b)=>a.title.localeCompare(b.title));
    else if(sort === 'risk') items.sort((a,b)=>(riskOrder[a.risk]||0)-(riskOrder[b.risk]||0) || a.title.localeCompare(b.title));
    else items.sort((a,b)=>score(b,q)-score(a,q) || a.title.localeCompare(b.title));

    // limit render
    const max = 400;
    const shown = items.slice(0, max);

    els2.results.innerHTML = shown.map(it=>{
      const badge = (it.risk === 'critical') ? 'badge extreme' : ((it.risk === 'high' || it.risk === 'warning') ? 'badge warn' : 'badge safe');
      const meta = `${escapeHtml(it.path)}`;
      return `
        <div class="list-row" data-ex-id="${escapeHtml(it.id)}" style="padding:8px; border-radius:10px; cursor:pointer;">
          <div style="display:flex; justify-content:space-between; gap:10px;">
            <div style="font-weight:700;">${escapeHtml(it.title)}</div>
            <div class="${badge}" style="text-transform:uppercase;">${escapeHtml(it.risk)}</div>
          </div>
          <div class="muted" style="font-size:11px; margin-top:2px;">${meta}</div>
          ${it.desc ? `<div class="muted" style="font-size:12px; margin-top:4px;">${escapeHtml(it.desc)}</div>` : ``}
        </div>
      `;
    }).join('') + (items.length > max ? `<div class="muted" style="padding:8px;">Showing ${max} of ${items.length}. Refine search/filters.</div>` : (items.length===0?`<div class="muted" style="padding:8px;">No matches.</div>`:''));

    els2.results.querySelectorAll('[data-ex-id]').forEach(row=>{
      row.onclick = ()=>{
        const id = row.getAttribute('data-ex-id');
        selected = index.find(x=>x.id===id) || null;
        renderDetails();
      };
    });
  }

  function renderDetails(){
    const it = selected;
    if(!it){
      els2.details.innerHTML = `<div class="muted">Select a result to see details and run it.</div>`;
      return;
    }
    const badge = (it.risk === 'critical') ? 'badge extreme' : ((it.risk === 'high' || it.risk === 'warning') ? 'badge warn' : 'badge safe');
    els2.details.innerHTML = `
      <div style="display:flex; justify-content:space-between; gap:10px; align-items:flex-start;">
        <div>
          <div style="font-weight:800; font-size:14px;">${escapeHtml(it.title)}</div>
          <div class="muted" style="font-size:12px; margin-top:4px;">${escapeHtml(it.path)}</div>
        </div>
        <div class="${badge}" style="text-transform:uppercase;">${escapeHtml(it.risk)}</div>
      </div>

      ${it.desc ? `<div style="margin-top:10px;">${escapeHtml(it.desc)}</div>` : ``}

      <div class="divider" style="margin:12px 0;"></div>

      <div class="muted" style="font-size:12px;">Requirements</div>
      <div style="margin-top:6px; display:flex; gap:8px; flex-wrap:wrap;">
        <span class="badge">${it.reboot ? 'Reboot recommended' : 'No reboot expected'}</span>
        <span class="badge">${it.hasRevert ? 'Revert available' : 'No revert steps'}</span>
        <span class="badge">${escapeHtml(it.file)}</span>
      </div>

      <div style="display:flex; gap:10px; margin-top:12px; flex-wrap:wrap;">
        <button id="exRunApply" class="btn btn-red">Apply</button>
        <button id="exRunRevert" class="btn btn-ghost" ${it.hasRevert ? '' : 'disabled'}>Revert</button>
      </div>

      <div class="muted" style="font-size:12px; margin-top:10px;">This runs the exact steps from the catalog. Balanced mode: critical items should be used intentionally.</div>
    `;

    const applyBtn = document.getElementById('exRunApply');
    const revBtn = document.getElementById('exRunRevert');

    if(applyBtn) applyBtn.onclick = async ()=>{
      try{
        setRunning(true);
        const res = await window.falcon.runTweak({ id: it.id, mode:'apply', steps: it.steps, revertSteps: it.revertSteps, meta:{ title: it.title, location: it.path, risk: it.risk } });
        toast(res && res.ok ? 'Applied' : 'Failed', (res && res.ok) ? 'ok' : 'error');
      }catch(e){
        toast(String(e && e.message ? e.message : e), 'error');
      }finally{
        setRunning(false);
      }
    };
    if(revBtn) revBtn.onclick = async ()=>{
      try{
        setRunning(true);
        const res = await window.falcon.runTweak({ id: it.id, mode:'revert', steps: it.revertSteps, meta:{ title: it.title, location: it.path, risk: it.risk } });
        toast(res && res.ok ? 'Reverted' : 'Failed', (res && res.ok) ? 'ok' : 'error');
      }catch(e){
        toast(String(e && e.message ? e.message : e), 'error');
      }finally{
        setRunning(false);
      }
    };
  }

  async function init(){
    els2.results.innerHTML = `<div class="muted" style="padding:8px;">Indexing…</div>`;
    index = await loadIndex();
    renderResults();
  }

  // wire controls
  [els2.q, els2.risk, els2.hasRevert, els2.reboot, els2.sort].forEach(el=>{
    if(!el) return;
    el.addEventListener('input', debounce(renderResults, 120));
    el.addEventListener('change', debounce(renderResults, 120));
  });
  if(els2.reload) els2.reload.onclick = ()=>init();

  await init();
}


async function runItem(item, mode) {
  const stepsRaw = getStepsFor(item, mode);
  const steps = adjustStepsForHwProfile(item, mode, stepsRaw);
  if (!steps || steps.length === 0) {
    alert("This item has no runnable steps yet.");
    return { ok: false };
  }
  const label = item && item.name ? item.name : 'Optimization';
  return await window.falcon.runSteps({ steps, meta: { label, hwProfile: currentHwProfile || 'auto' } });
}



document.addEventListener("DOMContentLoaded", () => {

  // Phase 4: sidebar toggle + persistence
  try{
    const toggleBtn = document.getElementById('sidebarToggle');
    const applySidebarState = ()=>{
      const collapsed = localStorage.getItem('falcon_sidebar_collapsed') === '1';
      document.body.classList.toggle('sidebar-collapsed', collapsed);
    };
    const closeMobileSidebar = ()=>{
      document.body.classList.remove('sidebar-open');
    };
    applySidebarState();
    if(toggleBtn){
      toggleBtn.addEventListener('click', (e)=>{
        e.preventDefault();
        // Mobile: open/close overlay sidebar
        if(window.matchMedia && window.matchMedia('(max-width: 860px)').matches){
          document.body.classList.toggle('sidebar-open');
          return;
        }
        const next = !document.body.classList.contains('sidebar-collapsed');
        document.body.classList.toggle('sidebar-collapsed', next);
        localStorage.setItem('falcon_sidebar_collapsed', next ? '1' : '0');
      });
    }
    // Click-out to close on mobile
    document.addEventListener('click', (e)=>{
      if(!document.body.classList.contains('sidebar-open')) return;
      const sidebar = document.querySelector('.sidebar');
      if(!sidebar) return;
      if(sidebar.contains(e.target) || (toggleBtn && toggleBtn.contains(e.target))) return;
      closeMobileSidebar();
    }, true);
    // Close mobile sidebar on route change (nav click)
    document.querySelectorAll('.nav-item').forEach(btn=>{
      btn.addEventListener('click', ()=>{ if(window.matchMedia && window.matchMedia('(max-width: 860px)').matches) closeMobileSidebar(); }, {capture:true});
    });
  }catch(_e){}


  // Phase 1: drawer controls
  try{
    const btnRH = document.getElementById('btnRunHistory');
    const btnClose = document.getElementById('btnRunHistoryClose');
    const drawer = document.getElementById('runHistoryDrawer');
    if(btnRH && drawer){
      btnRH.addEventListener('click', ()=>{ drawer.style.display='flex'; __renderRunHistory(); });
    }
    if(btnClose && drawer){
      btnClose.addEventListener('click', ()=>{ drawer.style.display='none'; });
    }
  }catch(e){}

  // Phase 1: Global search (indexes visible optimization cards + buttons by text)
  try{
    const inp = document.getElementById('globalSearch');
    const results = document.getElementById('globalSearchResults');
    const getCandidates = () => {
      // Search common title nodes across pages
      const nodes = Array.from(document.querySelectorAll('[data-tweak-id], .tweak-card, .card, .opt-card, button, .btn'));
      const seen = new Set();
      const items = [];
      for(const n of nodes){
        const txt = (n.getAttribute && (n.getAttribute('data-title')||n.getAttribute('aria-label'))) || n.textContent || '';
        const t = txt.trim().replace(/\s+/g,' ');
        if(!t || t.length<3) continue;
        const key = t.toLowerCase();
        if(seen.has(key)) continue;
        seen.add(key);
        items.push({ title: t.slice(0,120), node: n });
        if(items.length>400) break;
      }
      return items;
    };
    let cache = null;
    let cacheAt = 0;
    const ensureCache = () => {
      const now = Date.now();
      if(!cache || (now-cacheAt)>5000){
        cache = getCandidates();
        cacheAt = now;
      }
      return cache;
    };
    const render = (list) => {
      if(!results) return;
      results.innerHTML = '';
      if(!list.length){ results.style.display='none'; return; }
      for(const it of list.slice(0,10)){
        const row = document.createElement('div');
        row.className='sr-item';
        row.innerHTML = `<div class="sr-title">${__eh(it.title)}</div><div class="sr-meta">Jump to control</div>`;
        row.addEventListener('click', ()=>{
          try{
            results.style.display='none';
            inp.blur();
            it.node.scrollIntoView({behavior:'smooth', block:'center'});
            // focus/click if possible
            if(typeof it.node.focus==='function') it.node.focus();
          }catch(e){}
        });
        results.appendChild(row);
      }
      results.style.display='';
    };
    if(inp && results){
      inp.addEventListener('input', ()=>{
        const q = (inp.value||'').trim().toLowerCase();
        if(!q){ results.style.display='none'; return; }
        const items = ensureCache();
        const hits = items.filter(x => x.title.toLowerCase().includes(q));
        render(hits);
      });
      inp.addEventListener('keydown', (e)=>{
        if(e.key==='Escape'){ results.style.display='none'; inp.value=''; }
      });
      document.addEventListener('click', (e)=>{
        if(!results.contains(e.target) && e.target!==inp) results.style.display='none';
      });
    }
  }catch(e){}
  // Initialize toast host + wrap backend runSteps for success/fail notifications
  try {
    const host = document.getElementById('themeFxToastHost');
    if (host) toastHost = host;
  } catch (e) {
    console && console.warn && console.warn('toast host init failed', e);
  }

  
  // Inline custom controllers: enable/disable inputs based on preset selection (prevents "can't type" bugs).
  function syncInlineCustomControls(scope){
    try{
      const root = scope || document;
      // Timer Resolution
      root.querySelectorAll('[data-timer-preset]').forEach(sel=>{
        const card = sel.closest('.card') || sel.parentElement;
        const input = (card && card.querySelector) ? card.querySelector('[data-timer-custom]') : null;
        if(input){ input.readOnly = String(sel.value) !== 'custom'; }
      });
      // Priority Separation (Win32PrioritySeparation)
      root.querySelectorAll('[data-ps-mode]').forEach(sel=>{
        const card = sel.closest('.card') || sel.parentElement;
        const input = (card && card.querySelector) ? card.querySelector('[data-ps-custom]') : null;
        if(input){ input.readOnly = String(sel.value) !== 'custom'; }
      });
    }catch(_e){}
  }

  document.addEventListener('change', (e)=>{
    const t = e.target;
    if(!(t instanceof HTMLElement)) return;
    if(t.matches('[data-timer-preset], [data-ps-mode]')){
      syncInlineCustomControls(t.closest('.card') || document);
    }
  });

  // When toggles expand panels, resync after the DOM updates.
  document.addEventListener('click', (e)=>{
    const t = e.target;
    if(!(t instanceof HTMLElement)) return;
    if(t.classList && t.classList.contains('toggle')){
      setTimeout(()=>syncInlineCustomControls(t.closest('.card') || document), 0);
    }
  });

// Hardware profile chips (Auto / Low / Mid / High)
  try {
    const grp = document.getElementById('hwProfileGroup');
    if (grp) {
      // Restore last selection
      try {
        const saved = window.localStorage ? window.localStorage.getItem('falcon.hwProfile') : null;
        if (saved) currentHwProfile = saved;
      } catch (_e) {}
      grp.querySelectorAll('[data-hw]').forEach(btn => {
        const val = btn.getAttribute('data-hw') || 'auto';
        btn.classList.toggle('active', val === currentHwProfile);
        btn.addEventListener('click', () => {
          currentHwProfile = val;
          grp.querySelectorAll('[data-hw]').forEach(b2 => {
            const v2 = b2.getAttribute('data-hw') || 'auto';
            b2.classList.toggle('active', v2 === currentHwProfile);
          });
          try {
            if (window.localStorage) window.localStorage.setItem('falcon.hwProfile', currentHwProfile);
          } catch (_e) {}
          showToast('Hardware profile set to ' + (val === 'auto' ? 'Auto-detect' : val.toUpperCase()), 'info');
        });
      });
    }
  } catch (e) {
    console && console.warn && console.warn('hwProfile init failed', e);
  }

  try {
    if (window.falcon && typeof window.falcon.runSteps === "function" && !window.falcon.__wrappedForToast) {
      const origRunSteps = window.falcon.runSteps.bind(window.falcon);
      window.falcon.runSteps = async (args) => {
        __setRunning(true);
        const startedAt = Date.now();
        const res = await origRunSteps(args || {});
        __setRunning(false);
        try {
          const ok = !!(res && res.ok);
          const label = args && args.meta && args.meta.label ? args.meta.label : "Optimization batch";
          if (ok) {
            showToast(label + " applied successfully.", "success");
          } else {
            showToast(label + " failed or partially applied. Check log for details.", "error");
          }

        try{
          const ok2 = !!(res && res.ok);
          const label2 = args && args.meta && args.meta.label ? args.meta.label : "Optimization batch";
          lastLogFile = res && res.logFile ? res.logFile : lastLogFile;
          __pushRunHistory({ ts: Date.now(), ok: ok2, label: label2, logFile: (res && res.logFile) ? res.logFile : null, note: (Date.now()-startedAt) + ' ms' });
        }catch(e){}
        } catch (inner) {
          console && console.warn && console.warn('toast wrapper failed', inner);
        }
        return res;
      };
      window.falcon.__wrappedForToast = true;
    }

    // Ensure ALL actions (Fixes / Tools / Scripts) surface success/fail toasts too.
    // This wrapper is intentionally minimal: it does not change behavior, only adds UI feedback.
    if (window.falcon && typeof window.falcon.runAction === "function" && !window.falcon.__wrappedRunActionToast) {
      const origRunAction = window.falcon.runAction.bind(window.falcon);
      window.falcon.runAction = async (args) => {
        __setRunning(true);
        const startedAt = Date.now();
        let res = null;
        try {
          res = await origRunAction(args || {});
        } catch (e) {
          res = { ok:false, error: (e && e.message) ? e.message : String(e) };
        }
        __setRunning(false);
        try {
          const ok = !!(res && res.ok);
          const label = (args && args.meta && args.meta.label)
            ? args.meta.label
            : (args && args.tweak && args.tweak.name)
              ? args.tweak.name
              : (args && args.tweak && args.tweak.id)
                ? String(args.tweak.id)
                : (args && args.action)
                  ? String(args.action)
                  : 'Action';
          if (ok) {
            showToast(label + ' completed successfully.', 'success');
          } else {
            const err = (res && (res.error || res.message)) ? String(res.error || res.message) : 'Failed or partially applied. Check output/log.';
            showToast(label + ': ' + err, 'error');
          }
          try{
            lastLogFile = res && res.logFile ? res.logFile : lastLogFile;
            __pushRunHistory({ ts: Date.now(), ok: ok, label: label, logFile: (res && res.logFile) ? res.logFile : null, note: (Date.now()-startedAt) + ' ms', stdout: (res && (res.stdout||res.rawStdout)) ? (res.stdout||res.rawStdout) : '', stderr: (res && (res.stderr||res.rawStderr)) ? (res.stderr||res.rawStderr) : '' });
          }catch(_e){}
        } catch (inner) {
          console && console.warn && console.warn('runAction toast failed', inner);
        }
        return res;
      };
      window.falcon.__wrappedRunActionToast = true;
    }

    if (window.falcon && typeof window.falcon.runTweak === "function" && !window.falcon.__wrappedRunTweakToast) {
      const origRunTweak = window.falcon.runTweak.bind(window.falcon);
      window.falcon.runTweak = async (payload) => {
        __setRunning(true);
        const startedAt = Date.now();
        const res = await origRunTweak(payload || {});
        __setRunning(false);
        try {
          const ok = !!(res && res.ok);
          const id = payload && payload.id ? payload.id : "Profile";
          const label = payload && payload.meta && payload.meta.profile ? payload.meta.profile : id;
          if (ok) {
            showToast("Profile " + label + " applied successfully.", "success");
          } else {
            showToast("Profile " + label + " failed or partially applied. Check log for details.", "error");
          }
        } catch (inner) {
          console && console.warn && console.warn('runTweak toast failed', inner);
        }
        return res;
      };
      window.falcon.__wrappedRunTweakToast = true;
    }
  } catch (e) {
    console && console.warn && console.warn('wrap runSteps failed', e);
  }



  const btn = document.getElementById("btnSelfTest");
  const statusEl = document.getElementById("selfTestStatus");
  const outEl = document.getElementById("selfTestOutput");
  if (btn) {
    btn.addEventListener("click", async () => {
      if (statusEl) statusEl.textContent = "Running…";
      if (outEl) { outEl.style.display = "none"; outEl.textContent = ""; }
      try {
        const res = await window.falcon.selfTest();
        const logInfo = res && res.logFile ? res.logFile : "n/a";
        if (statusEl) {
          statusEl.textContent = (res && res.ok)
            ? ("OK (log: " + logInfo + ")")
            : ("FAILED (log: " + logInfo + ")");
        }
        if (outEl) {
          outEl.style.display = "block";
          outEl.textContent = (res && res.output ? res.output : []).join("\n");
        }
      } catch (e) {
        if (statusEl) statusEl.textContent = "FAILED";
        if (outEl) {
          outEl.style.display = "block";
          outEl.textContent = String(e && e.message ? e.message : e);
        }
      }
    });
  }

// Run status controls
  if (els.openLogBtn) {
    els.openLogBtn.onclick = async () => {
      if (lastLogFile) await window.falcon.openPath(lastLogFile);
    };
  }
  if (els.clearRunBtn) {
    els.clearRunBtn.onclick = () => {
      els.runStatus.style.display = 'none';
      els.runOutput.textContent = '';
      els.runProgress.value = 0;
      lastLogFile = null;
    };
  }

  // GPU vendor chips
  try {
    const gvRoot = document.querySelector('.gpu-vendor-chips');
    if (gvRoot) {
      // Restore saved vendor
      try {
        const savedVendor = window.localStorage ? window.localStorage.getItem('falcon.gpuVendor') : null;
        if (savedVendor) currentGpuVendor = savedVendor;
      } catch (_e) {}
      gvRoot.querySelectorAll('[data-gpu-vendor]').forEach(btn => {
        const val = btn.getAttribute('data-gpu-vendor') || 'auto';
        btn.classList.toggle('active', val === currentGpuVendor);
        btn.addEventListener('click', () => {
          currentGpuVendor = val;
          gvRoot.querySelectorAll('[data-gpu-vendor]').forEach(b2 => {
            const v2 = b2.getAttribute('data-gpu-vendor') || 'auto';
            b2.classList.toggle('active', v2 === currentGpuVendor);
          });
          try {
            if (window.localStorage) window.localStorage.setItem('falcon.gpuVendor', currentGpuVendor);
          } catch (_e) {}
          const label = (val === 'auto')
            ? 'Auto-detect from GPU name'
            : (val.toUpperCase());
          showToast('GPU vendor mode set to ' + label + '.', 'info');
        });
      });
    }
  } catch (e) {
    console && console.warn && console.warn('gpu vendor init failed', e);
  }

});

async function detectRunningGame(){
  if (!window.falcon || !window.falcon.listProcesses) return null;
  try {
    const res = await window.falcon.listProcesses();
    if (!res || !res.ok) return null;
    const procs = res.processes || [];
    const lower = procs.map(p => (p.name || '').toLowerCase());
    const candidates = [
      { id: 'fortnite', label: 'Fortnite', matches: ['fortniteclient-win64-shipping.exe', 'fortniteclient-win64-shipping'] },
      { id: 'valorant', label: 'Valorant', matches: ['valorant-win64-shipping.exe', 'valorant.exe'] },
      { id: 'apex', label: 'Apex Legends', matches: ['r5apex.exe'] },
      { id: 'overwatch', label: 'Overwatch 2', matches: ['overwatch.exe', 'overwatch2.exe'] },
      { id: 'cs2', label: 'Counter-Strike 2', matches: ['cs2.exe', 'csgo.exe'] },
      { id: 'rocketleague', label: 'Rocket League', matches: ['rocketleague.exe'] },
      { id: 'gta', label: 'GTA V', matches: ['gta5.exe', 'gtav.exe'] },
      { id: 'league', label: 'League of Legends', matches: ['leagueclientux.exe', 'leagueclient.exe'] },
      { id: 'geforcenow', label: 'GeForce NOW', matches: ['nvidia geforce now.exe', 'geforcenow.exe'] }
    ];
    for (const g of candidates) {
      const found = lower.some(n => g.matches.some(m => n === m || n.includes(m)));
      if (found) return g;
    }
    return null;
  } catch (e) {
    try { console && console.warn && console.warn('detectRunningGame failed', e); } catch(_e) {}
    return null;
  }
}

async function buildGameDetectionBanner(gridEl){
  if (!gridEl) return;
  const detected = await detectRunningGame();
  if (!detected) return;
  const banner = document.createElement('div');
  banner.className = 'panel game-detect-banner';
  banner.innerHTML = `
    <div class="card-title">Detected running game: ${detected.label}</div>
    <div class="card-desc">Falcon Optimizer can prioritize this game with per-title QoS policies and Game Mode tweaks.</div>
    <div class="card-actions">
      <button class="btn secondary" id="detectedGameView">View recommended tweaks for ${detected.label}</button>
      <button class="btn primary" id="detectedGameApply">Apply per-game optimizations</button>
    </div>
  `;
  els.panel.insertBefore(banner, els.panel.firstChild);

  const viewBtn = banner.querySelector('#detectedGameView');
  const applyBtn = banner.querySelector('#detectedGameApply');

  if (viewBtn) {
    viewBtn.onclick = () => {
      // We are already on the Game Specific section when this banner is used,
      // but calling refresh keeps things consistent.
      try { showToast('Scroll down to the highlighted game-specific tweaks for ' + detected.label + '.', 'info'); } catch(_e) {}
    };
  }
  if (applyBtn) {
    applyBtn.onclick = async () => {
      try {
        showToast('Applying recommended network / priority tweaks for ' + detected.label + '…', 'info');
        // We do not hard-code per-game logic here; instead, users can toggle
        // the QoS and Game Mode items in this section. This button is a
        // gentle helper, not an aggressive auto-tuner.
      } catch (e) {
        try { showToast('Unable to apply automatic per-game tweaks. Use the manual cards below.', 'error'); } catch(_e) {}
      }
    };
  }
}

const gamePriorityTargets = [
  { id: 'fortnite', label: 'Fortnite', policyName: 'Falcon Fortnite DSCP46', exePattern: '*FortniteClient-Win64-Shipping.exe' },
  { id: 'overwatch2', label: 'Overwatch 2', policyName: 'Falcon Overwatch DSCP46', exePattern: '*Overwatch.exe' },
  { id: 'apex', label: 'Apex Legends', policyName: 'Falcon Apex Legends DSCP46', exePattern: '*r5apex.exe' },
  { id: 'geforceNow', label: 'GeForce NOW', policyName: 'Falcon GeForce NOW DSCP46', exePattern: '*GeForceNOW.exe' },
  { id: 'valorant', label: 'Valorant', policyName: 'Falcon Valorant DSCP46', exePattern: '*VALORANT-Win64-Shipping.exe' },
  { id: 'cs2', label: 'CS2', policyName: 'Falcon CS2 DSCP46', exePattern: '*cs2.exe' },
  { id: 'rocketLeague', label: 'Rocket League', policyName: 'Falcon Rocket League DSCP46', exePattern: '*RocketLeague.exe' },
  { id: 'gta5', label: 'GTA V', policyName: 'Falcon GTA DSCP46', exePattern: '*GTA5.exe' },
  { id: 'league', label: 'League of Legends', policyName: 'Falcon League of Legends DSCP46', exePattern: '*League of Legends.exe' }
];

function buildGamePrioritySchedulerPanel() {
  const headerDesc = 'Select which supported games should receive high-priority QoS (DSCP 46) and optionally configure a custom .exe. This uses the same per-game policies as the individual toggles and is fully reversible.';
  const logText = escapeHtml(lastLog || '');
  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Game Priority Scheduler</div>
      <div class="card-desc">${__eh(headerDesc)}</div>
      <div id="gamePriorityList" class="grid"></div>
      <div class="card-actions" style="margin-top:12px;display:flex;flex-wrap:wrap;gap:8px;">
        <button class="btn primary" id="gamePriorityApply">Apply DSCP 46 for selected games</button>
        <button class="btn" id="gamePriorityRemove">Remove QoS policies for selected games</button>
      </div>
      <div class="card-title" style="margin-top:20px;">Custom app QoS</div>
      <div class="card-desc">Enter a full path or exe name to give any app the same DSCP 46 treatment. This creates a policy named "Falcon Custom DSCP46" that you can remove at any time.</div>
      <div class="field">
        <label class="field-label">Custom .exe name or path</label>
        <input class="input" id="gamePriorityCustomExe" placeholder="Example: C:\\Games\\MyGame\\Game.exe or MyGame.exe" />
      </div>
      <div class="card-actions" style="margin-top:8px;display:flex;flex-wrap:wrap;gap:8px;">
        <button class="btn primary" id="gamePriorityCustomApply">Apply DSCP 46 for custom app</button>
        <button class="btn" id="gamePriorityCustomRemove">Remove custom QoS policy</button>
      </div>
    </div>
    <div class="panel">
      <div class="card-title">Last action output</div>
      <div class="card-desc">Most recent PowerShell output</div>
      <pre class="log">${logText}</pre>
    </div>
  `;

  const listEl = document.getElementById('gamePriorityList');
  if (listEl) {
    gamePriorityTargets.forEach(g => {
      const card = document.createElement('div');
      card.className = 'card';
      const desc = `${g.label} traffic will be tagged with DSCP 46 (Expedited Forwarding) on both UDP and TCP using a per-game NetQos policy. Safe to remove at any time via Falcon Optimizer.`;
      card.innerHTML = `
        <div class="card-title">${__eh(g.label)}</div>
        <div class="card-desc">${__eh(desc)}</div>
        <div class="badges">
          <span class="badge">Network</span>
          <span class="badge">QoS DSCP 46</span>
        </div>
        <label class="field-label" style="margin-top:6px;display:flex;align-items:center;gap:6px;">
          <input type="checkbox" class="gp-checkbox" data-game-id="${g.id}">
          Include in this run
        </label>
      `;
      listEl.appendChild(card);
    });
  }

  const getSelectedGames = () => {
    const boxes = Array.from(document.querySelectorAll('.gp-checkbox'));
    return boxes
      .filter(b => b.checked)
      .map(b => {
        const id = b.getAttribute('data-game-id');
        return gamePriorityTargets.find(g => g.id === id);
      })
      .filter(Boolean);
  };

  const applyBtn = document.getElementById('gamePriorityApply');
  const removeBtn = document.getElementById('gamePriorityRemove');
  const customApplyBtn = document.getElementById('gamePriorityCustomApply');
  const customRemoveBtn = document.getElementById('gamePriorityCustomRemove');

  async function runStepsWithLog(steps, successMsg) {
    if (!window.falcon || !window.falcon.runSteps) return;
    const res = await window.falcon.runSteps({ steps, meta: { label: 'Game QoS DSCP46 batch' } });
    try {
      const ok = !!(res && res.ok);
      showToast(ok ? (successMsg || 'QoS batch applied.') : 'QoS batch failed. Check log.', ok ? 'success' : 'error');
    } catch (e) {}
    lastLog = (res && ((res.stdout || '') + (res.stderr || ''))) || '';
    refresh(false);
  }

  if (applyBtn) {
    applyBtn.onclick = async () => {
      const selected = getSelectedGames();
      if (!selected.length) {
        showToast('Select at least one game to prioritize.', 'error');
        return;
      }
      const steps = selected.map(g => ({
        type: 'cmd',
        shell: 'cmd',
        command: "powershell -NoProfile -ExecutionPolicy Bypass -Command \\\"New-NetQosPolicy -Name '" + g.policyName + "' -AppPathNameMatchCondition '" + g.exePattern + "' -DSCPAction 46 -PolicyStore ActiveStore -ErrorAction SilentlyContinue\\\""
      }));
      const names = selected.map(g => g.label).join(', ');
      await runStepsWithLog(steps, 'Applied DSCP 46 QoS for: ' + names);
    };
  }

  if (removeBtn) {
    removeBtn.onclick = async () => {
      const selected = getSelectedGames();
      if (!selected.length) {
        showToast('Select at least one game to remove policies for.', 'error');
        return;
      }
      const steps = selected.map(g => ({
        type: 'cmd',
        shell: 'cmd',
        command: "powershell -NoProfile -ExecutionPolicy Bypass -Command \\\"Remove-NetQosPolicy -Name '" + g.policyName + "' -PolicyStore ActiveStore -Confirm:$false -ErrorAction SilentlyContinue\\\""
      }));
      const names = selected.map(g => g.label).join(', ');
      await runStepsWithLog(steps, 'Removed QoS policies for: ' + names);
    };
  }

  if (customApplyBtn) {
    customApplyBtn.onclick = async () => {
      const inp = document.getElementById('gamePriorityCustomExe');
      const raw = inp ? String(inp.value || '').trim() : '';
      if (!raw) {
        showToast('Enter a custom exe name or path first.', 'error');
        return;
      }
      const pattern = raw.indexOf('*') >= 0 ? raw : ('*' + raw);
      const steps = [
        {
          type: 'cmd',
          shell: 'cmd',
          command: "powershell -NoProfile -ExecutionPolicy Bypass -Command \\\"New-NetQosPolicy -Name 'Falcon Custom DSCP46' -AppPathNameMatchCondition '" + pattern + "' -DSCPAction 46 -PolicyStore ActiveStore -ErrorAction SilentlyContinue\\\""
        }
      ];
      await runStepsWithLog(steps, 'Applied DSCP 46 QoS for custom app.');
    };
  }

  if (customRemoveBtn) {
    customRemoveBtn.onclick = async () => {
      const steps = [
        {
          type: 'cmd',
          shell: 'cmd',
          command: "powershell -NoProfile -ExecutionPolicy Bypass -Command \\\"Remove-NetQosPolicy -Name 'Falcon Custom DSCP46' -PolicyStore ActiveStore -Confirm:$false -ErrorAction SilentlyContinue\\\""
        }
      ];
      await runStepsWithLog(steps, 'Removed custom QoS policy.');
    };
  }
}

// --- Custom panel: Network Priority with game scanning + images ---
async function buildNetworkPriorityPanel(){
  const headerDesc = 'Set per-game QoS (DSCP 46) policies to prioritize game traffic on your PC. If your router honors DSCP, it can help stabilize ping and reduce packet loss.';

  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Network Priority</div>
      <div class="card-desc">${__eh(headerDesc)}</div>
      <div class="toolbar" style="margin-top:12px;display:flex;flex-wrap:wrap;gap:10px;align-items:center;">
        <div class="search-wrap" style="flex:1;min-width:220px;">
          <input id="npSearch" class="search" placeholder="Search games..." />
        </div>
        <button class="btn" id="npRefresh">Refresh</button>
        <button class="btn primary" id="npAddGames">Add games</button>
      </div>
    </div>

    <div class="panel">
      <div class="card-title">How does it work?</div>
      <div class="card-desc">Creates a Windows QoS policy for a game's executable and marks packets with DSCP 46 (Expedited Forwarding). This is reversible at any time.</div>
    </div>

    <div class="panel">
      <div class="card-title">Detected games</div>
      <div class="card-desc" id="npStatus">Scanning for installed games…</div>
      <div id="npList" class="grid" style="margin-top:12px;"></div>
    </div>

    <div class="panel">
      <div class="card-title">Last action output</div>
      <pre class="log" id="npLog">${__eh(lastLog || '')}</pre>
    </div>
  `;

  const listEl = document.getElementById('npList');
  const statusEl = document.getElementById('npStatus');
  const searchEl = document.getElementById('npSearch');

  const render = (games) => {
    const q = (searchEl.value||'').toLowerCase().trim();
    const filtered = (games||[]).filter(g => !q || String(g.name||'').toLowerCase().includes(q));
    if (!filtered.length) {
      listEl.innerHTML = `<div class="card-desc">No supported games detected yet. Use “Add games” to track a custom executable.</div>`;
      return;
    }
    listEl.innerHTML = filtered.map(g => {
      const img = `images/games/${encodeURIComponent(g.id)}.png`;
      return `
        <div class="card game-tile">
          <div class="game-thumb">
            <img src="${img}" alt="" onerror="this.style.display='none'; this.parentElement.classList.add('noimg');" />
            <div class="game-thumb-fallback">${__eh(String(g.name||g.id||'Game'))}</div>
          </div>
          <div class="card-title" style="margin-top:10px;">${__eh(String(g.name||g.id))}</div>
          <div class="card-desc" style="margin-top:6px;word-break:break-all;">${__eh(String(g.exePath||'').slice(0,120))}${(g.exePath && g.exePath.length>120)?'…':''}</div>
          <div class="card-actions" style="margin-top:12px;display:flex;gap:8px;flex-wrap:wrap;">
            <button class="btn primary" data-act="enable" data-id="${__eh(g.id)}">Enable DSCP 46</button>
            <button class="btn" data-act="disable" data-id="${__eh(g.id)}">Disable</button>
          </div>
        </div>
      `;
    }).join('');
  };

  let games = [];
  try {
    games = await window.falcon.scanInstalledGames();
    statusEl.textContent = games.length ? `Detected ${games.length} supported game(s).` : 'No supported games detected.';
  } catch(e) {
    statusEl.textContent = 'Scan failed. Run as admin, or use Add games.';
  }
  render(games);

  const refreshBtn = document.getElementById('npRefresh');
  if (refreshBtn) refreshBtn.onclick = async () => {
    statusEl.textContent = 'Scanning for installed games…';
    try {
      games = await window.falcon.scanInstalledGames();
      statusEl.textContent = games.length ? `Detected ${games.length} supported game(s).` : 'No supported games detected.';
    } catch(e) {
      statusEl.textContent = 'Scan failed.';
    }
    render(games);
  };

  if (searchEl) searchEl.oninput = () => render(games);

  listEl.addEventListener('click', async (ev) => {
    const btn = ev.target && ev.target.closest ? ev.target.closest('button[data-act]') : null;
    if (!btn) return;
    const id = btn.getAttribute('data-id');
    const act = btn.getAttribute('data-act');
    if (!id || !act) return;

    const action = (act === 'enable') ? 'EnableQoS' : 'DisableQoS';
    try {
      const res = await window.falcon.runGamePack(id, action);
      lastLog = (res && (res.stdout || res.stderr)) ? ((res.stdout||'') + '\n' + (res.stderr||'')).trim() : lastLog;
      document.getElementById('npLog').textContent = lastLog || '';
      showToast((act === 'enable') ? 'Enabled DSCP 46 for ' + id : 'Disabled DSCP 46 for ' + id, (res && res.ok) ? 'success' : 'error');
    } catch(e) {
      showToast('Failed to run game policy for ' + id, 'error');
    }
  });

  const addBtn = document.getElementById('npAddGames');
  if (addBtn) addBtn.onclick = () => {
    showToast('Custom game adds: coming next. For now, drop a cover image into images/games and use the built-in supported list.', 'info');
  };
}

// --- Custom panel: Power Plans (Desktop/Laptop) ---
async function buildPowerPlansPanel(){
  const desc = 'Installs real Falcon power plans into Windows (Control Panel → Power Options), lets you apply Windows defaults (Balanced/High/Ultimate), and can auto-switch to a competitive plan when games are running.';

  els.panel.innerHTML = `
    <div class="panel">
      <div class="card-title">Power Plans</div>
      <div class="card-desc">${__eh(desc)}</div>

      <div class="grid" style="margin-top:14px;">
        <div class="card">
          <div class="card-title">Falcon Plans</div>
          <div class="card-desc">Install once, then apply any time. These modify core parking, boost policy, PCIe/USB power saving, and sleep timers.</div>
          <div class="card-actions" style="display:flex; gap:8px; flex-wrap:wrap; margin-top:12px;">
            <button class="btn secondary" id="ppInstallAll">Install / Refresh Falcon plans</button>
            <button class="btn" id="ppRestorePrev">Restore previous plan</button>
          </div>

          <div class="row" style="gap:8px; flex-wrap:wrap; margin-top:12px;">
            <button class="btn primary" id="ppExtreme">Apply Max FPS (Extreme)</button>
            <button class="btn primary" id="ppSustain">Apply Sustained Boost</button>
            <button class="btn primary" id="ppCompetitive">Apply Competitive (Low Latency)</button>
            <button class="btn" id="ppBalanced">Apply Balanced Performance</button>
            <button class="btn" id="ppLaptop">Apply Laptop Gaming</button>
          </div>

          <div class="muted" style="margin-top:10px; font-size:12px;">
            Warning: Extreme can increase temperatures and power draw.
          </div>
        </div>

        <div class="card">
          <div class="card-title">Windows Defaults</div>
          <div class="card-desc">Switch back to Windows defaults anytime.</div>
          <div class="row" style="gap:8px; flex-wrap:wrap; margin-top:12px;">
            <button class="btn" id="ppWinBalanced">Windows Balanced</button>
            <button class="btn" id="ppWinHigh">High Performance</button>
            <button class="btn" id="ppWinUltimate">Ultimate Performance</button>
          </div>
          <div class="muted" style="margin-top:10px; font-size:12px;">
            Note: Ultimate Performance may be unavailable on some Windows editions.
          </div>
        </div>
      </div>
    </div>

    <div class="panel">
      <div class="card-title">Auto-switch when gaming</div>
      <div class="card-desc">When any selected game process is detected, Falcon applies your chosen plan. When none are running, it applies your fallback.</div>

      <div class="row" style="gap:12px; flex-wrap:wrap; align-items:flex-end; margin-top:10px;">
        <label class="field" style="min-width:220px;">
          <span class="field-label">Enabled</span>
          <div class="row" style="align-items:center; gap:10px;">
            <label class="fo-switch"><input type="checkbox" id="ppAutoEnable"><span class="slider"></span></label>
            <span class="muted" id="ppAutoStatus">…</span>
          </div>
        </label>

        <label class="field" style="min-width:220px;">
          <span class="field-label">On game launch</span>
          <select id="ppAutoPlan" class="select">
            <option value="competitive">Competitive (Low Latency)</option>
            <option value="extreme">Max FPS (Extreme)</option>
            <option value="sustain">Sustained Boost</option>
            <option value="balanced">Balanced Performance</option>
            <option value="laptop">Laptop Gaming</option>
          </select>
        </label>

        <label class="field" style="min-width:220px;">
          <span class="field-label">Fallback when games close</span>
          <select id="ppAutoFallback" class="select">
            <option value="previous">Restore previous</option>
            <option value="balanced">Falcon Balanced</option>
            <option value="windows_balanced">Windows Balanced</option>
            <option value="high">High Performance</option>
          </select>
        </label>

        <button class="btn primary" id="ppAutoSave">Save</button>
      </div>

      <label class="field" style="margin-top:10px;">
        <span class="field-label">Game process names (one per line)</span>
        <textarea id="ppAutoExes" class="textarea" rows="6" placeholder="FortniteClient-Win64-Shipping.exe&#10;Valorant.exe"></textarea>
      </label>
    </div>

    <div class="panel">
      <div class="card-title">Vitals</div>
      <div class="card-desc">Real-time CPU load, clocks, (optional) temperature and C-state counters (if available on your system).</div>
      <div class="row" style="gap:10px; flex-wrap:wrap; margin-top:10px;">
        <span class="pill" id="vCpu">CPU: …</span>
        <span class="pill" id="vClk">Clock: …</span>
        <span class="pill" id="vTmp">Temp: …</span>
        <span class="pill" id="vCst">C-states: …</span>
      </div>
    </div>

    <div class="panel">
      <div class="card-title">Latency benchmark</div>
      <div class="card-desc">Runs a short high-resolution timer jitter test and reports basic stats (lower and tighter is better).</div>
      <div class="row" style="gap:8px; flex-wrap:wrap; align-items:flex-end; margin-top:10px;">
        <label class="field" style="min-width:160px;">
          <span class="field-label">Seconds</span>
          <input id="latBenchSec" class="input" value="5" />
        </label>
        <button class="btn primary" id="latBenchRun">Run benchmark</button>
      </div>
      <pre class="log" id="latBenchOut" style="margin-top:10px;">${__eh(lastLog || '')}</pre>
    </div>
  `;

  const logOut = document.getElementById('latBenchOut');

  const setLog = (txt) => {
    lastLog = txt || '';
    if (logOut) logOut.textContent = lastLog;
  };

  const call = async (fn) => {
    try {
      const res = await fn();
      const out = (res && (res.stdout || res.stderr || res.raw)) ? ((res.stdout||'') + '\n' + (res.stderr||'') + '\n' + (res.raw||'')).trim() : '';
      if (out) setLog(out);
      return res;
    } catch (e) {
      setLog(String(e && e.message ? e.message : e));
      return { ok:false };
    }
  };

  const applyFalcon = async (plan) => {
    const res = await call(()=>window.falcon.powerPlansApply(plan));
    showToast(res && res.ok ? ('Applied: ' + plan) : ('Failed: ' + plan), (res && res.ok) ? 'success' : 'error');
  };
  const applyWin = async (which) => {
    const res = await call(()=>window.falcon.powerPlansApplyWindows(which));
    showToast(res && res.ok ? ('Applied Windows: ' + which) : ('Failed Windows: ' + which), (res && res.ok) ? 'success' : 'error');
  };

  // buttons
  const btn = (id, fn) => { const el=document.getElementById(id); if(el) el.onclick=fn; };
  btn('ppInstallAll', async ()=> {
    const res = await call(()=>window.falcon.powerPlansInstallAll());
    showToast(res && res.ok ? 'Installed Falcon power plans.' : 'Failed to install power plans.', (res && res.ok) ? 'success' : 'error');
  });
  btn('ppRestorePrev', async ()=> {
    const res = await call(()=>window.falcon.powerPlansRestorePrevious());
    showToast(res && res.ok ? 'Restored previous plan.' : 'Failed to restore previous plan.', (res && res.ok) ? 'success' : 'error');
  });

  btn('ppExtreme', ()=>applyFalcon('extreme'));
  btn('ppSustain', ()=>applyFalcon('sustain'));
  btn('ppCompetitive', ()=>applyFalcon('competitive'));
  btn('ppBalanced', ()=>applyFalcon('balanced'));
  btn('ppLaptop', ()=>applyFalcon('laptop'));

  btn('ppWinBalanced', ()=>applyWin('balanced'));
  btn('ppWinHigh', ()=>applyWin('high'));
  btn('ppWinUltimate', ()=>applyWin('ultimate'));

  // Auto-switch load/save
  const autoEnable = document.getElementById('ppAutoEnable');
  const autoPlan = document.getElementById('ppAutoPlan');
  const autoFallback = document.getElementById('ppAutoFallback');
  const autoExes = document.getElementById('ppAutoExes');
  const autoStatus = document.getElementById('ppAutoStatus');

  (async ()=>{
    try {
      const res = await window.falcon.getAutoSwitchPowerPlan();
      const st = res && res.state ? res.state : {};
      if (autoEnable) autoEnable.checked = !!st.enabled;
      if (autoPlan) autoPlan.value = (st.plan || 'competitive');
      if (autoFallback) autoFallback.value = (st.fallback || 'balanced');
      if (autoExes) autoExes.value = Array.isArray(st.exes) ? st.exes.join("\n") : '';
      if (autoStatus) autoStatus.textContent = st.enabled ? 'Enabled' : 'Disabled';
    } catch(_e) {}
  })();

  btn('ppAutoSave', async ()=>{
    const state = {
      enabled: !!(autoEnable && autoEnable.checked),
      plan: autoPlan ? autoPlan.value : 'competitive',
      fallback: autoFallback ? autoFallback.value : 'balanced',
      exes: (autoExes && autoExes.value ? autoExes.value.split(/\r?\n/).map(s=>s.trim()).filter(Boolean) : [])
    };
    const res = await window.falcon.setAutoSwitchPowerPlan(state);
    showToast(res && res.ok ? 'Saved auto-switch.' : 'Failed to save auto-switch.', (res && res.ok) ? 'success' : 'error');
    if (autoStatus) autoStatus.textContent = state.enabled ? 'Enabled' : 'Disabled';
  });

  // Vitals poll
  let vitalsTimer = setInterval(async ()=>{
    try {
      const res = await window.falcon.getSystemVitals();
      if (!res || !res.ok) return;
      const cpu = res.cpu || {};
      const elCpu = document.getElementById('vCpu');
      const elClk = document.getElementById('vClk');
      const elTmp = document.getElementById('vTmp');
      const elCst = document.getElementById('vCst');

      if (elCpu) elCpu.textContent = `CPU: ${cpu.loadPercent!=null?cpu.loadPercent+'%':'?'} load`;
      if (elClk) elClk.textContent = `Clock: ${cpu.currentMHz!=null?cpu.currentMHz+' MHz':'?'} / ${cpu.maxMHz!=null?cpu.maxMHz+' MHz':'?'}`;
      if (elTmp) elTmp.textContent = `Temp: ${res.cpuTempC!=null?res.cpuTempC+'°C':'N/A'}`;
      if (elCst) {
        const r = res.residency || {};
        const parts=[];
        if (r.c1!=null) parts.push('C1 '+r.c1+'%');
        if (r.c2!=null) parts.push('C2 '+r.c2+'%');
        if (r.c3!=null) parts.push('C3 '+r.c3+'%');
        elCst.textContent = 'C-states: ' + (parts.length?parts.join(' / '):'N/A');
      }
    } catch(_e) {}
  }, 2000);

  // benchmark
  btn('latBenchRun', async ()=>{
    const secEl = document.getElementById('latBenchSec');
    const seconds = secEl ? Number(String(secEl.value||'5').trim()) : 5;
    setLog('Running benchmark…');
    const res = await window.falcon.runLatencyBenchmark(seconds);
    if (res && res.ok && res.result) {
      const r = res.result;
      const out = [
        `Samples: ${r.samples} (${r.seconds}s)`,
        `Mean: ${r.mean_ms} ms`,
        `Std: ${r.std_ms} ms`,
        `P50: ${r.p50_ms} ms`,
        `P90: ${r.p90_ms} ms`,
        `P99: ${r.p99_ms} ms`,
        `Max: ${r.max_ms} ms`,
      ].join("\n");
      setLog(out);
      showToast('Benchmark complete.', 'success');
    } else {
      setLog((res && (res.error||res.stderr||res.raw)) ? String(res.error||res.stderr||res.raw) : 'Benchmark failed.');
      showToast('Benchmark failed.', 'error');
    }
  });
}



function buildTimerResolutionManagerHtml(){
  return `
  <div class="card" id="timerResCard">
    <div class="card-h">
      <div>
        <div class="card-title">Timer Resolution</div>
        <div class="card-sub">Apply a timer resolution request using a Falcon-managed PowerShell helper (no third-party tools). You can also enable a startup task.</div>
      </div>
      <div class="row" style="gap:8px; align-items:center;">
        <span class="pill" id="timerResStatusPill">Status: …</span>
      </div>
    </div>

    <div class="card-b">
      <div class="row" style="flex-wrap:wrap; gap:10px; align-items:flex-end;">
        <label class="field" style="min-width:220px;">
          <span class="field-label">Preset</span>
          <select id="timerResPreset" class="select">
            <option value="5000">0.5 ms (5000 µs)</option>
            <option value="5040">0.504 ms (5040 µs)</option>
            <option value="5070">0.507 ms (5070 µs)</option>
            <option value="custom">Custom</option>
          </select>
        </label>

        <label class="field" style="min-width:180px;">
          <span class="field-label">Custom (µs)</span>
          <input id="timerResCustom" class="input" type="number" min="1000" step="10" placeholder="5000" disabled />
        </label>

        <button class="btn btn-primary" id="timerResStart">Start</button>
        <button class="btn" id="timerResStop">Stop</button>

        <div class="spacer"></div>

        <button class="btn" id="timerResInstall">Enable on startup</button>
        <button class="btn" id="timerResRemove">Disable startup</button>
      </div>

      <div class="muted" style="margin-top:10px; line-height:1.3;">
        Notes: This runs a hidden PowerShell helper that calls <code>NtSetTimerResolution</code> and stays alive to hold the request. Use <strong>Stop</strong> to end it.
      </div>
    </div>
  </div>`;
}

function setupTimerResolutionManager(){
  const preset = document.getElementById('timerResPreset');
  const custom = document.getElementById('timerResCustom');
  const pill = document.getElementById('timerResStatusPill');
  const btnStart = document.getElementById('timerResStart');
  const btnStop = document.getElementById('timerResStop');
  const btnInstall = document.getElementById('timerResInstall');
  const btnRemove = document.getElementById('timerResRemove');

  if(!preset || !custom || !pill || !btnStart || !btnStop || !btnInstall || !btnRemove) return;

  function getResolution(){
    if (preset.value === 'custom') {
      const v = parseInt(custom.value || '5000', 10);
      return isFinite(v) ? String(v) : '5000';
    }
    return String(preset.value);
  }

  preset.onchange = () => {
    custom.disabled = preset.value !== 'custom';
    if (preset.value !== 'custom') custom.value = '';
  };

  async function refreshStatus(){
    try{
      const s = await window.falcon.timerStatus();
      if (s && s.ok && s.running){
        pill.textContent = `Status: RUNNING (PID ${s.pid || '?'})`;
        pill.classList.add('pill-green');
      } else {
        pill.textContent = 'Status: STOPPED';
        pill.classList.remove('pill-green');
      }
    } catch(e){
      pill.textContent = 'Status: UNKNOWN';
      pill.classList.remove('pill-green');
    }
  }

  async function persistOverride(usStr){
    try {
      const us = parseInt(String(usStr||'5000'), 10);
      if (window.falcon && window.falcon.setLatencyOverrides) {
        await window.falcon.setLatencyOverrides({ timer: { resolution_us: isFinite(us) ? us : 5000 } });
      }
    } catch(_e) {}
  }

  btnStart.onclick = async () => {
    const res = getResolution();
    await persistOverride(res);
    await window.falcon.timerStart(res);
    await refreshStatus();
  };
  btnStop.onclick = async () => {
    await window.falcon.timerStop();
    await refreshStatus();
  };
  btnInstall.onclick = async () => {
    const res = getResolution();
    await persistOverride(res);
    await window.falcon.timerInstallStartup(res);
  };
  btnRemove.onclick = async () => {
    await window.falcon.timerRemoveStartup();
  };

  refreshStatus();
  setInterval(refreshStatus, 4000);
}
// ---------- System Info Modal ----------
function fmtBytes(n){
  const num = Number(n||0);
  if(!isFinite(num) || num<=0) return "—";
  const units = ["B","KB","MB","GB","TB"];
  let v=num, i=0;
  while(v>=1024 && i<units.length-1){ v/=1024; i++; }
  return (i===0? String(Math.round(v)) : v.toFixed(v>=10?1:2)) + " " + units[i];
}
function kvRow(k,v){
  return `<div class="kv"><div class="k">${__eh(k)}</div><div class="v">${__eh(v??"—")}</div></div>`;
}
async function openSystemInfoModal(){
  const bd = document.getElementById('sysInfoBackdrop');
  if(!bd) return;
  bd.style.display='flex';

  // tab switching
  document.querySelectorAll('.sysinfo-tab').forEach(b=>{
    b.onclick = () => {
      document.querySelectorAll('.sysinfo-tab').forEach(x=>x.classList.toggle('active', x===b));
      const tab = b.dataset.sysTab;
      document.querySelectorAll('[data-sys-panel]').forEach(p=>{
        p.style.display = (p.dataset.sysPanel===tab) ? 'block' : 'none';
      });
    };
  });
  const closeBtn = document.getElementById('sysInfoClose');
  if(closeBtn) closeBtn.onclick = () => { bd.style.display='none'; };

  // Populate
  const isPreviewMode = (!window.falcon || !window.falcon.getSystemInfo);
  const info = isPreviewMode ? {
    CPU: "Preview CPU",
    CPUCores: 6,
    CPULogical: 12,
    MotherboardLabel: "Preview Board",
    RAMBytes: 16 * 1024 * 1024 * 1024,
    GPU: "Preview GPU",
    GPUVRAM: 8,
    OS: "Windows 11 (Preview)",
    Disks: [{ Name:"C:", Size:512*1024**3, Free:200*1024**3 }],
    Network: [{ Name:"Ethernet", IPv4:"192.168.1.50", MAC:"00-00-00-00-00-00" }]
  } : await window.falcon.getSystemInfo();

  const cpu = document.querySelector('[data-sys-panel="cpu"]');
  const mb  = document.querySelector('[data-sys-panel="mainboard"]');
  const mem = document.querySelector('[data-sys-panel="memory"]');
  const gpu = document.querySelector('[data-sys-panel="graphics"]');
  const sto = document.querySelector('[data-sys-panel="storage"]');
  const net = document.querySelector('[data-sys-panel="network"]');
  const osP = document.querySelector('[data-sys-panel="os"]');

  if(cpu) cpu.innerHTML = `<div class="sysinfo-title">Processor</div>` +
    kvRow("Name", info.CPU || info.cpu || "—") +
    kvRow("Cores", String(info.CPUCores ?? info.cores ?? "—")) +
    kvRow("Logical processors", String(info.CPULogical ?? info.logical ?? "—")) +
    kvRow("Max clock speed", info.CPUMaxClock ? String(info.CPUMaxClock) : (info.maxClock ? String(info.maxClock) : "—"));

  if(mb) mb.innerHTML = `<div class="sysinfo-title">Mainboard</div>` +
    kvRow("Board", info.MotherboardLabel || info.motherboard || "—") +
    kvRow("BIOS", info.BIOSLabel || info.bios || "—");

  if(mem) mem.innerHTML = `<div class="sysinfo-title">Memory</div>` +
    kvRow("Installed", fmtBytes(info.RAMBytes || info.ramBytes || 0)) +
    (info.RAMSpeed ? kvRow("Speed", String(info.RAMSpeed)) : "") +
    (info.RAMType ? kvRow("Type", String(info.RAMType)) : "");

  if(gpu) gpu.innerHTML = `<div class="sysinfo-title">Graphics</div>` +
    kvRow("GPU", info.GPU || info.gpu || "—") +
    kvRow("VRAM", (info.GPUVRAM!=null ? String(info.GPUVRAM)+" GB" : "—"));

  if(sto){
    const disks = info.Disks || info.disks || [];
    sto.innerHTML = `<div class="sysinfo-title">Storage</div>` + (disks.length
      ? disks.map(d=> `<div class="sysinfo-block">`+
          kvRow("Disk", d.Name || d.name || "—")+
          kvRow("Size", fmtBytes(d.Size || d.size || 0))+
          kvRow("Free", fmtBytes(d.Free || d.free || 0))+
        `</div>`).join('')
      : `<div class="muted">No storage info available.</div>`);
  }

  if(net){
    const nics = info.Network || info.network || [];
    net.innerHTML = `<div class="sysinfo-title">Network</div>` + (nics.length
      ? nics.map(n=> `<div class="sysinfo-block">`+
          kvRow("Adapter", n.Name || n.name || "—")+
          kvRow("IPv4", n.IPv4 || n.ipv4 || "—")+
          kvRow("MAC", n.MAC || n.mac || "—")+
        `</div>`).join('')
      : `<div class="muted">No network info available.</div>`);
  }

  if(osP) osP.innerHTML = `<div class="sysinfo-title">Operating System</div>` +
    kvRow("OS", info.OS || info.os || "—") +
    (info.Build ? kvRow("Build", String(info.Build)) : "");

  // default tab
  const firstTab = document.querySelector('.sysinfo-tab[data-sys-tab="cpu"]');
  if(firstTab) firstTab.click();
}

// ---------- Game Profiles (Paragon-like) ----------
let gpSelected = null;
async function renderGameProfiles(){
  // Hide standard tabs for this route
  els.tabs.style.display='none';

  const cfg = routes.fortnite;
  const games = (cfg && cfg.tabs) ? cfg.tabs : [];
  if(!games.length){
    els.panel.innerHTML = `<div class="notice"><strong>No game profiles:</strong> Nothing configured yet.</div>`;
    return;
  }
  if(!gpSelected) gpSelected = games[0].id;

  let installed = {};
  try{
    if(window.falcon && window.falcon.scanInstalledGames){
      installed = await window.falcon.scanInstalledGames();
    }
  }catch(e){ installed = {}; }

  const listItems = games.map(g=>{
    const isOn = (g.id === gpSelected);
    const isInstalled = Boolean(installed && installed[g.id]);
    const badge = isInstalled ? `<span class="gp-badge ok">INSTALLED</span>` : `<span class="gp-badge">NOT INSTALLED</span>`;
    const label = escapeHtml(g.label || g.id);
    const sub = escapeHtml((g.publisher||g.metaPublisher||"").slice(0,40));
    const icon = label.slice(0,1).toUpperCase();
    return `
      <button class="gp-item ${isOn?'active':''}" data-gpid="${__eh(g.id)}">
        <div class="gp-icon">${icon}</div>
        <div class="gp-meta">
          <div class="gp-name">${label}</div>
          <div class="gp-sub">${sub || '&nbsp;'}</div>
        </div>
        ${badge}
      </button>
    `;
  }).join('');

  const selected = games.find(x=>x.id===gpSelected) || games[0];
  const topTitle = escapeHtml(selected.label || selected.id);

  els.panel.innerHTML = `
    <div class="gp-layout">
      <div class="gp-left">
        <div class="gp-toolbar">
          <input class="input gp-search" id="gpSearch" placeholder="Search" />
          <button class="btn inline small" id="gpRefresh">Refresh</button>
        </div>
        <div class="gp-list" id="gpList">${listItems}</div>
      </div>
      <div class="gp-right">
        <div class="gp-hero">
          <div>
            <div class="gp-hero-title">${topTitle}</div>
            <div class="gp-hero-sub">Fine-tune this profile before applying.</div>
          </div>
          <div class="gp-actions">
            <button class="btn inline small" id="gpApplyAll">Apply Profile</button>
            <button class="btn inline small" id="gpApplyRec">Apply Recommended</button>
            <button class="btn inline small" id="gpReset">Reset</button>
          </div>
        </div>
        <div class="gp-content" id="gpContent"></div>
      </div>
    </div>
  `;

  const wire = () => {
    document.querySelectorAll('.gp-item').forEach(b=>{
      b.onclick = async () => { gpSelected = b.dataset.gpid; await renderGameProfiles(); };
    });
    const search = document.getElementById('gpSearch');
    if(search){
      search.oninput = () => {
        const q = search.value.trim().toLowerCase();
        document.querySelectorAll('.gp-item').forEach(it=>{
          const nm = (it.querySelector('.gp-name')?.textContent||"").toLowerCase();
          it.style.display = nm.includes(q) ? '' : 'none';
        });
      };
    }
    const ref = document.getElementById('gpRefresh');
    if(ref) ref.onclick = async () => { await renderGameProfiles(); };

    const applyAll = document.getElementById('gpApplyAll');
    if(applyAll) applyAll.onclick = async () => {
      // apply every tweak on this tab
      await applyGameProfile(selected, { recommended:false });
    };
    const applyRec = document.getElementById('gpApplyRec');
    if(applyRec) applyRec.onclick = async () => {
      await applyGameProfile(selected, { recommended:true });
    };
    const reset = document.getElementById('gpReset');
    if(reset) reset.onclick = async () => {
      await revertGameProfile(selected);
    };
  };

  // Render tweaks list for selected game
  await renderTweaksInto('gpContent', selected.source);

  wire();
}

async function renderTweaksInto(containerId, source){
  const container = document.getElementById(containerId);
  if(!container) return;
  container.innerHTML = `<div class="muted">Loading…</div>`;
  try{
    const raw = await window.falcon.readJson(source);
    const cat = Array.isArray(raw?.items) ? raw : raw; // existing tweak format
    // reuse existing list renderer by temporarily swapping els.panel
    const prev = els.panel;
    const tmp = document.createElement('div');
    tmp.className='gp-inner';
    container.innerHTML='';
    container.appendChild(tmp);
    els.panel = tmp;
    await renderTweaksFromSource(source);
    try{ tmp.querySelectorAll('.grid').forEach(g=>g.classList.add('hscroll-wheel')); bindHorizontalWheelScroll(tmp); }catch(_){ }
    els.panel = prev;
  }catch(e){
    container.innerHTML = `<div class="notice notice-error"><strong>Load error:</strong> ${__eh(String(e?.message||e))}</div>`;
  }
}

async function applyGameProfile(tab, {recommended=false}={}){
  if(!tab || !tab.source) return;
  try{
    const data = await window.falcon.readJson(tab.source);
    const items = data.items || [];
    const selected = recommended ? items.filter(it=> String(it.recommended||"").toLowerCase()==='true' || it.recommended===1) : items;
    if(!selected.length){
      showToast('No items to apply for this profile.');
      return;
    }
    await runBatch(selected, { label: `${tab.label} profile`, skipConfirm:false });
  }catch(e){
    showToast('Failed to apply profile: ' + String(e?.message||e));
  }
}
async function revertGameProfile(tab){
  if(!tab || !tab.source) return;
  try{
    const data = await window.falcon.readJson(tab.source);
    const items = data.items || [];
    if(!items.length){ showToast('No items to revert for this profile.'); return; }
    // Revert in reverse order for safety
    const rev = [...items].reverse();
    for(const it of rev){
      if(it && it.revert){
        await runTweak(it, 'revert');
      }
    }
    showToast('Profile reverted.');
  }catch(e){
    showToast('Failed to revert profile: ' + String(e?.message||e));
  }
}
