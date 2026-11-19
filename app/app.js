'use strict';
/* Falcon Optimizer 2 — renderer. Vanilla JS; all privileged work goes through window.falcon (preload). */

const api = window.falcon;
const $ = (sel) => document.querySelector(sel);
const esc = (v) => String(v == null ? '' : v).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const S = {
  route: 'dashboard',
  info: {},
  settings: { mode: 'latency', tier: 'regular' },
  profile: null,
  health: [],
  catalog: null,
  states: {},
  detecting: false,
  cat: 'input',
  search: '',
  filter: 'all',
  games: null,
  gamesLoading: false,
  history: [],
  tools: [],
  timer: null,
  reboot: 'none',
  busy: false,
  updater: null,
  cleaner: null,      // { groups, targets }
  cleanScan: null,    // id -> { bytes, files }
  cleanSel: null,     // Set of selected target ids
  cleaning: false,
  scanning: false,
  lastFreed: null
};

// ------------------------------------------------------------------ presets
const PRESETS = [
  {
    id: 'competitive', mode: 'latency', tier: 'regular', name: 'Competitive', tag: 'Lowest input delay · PC works as usual',
    icon: 'M13 2 3 14h7l-1 8 10-12h-7z',
    points: ['Latency-first scheduler, timers and power plan', 'C-states off, NIC interrupt moderation off', 'USB/HID never sleep, Game DVR off', 'Nothing you use stops working']
  },
  {
    id: 'boost', mode: 'fps', tier: 'regular', name: 'Everyday Boost', tag: 'More FPS · zero change to how Windows works',
    icon: 'M3 17h4v4H3zm7-6h4v10h-4zm7-8h4v18h-4z',
    points: ['Boost-friendly power plan (keeps idle states for higher clocks)', 'HAGS, flip model, Game Mode, MSI mode', 'Background telemetry and update seeding off', 'Safe for any PC — the normie pick']
  },
  {
    id: 'extreme_latency', mode: 'latency', tier: 'extreme', name: 'Extreme Latency', tag: 'Absolute minimum delay · strips Windows',
    icon: 'M12 12.9 9.87 15c-.56.56-.87 1.29-.87 2.07C9 18.68 10.35 20 12 20s3-1.32 3-2.94c0-.78-.31-1.52-.87-2.07zM16 6l-.44.55C14.38 8.02 12 7.19 12 5.3V2S4 6 4 13c0 2.92 1.56 5.47 3.89 6.86-.56-.79-.89-1.76-.89-2.8 0-1.32.52-2.56 1.47-3.5L12 10.1l3.53 3.47c.95.93 1.47 2.17 1.47 3.5 0 1.02-.31 1.96-.85 2.75 1.89-1.15 3.29-3.06 3.71-5.3.66-3.55-1.08-6.9-3.86-8.52',
    points: ['Everything in Competitive', 'VBS/HVCI + hypervisor off, CPU mitigations off', '20+ services, Bluetooth, Xbox, OneDrive, bloat apps gone', 'Updates paused, notifications off'], danger: true
  },
  {
    id: 'extreme_fps', mode: 'fps', tier: 'extreme', name: 'Extreme FPS', tag: 'Every last frame · dedicated gaming PC',
    icon: 'M12 12.9 9.87 15c-.56.56-.87 1.29-.87 2.07C9 18.68 10.35 20 12 20s3-1.32 3-2.94c0-.78-.31-1.52-.87-2.07zM16 6l-.44.55C14.38 8.02 12 7.19 12 5.3V2S4 6 4 13c0 2.92 1.56 5.47 3.89 6.86-.56-.79-.89-1.76-.89-2.8 0-1.32.52-2.56 1.47-3.5L12 10.1l3.53 3.47c.95.93 1.47 2.17 1.47 3.5 0 1.02-.31 1.96-.85 2.75 1.89-1.15 3.29-3.06 3.71-5.3.66-3.55-1.08-6.9-3.86-8.52',
    points: ['Everything in Everyday Boost', 'Security trade-offs for the largest CPU-side FPS gains', 'Background services and apps stripped to the bone', 'Things will break — every trade-off is listed first'], danger: true
  }
];
const activePreset = () => PRESETS.find((p) => p.mode === mode() && p.tier === tier()) || PRESETS[0];
const mode = () => (S.settings.mode === 'fps' ? 'fps' : 'latency');
const tier = () => (S.settings.tier === 'extreme' ? 'extreme' : 'regular');

const ACCENTS = [
  { id: 'falcon', name: 'Falcon', color: '#36c5f0' },
  { id: 'crimson', name: 'Crimson', color: '#ff4d5e' },
  { id: 'violet', name: 'Violet', color: '#9b7bff' },
  { id: 'emerald', name: 'Emerald', color: '#2fd39a' },
  { id: 'amber', name: 'Amber', color: '#f5a524' },
  { id: 'mono', name: 'Mono', color: '#d7dce4' }
];

const ROUTES = {
  dashboard: { title: 'Dashboard', sub: 'Pick a preset, check your system, apply in one click.' },
  tweaks: { title: 'Tweaks', sub: 'Every change Falcon can make — live status, the reason it exists, exact undo.' },
  speedboost: { title: 'Speed Boost', sub: 'Clear caches, logs and leftovers in one pass. Pick what to clean — Falcon shows exactly how much each one frees.' },
  games: { title: 'Games', sub: 'Per-game priority, Defender, QoS and GPU settings for the games on this PC.' },
  tools: { title: 'Tools', sub: 'Timer resolution service, the Falcon NVIDIA profile and trusted third-party tools.' },
  history: { title: 'History', sub: 'Everything Falcon changed, and one button to put it all back.' },
  settings: { title: 'Settings', sub: 'Appearance, safety options and updates.' }
};

const STATE_LABEL = { applied: 'Applied', not_applied: 'Not applied', partial: 'Partial', na: 'N/A', unknown: 'Unknown', custom: 'Custom value' };
const RISK_LABEL = { safe: 'Safe', moderate: 'Moderate', advanced: 'Advanced' };
const REBOOT_LABEL = { reboot: 'Restart', signout: 'Sign-out' };
const EVIDENCE = { measured: 'Measured in benchmarks', documented: 'Documented by Microsoft / vendor', mechanism: 'Known mechanism — benefit varies by system' };

// ------------------------------------------------------------------ helpers
const svg = (d, cls = '') => `<svg class="${cls}" viewBox="0 0 24 24" aria-hidden="true"><path d="${d}"/></svg>`;

function toast(msg, kind = '') {
  const el = document.createElement('div');
  el.className = `toast ${kind}`;
  el.textContent = msg;
  $('#toasts').appendChild(el);
  setTimeout(() => el.classList.add('out'), kind === 'error' ? 7000 : 3800);
  setTimeout(() => el.remove(), kind === 'error' ? 7400 : 4200);
}

function meter(n, cls, label) {
  const v = Math.max(-1, Math.min(3, Number(n) || 0));
  if (!v) return '';
  const on = v < 0 ? 1 : v;
  return `<span class="impact ${cls}${v < 0 ? ' neg' : ''}" title="${esc(label)} impact">${v < 0 ? `${label} −` : label}<span class="bars">${[0, 1, 2].map((i) => `<i class="${i < on ? 'on' : ''}"></i>`).join('')}</span></span>`;
}
const impactHtml = (imp) => (imp ? meter(imp.latency, 'lat', 'Latency') + meter(imp.fps, 'fps', 'FPS') : '');
const statePill = (st) => `<span class="pill st-${esc(st)}">${st === 'applied' ? '●' : ''} ${esc(STATE_LABEL[st] || st)}</span>`;

function stepText(s) {
  switch (s.type) {
    case 'reg': return s.delete ? `REG   delete ${s.path}\\${s.name}` : `REG   ${s.path}\\${s.name} = ${s.value} (${s.regType})`;
    case 'service': return `SVC   ${s.name} → ${s.start}`;
    case 'task': return `TASK  ${s.path} → ${s.state}`;
    case 'bcd': return s.delete ? `BCD   deletevalue ${s.name}` : `BCD   set ${s.name} ${s.value}`;
    case 'powercfg': return `PWR   ${s.sub} / ${s.setting} = ${s.value} (${s.scope})`;
    case 'netadapter': return `NIC   ${s.keyword} = ${s.value}`;
    case 'ps': { const l = String(s.script).trim().split('\n'); return `PS    ${l.slice(0, 3).join('\n      ')}${l.length > 3 ? '\n      …' : ''}`; }
    default: return JSON.stringify(s);
  }
}

const itemById = (id) => (S.catalog ? S.catalog.items.find((i) => i.id === id) : null);
const catLabel = (id) => ((S.catalog && S.catalog.categories.find((c) => c.id === id)) || { label: id }).label;
const presetOption = (it, m = mode()) => (it.options || []).find((o) => o.presets.includes(m) && !o.naReason);
function inPreset(it, m = mode(), t = tier()) {
  if (!it.applicable || it.kind === 'action') return false;
  if (it.kind === 'choice') return !!presetOption(it, m);
  return it.presets.includes(m) && (t === 'extreme' || it.tier !== 'extreme');
}
function isApplied(it, m = mode()) {
  const st = S.states[it.id];
  if (!st) return false;
  if (it.kind === 'choice') { const o = presetOption(it, m); return !!o && st.option === o.id; }
  return st.state === 'applied';
}
function presetProgress(m, t) {
  if (!S.catalog) return null;
  const rel = S.catalog.items.filter((it) => inPreset(it, m, t));
  return { total: rel.length, done: rel.filter((it) => isApplied(it, m)).length };
}

// ------------------------------------------------------------------ data
async function loadCatalog() {
  const r = await api.getCatalog();
  if (!r.ok) { toast(`Catalog failed to load: ${r.error}`, 'error'); return; }
  S.catalog = r;
  if (r.errors && r.errors.length) console.warn('catalog errors', r.errors);
}
async function detectAll() {
  S.detecting = true; render();
  const r = await api.detect();
  S.detecting = false;
  if (r.ok) S.states = r.states; else toast(`Status scan failed: ${r.error}`, 'error');
  render();
}
async function detectIds(ids) {
  if (!ids.length) return;
  const r = await api.detect(ids);
  if (r.ok) Object.assign(S.states, r.states);
}
async function loadProfile(force) {
  const r = await api.getProfile(!!force);
  if (r.ok) { S.profile = r.profile; S.health = r.health; }
  render();
}

// ------------------------------------------------------------------ modal
let modalCloseHook = null;
function openModal(title, body, foot, { wide = false, danger = false } = {}) {
  $('#modalTitle').textContent = title;
  $('#modalBody').innerHTML = body;
  $('#modalFoot').innerHTML = foot || '';
  ['onchange', 'oninput', 'onclick'].forEach((k) => { $('#modalBody')[k] = null; $('#modalFoot')[k] = null; });
  const m = $('#modal .modal');
  m.classList.toggle('wide', wide);
  m.classList.toggle('danger', danger);
  $('#modal').hidden = false;
}
function closeModal() {
  $('#modal').hidden = true;
  const h = modalCloseHook; modalCloseHook = null;
  if (h) h();
}
function confirmModal({ title, body, okLabel = 'Continue', danger = false, typed = null }) {
  return new Promise((resolve) => {
    openModal(title, `${body}${typed ? `<label class="typed">Type <b>${esc(typed)}</b> to confirm<input type="text" id="typedInput" autocomplete="off" spellcheck="false" /></label>` : ''}`,
      `<button class="btn" data-m="cancel">Cancel</button><button class="btn ${danger ? 'danger-solid' : 'primary'}" data-m="ok" ${typed ? 'disabled' : ''}>${esc(okLabel)}</button>`, { danger });
    modalCloseHook = () => resolve(false);
    const done = (v) => { modalCloseHook = null; closeModal(); resolve(v); };
    if (typed) $('#modalBody').oninput = (e) => { if (e.target.id === 'typedInput') $('#modalFoot [data-m="ok"]').disabled = e.target.value.trim().toUpperCase() !== typed; };
    $('#modalFoot').onclick = (e) => { const b = e.target.closest('[data-m]'); if (b && !b.disabled) done(b.dataset.m === 'ok'); };
  });
}

// ------------------------------------------------------------------ execution
async function execute(requests, label) {
  if (S.busy) { toast('Another operation is still running.'); return null; }
  const risky = requests.map((r) => [r, itemById(r.id)]).filter(([r, it]) => it && r.action !== 'revert' && (it.risk === 'advanced' || it.tier === 'extreme'));
  if (risky.length) {
    const ok = await confirmModal({
      title: risky.length === 1 ? `Apply “${risky[0][1].name}”?` : `Apply ${risky.length} extreme changes?`,
      body: `<div class="warnlist">${risky.map(([, it]) => `<div><b>${esc(it.name)}</b><span>${esc(it.tradeoff || it.summary)}</span></div>`).join('')}</div><p class="muted" style="margin-top:12px">You can undo this later from History.</p>`,
      okLabel: 'Apply anyway', danger: true
    });
    if (!ok) return null;
  }
  S.busy = true; render();
  toast(`${label || 'Applying'}…`);
  const res = await api.execute(requests, { label });
  S.busy = false;
  if (!res || res.cancelled) { toast(res && res.error ? res.error : 'Cancelled.', 'error'); render(); return res; }
  const failed = (res.results || []).filter((r) => !r.ok);
  if (failed.length) toast(`${failed.length} change(s) failed: ${failed.map((f) => `${(itemById(f.id) || {}).name || f.id} — ${(f.messages || []).slice(-1)[0] || 'error'}`).join('; ')}`, 'error');
  else toast(res.dryRun ? 'Dry run complete — nothing was changed.' : 'Done.', 'ok');
  if (res.reboot && res.reboot !== 'none' && !res.dryRun) S.reboot = res.reboot === 'reboot' || S.reboot === 'reboot' ? 'reboot' : 'signout';
  await detectIds([...new Set(requests.map((r) => r.id))]);
  render();
  return res;
}

// ------------------------------------------------------------------ one-click optimize
async function openOptimize(customIds) {
  const m = mode();
  const t = customIds ? 'extreme' : tier();
  const preset = customIds ? { name: 'Custom preset', danger: false } : activePreset();
  let restorePoint = S.settings.createRestorePoint !== false;
  let plan = [];
  const selected = new Set();

  const footHtml = () => `
    <label class="check"><input type="checkbox" id="optRp" ${restorePoint ? 'checked' : ''}/> Restore point first</label>
    <button class="btn ghost sm" data-m="save">Save selection as Custom preset</button>
    <span class="spacer"></span>
    <button class="btn" data-m="cancel">Cancel</button>
    <button class="btn ${preset.danger ? 'danger-solid' : 'primary'}" data-m="go" ${selected.size ? '' : 'disabled'}>Apply ${selected.size} change${selected.size === 1 ? '' : 's'}</button>`;

  const renderPlan = () => {
    if (!plan.length) {
      $('#modalBody').innerHTML = `<div class="empty big">${svg('M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z', 'empty-ic')}<div>Everything in <b>${esc(preset.name)}</b> is already applied on this PC.</div></div>`;
      $('#modalFoot').innerHTML = '<button class="btn primary" data-m="cancel">Close</button>';
      return;
    }
    const groups = {};
    for (const p of plan) (groups[p.category] = groups[p.category] || []).push(p);
    const extreme = plan.filter((p) => p.tier === 'extreme');
    $('#modalBody').innerHTML = `
      ${preset.danger ? `<div class="hazard"><div class="hazard-title">${svg('M1 21h22L12 2zm12-3h-2v-2h2zm0-4h-2v-4h2z')}Extreme preset — this will make Windows harder to use</div>
        <p>${extreme.length} changes below remove Windows features on purpose. Each one lists what breaks. Untick anything you rely on. Everything can be undone from History.</p></div>` : ''}
      <div class="plan-tools"><button class="btn ghost sm" data-m="all">Select all</button><button class="btn ghost sm" data-m="none">Select none</button><span class="muted">${plan.length} pending · already-applied items are skipped</span></div>
      ${Object.entries(groups).map(([cat, rows]) => `
        <div class="plan-group"><h4>${esc(catLabel(cat))}</h4>
        ${rows.map((p) => `<label class="plan-row ${p.tier === 'extreme' ? 'x' : ''}">
            <input type="checkbox" data-plan="${esc(p.id)}" ${selected.has(p.id) ? 'checked' : ''} />
            <span class="pr-main"><span class="pr-name">${esc(p.name)}</span>${p.optionLabel ? `<span class="pr-sub">${esc(p.optionLabel)}</span>` : ''}${p.tier === 'extreme' && p.tradeoff ? `<span class="pr-trade">${esc(p.tradeoff)}</span>` : ''}</span>
            <span class="pr-meta">${p.reboot === 'reboot' ? '<span class="pill">Restart</span>' : ''}${impactHtml(p.impact)}</span>
          </label>`).join('')}
        </div>`).join('')}`;
    $('#modalFoot').innerHTML = footHtml();
  };

  openModal(customIds ? 'Custom preset' : `${preset.name}`, '<div class="empty"><span class="spinner"></span> Checking what is already applied…</div>', '', { wide: true, danger: !!preset.danger });
  const r = await api.planOptimize(m, t);
  if (!r.ok) { $('#modalBody').innerHTML = `<div class="empty">Could not build the plan: ${esc(r.error)}</div>`; return; }
  S.states = { ...S.states, ...r.states };
  plan = customIds ? r.plan.filter((p) => customIds.includes(p.id)) : r.plan;
  for (const p of plan) selected.add(p.id);
  renderPlan();

  const sync = () => {
    const go = $('#modalFoot [data-m="go"]');
    if (go) { go.disabled = !selected.size; go.textContent = `Apply ${selected.size} change${selected.size === 1 ? '' : 's'}`; }
  };
  $('#modalBody').onchange = (e) => {
    const cb = e.target.closest('[data-plan]');
    if (!cb) return;
    if (cb.checked) selected.add(cb.dataset.plan); else selected.delete(cb.dataset.plan);
    sync();
  };
  $('#modalBody').onclick = (e) => {
    const b = e.target.closest('[data-m]');
    if (!b) return;
    if (b.dataset.m === 'all') plan.forEach((p) => selected.add(p.id));
    if (b.dataset.m === 'none') selected.clear();
    $('#modalBody').querySelectorAll('[data-plan]').forEach((cb) => { cb.checked = selected.has(cb.dataset.plan); });
    sync();
  };
  $('#modalFoot').onchange = async (e) => {
    if (e.target.id === 'optRp') { restorePoint = e.target.checked; await saveSetting({ createRestorePoint: restorePoint }, false); }
  };
  $('#modalFoot').onclick = async (e) => {
    const b = e.target.closest('[data-m]');
    if (!b || b.disabled) return;
    if (b.dataset.m === 'cancel') return closeModal();
    if (b.dataset.m === 'save') {
      await saveSetting({ customPreset: { mode: m, ids: [...selected], savedAt: new Date().toISOString() } }, false);
      toast(`Saved ${selected.size} changes as your Custom preset.`, 'ok');
      return;
    }
    if (b.dataset.m !== 'go') return;
    const chosen = plan.filter((p) => selected.has(p.id));
    const xs = chosen.filter((p) => p.tier === 'extreme' || p.risk === 'advanced');
    if (xs.length) {
      const ok = await confirmModal({
        title: 'Final confirmation',
        body: `<p>You are about to apply <b>${xs.length} extreme change${xs.length === 1 ? '' : 's'}</b>:</p><div class="warnlist">${xs.map((p) => `<div><b>${esc(p.name)}</b><span>${esc(p.tradeoff || '')}</span></div>`).join('')}</div>`,
        okLabel: 'Apply extreme changes', danger: true, typed: 'EXTREME'
      });
      if (!ok) return;
      openModal(preset.name, '', '', { wide: true, danger: !!preset.danger });
    }
    $('#modalBody').innerHTML = `<div class="applying"><span class="spinner lg"></span><div><b>Applying ${chosen.length} changes${restorePoint ? ' (restore point first)' : ''}…</b><div class="muted">Windows may ask for administrator approval. Network adapters can reconnect briefly.</div></div></div><div class="progress"><div></div></div>`;
    $('#modalFoot').innerHTML = '';
    S.busy = true; render();
    const res = await api.runOptimize(m, chosen.map((p) => ({ id: p.id, option: p.option })), { restorePoint, tier: t });
    S.busy = false;
    if (!res || res.cancelled) { closeModal(); toast((res && res.error) || 'Cancelled.', 'error'); render(); return; }
    const ok = res.results.filter((x) => x.ok);
    const bad = res.results.filter((x) => !x.ok);
    if (res.reboot !== 'none' && !res.dryRun) S.reboot = res.reboot;
    $('#modalBody').innerHTML = `
      <div class="result-head ${bad.length ? 'has-fail' : ''}">${svg(bad.length ? 'M1 21h22L12 2zm12-3h-2v-2h2zm0-4h-2v-4h2z' : 'M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z')}
        <div><b>${ok.length} applied${bad.length ? `, ${bad.length} failed` : ''}</b><div class="muted">${res.dryRun ? 'Dry run — nothing was actually changed.' : res.reboot === 'reboot' ? 'Restart Windows to finish.' : 'Changes are active.'}</div></div></div>
      ${bad.length ? `<div class="plan-group"><h4>Failed</h4>${bad.map((x) => `<div class="plan-row"><span class="fail">✕</span><span class="pr-main"><span class="pr-name">${esc((itemById(x.id) || {}).name || x.id)}</span><span class="pr-sub">${esc((x.messages || []).join(' · '))}</span></span><span></span></div>`).join('')}</div>` : ''}`;
    $('#modalFoot').innerHTML = `${res.reboot === 'reboot' && !res.dryRun ? '<button class="btn" data-m="restart">Restart now</button>' : ''}<button class="btn primary" data-m="close">Done</button>`;
    $('#modalFoot').onclick = async (ev) => {
      const bb = ev.target.closest('[data-m]');
      if (!bb) return;
      if (bb.dataset.m === 'restart') await api.restartPc();
      closeModal();
    };
    await detectAll();
  };
}

// ------------------------------------------------------------------ pages
function presetCard(p) {
  const active = p.mode === mode() && p.tier === tier();
  const prog = presetProgress(p.mode, p.tier);
  const pct = prog && prog.total ? Math.round((prog.done / prog.total) * 100) : 0;
  return `<button class="preset ${active ? 'active' : ''} ${p.danger ? 'danger' : ''}" data-act="preset" data-preset="${p.id}" aria-pressed="${active}">
    <div class="preset-top">
      <span class="preset-ic">${svg(p.icon)}</span>
      <span class="preset-chips"><span class="chip">${p.mode === 'fps' ? 'FPS' : 'Latency'}</span><span class="chip ${p.tier === 'extreme' ? 'x' : ''}">${p.tier === 'extreme' ? 'Extreme' : 'Regular'}</span></span>
    </div>
    <div class="preset-name">${esc(p.name)}</div>
    <div class="preset-tag">${esc(p.tag)}</div>
    <ul>${p.points.map((x) => `<li>${esc(x)}</li>`).join('')}</ul>
    <div class="preset-foot">${prog ? `<span>${prog.done}/${prog.total} applied</span><div class="meter"><div style="width:${pct}%"></div></div>` : '<span class="muted">…</span>'}</div>
  </button>`;
}

function pageDashboard() {
  const p = S.profile;
  const ap = activePreset();
  const prog = presetProgress(mode(), tier());
  const pending = prog ? prog.total - prog.done : null;
  const cp = S.settings.customPreset;
  const bad = S.health.filter((h) => h.status === 'bad' || h.status === 'warn');
  const info = S.health.filter((h) => h.status === 'info');
  const good = S.health.filter((h) => h.status === 'good');
  const hItem = (h) => `<div class="health-item ${h.status}"><span class="sev"></span><div><div class="t">${esc(h.title)}</div>${h.detail ? `<div class="d">${esc(h.detail)}</div>` : ''}${h.fix ? `<div class="f">${esc(h.fix)}</div>` : ''}</div></div>`;

  return `
  <section class="presets">${PRESETS.map(presetCard).join('')}</section>
  <section class="cta ${ap.danger ? 'danger' : ''}">
    <div>
      <div class="cta-kicker">Selected preset</div>
      <div class="cta-title">${esc(ap.name)} <span class="muted">· ${esc(ap.tag)}</span></div>
      <div class="cta-sub">${S.detecting ? '<span class="spinner"></span> Reading current system state…' : pending == null ? '' : pending ? `${pending} change${pending === 1 ? '' : 's'} pending on this PC` : 'Fully applied on this PC'}</div>
    </div>
    <div class="row">
      ${cp && cp.ids && cp.ids.length ? `<button class="btn" data-act="custom-preset" ${S.busy || !S.catalog ? 'disabled' : ''}>Custom preset (${cp.ids.length})</button>` : ''}
      <button class="btn ${ap.danger ? 'danger-solid' : 'primary'} lg" data-act="optimize" ${S.busy || !S.catalog ? 'disabled' : ''}>${svg('M13 2 3 14h7l-1 8 10-12h-7z')} Apply ${esc(ap.name)}</button>
    </div>
  </section>
  <section class="dash-grid">
    <div class="panel">
      <div class="panel-head"><h3>Health checks</h3><button class="btn sm ghost" data-act="rescan">Re-scan</button></div>
      <p class="muted small">Problems a tweak cannot fix — BIOS settings, wrong refresh rate, drivers. These usually matter more than any tweak.</p>
      ${p ? `<div class="health">${bad.map(hItem).join('')}${info.map(hItem).join('')}${!bad.length && !info.length ? '<div class="muted">No problems found.</div>' : ''}</div>
        ${good.length ? `<details class="health-good"><summary>${good.length} checks passed</summary><div class="health">${good.map(hItem).join('')}</div></details>` : ''}` : '<div class="skeleton" style="height:180px"></div>'}
    </div>
    <div class="panel sys">
      <div class="panel-head"><h3>This PC</h3><span class="chip">${p ? (p.formFactor === 'laptop' ? 'Laptop' : 'Desktop') : '…'}</span></div>
      ${p ? `
        <div class="spec">${svg('M6 4h12v16H6zm2 2v12h8V6zM2 9h2v2H2zm0 4h2v2H2zm18-4h2v2h-2zm0 4h2v2h-2z')}<div><span>Processor</span><b>${esc(p.cpu.name || 'Unknown')}</b><em>${[p.cpu.cores && `${p.cpu.cores} cores / ${p.cpu.threads} threads`, p.cpu.x3dDual && 'dual-CCD X3D', !p.cpu.x3dDual && p.cpu.x3d && 'X3D', p.cpu.hybrid && 'hybrid P/E'].filter(Boolean).join(' · ')}</em></div></div>
        <div class="spec">${svg('M2 7h20v10H2zm2 2v6h16V9zM5 18h2v2H5zm4 0h2v2H9z')}<div><span>Graphics</span><b>${esc(p.gpu.name || 'Unknown')}</b><em>${esc((p.gpus || []).filter((g) => g.name !== p.gpu.name).map((g) => `+ ${g.name}`).join(' ') || (p.gpu.vramGb ? `${p.gpu.vramGb} GB VRAM` : ''))}</em></div></div>
        <div class="spec">${svg('M3 7h18v10H3zm2 2v6h2V9zm4 0v6h2V9zm4 0v6h2V9zm4 0v6h2V9z')}<div><span>Memory</span><b>${esc(p.ram.totalGb || '?')} GB${p.ram.configuredMTs ? ` @ ${p.ram.configuredMTs} MT/s` : ''}</b><em>${p.ram.modules ? `${p.ram.modules} module${p.ram.modules > 1 ? 's' : ''}` : ''}</em></div></div>
        <div class="spec">${svg('M3 4h18v12H3zm2 2v8h14V6zm3 12h8v2H8z')}<div><span>Display</span><b>${esc((p.displays || []).map((d) => `${d.resolution} @ ${d.refreshHz} Hz`).join(', ') || '—')}</b><em>${esc((p.displays || []).length > 1 ? `${p.displays.length} displays` : '')}</em></div></div>
        <div class="spec">${svg('M3 3h8v8H3zm10 0h8v8h-8zM3 13h8v8H3zm10 0h8v8h-8z')}<div><span>Windows</span><b>${esc((p.os.caption || '').replace('Microsoft ', ''))} ${esc(p.os.displayVersion || '')}</b><em>Build ${esc(p.os.build)}.${esc(p.os.ubr || 0)} · plan: ${esc(p.state.powerPlan || '—')}</em></div></div>` : '<div class="skeleton" style="height:220px"></div>'}
    </div>
  </section>`;
}

function tweakCard(it) {
  const st = S.states[it.id] || {};
  const m = mode();
  const state = it.applicable ? (st.state || (S.detecting ? '' : 'unknown')) : 'na';
  const meta = [];
  if (it.kind !== 'action' && state) meta.push(statePill(state));
  if (it.tier === 'extreme') meta.push('<span class="pill x">Extreme</span>');
  if (it.kind === 'toggle' && inPreset(it)) meta.push(`<span class="pill preset">In ${esc(activePreset().name)}</span>`);
  if (it.risk !== 'safe') meta.push(`<span class="pill risk-${it.risk}">${RISK_LABEL[it.risk]}</span>`);
  if (REBOOT_LABEL[it.reboot]) meta.push(`<span class="pill">${REBOOT_LABEL[it.reboot]}</span>`);
  meta.push(impactHtml(it.impact));

  const dis = S.busy || !it.applicable ? 'disabled' : '';
  let actions = '';
  if (it.kind === 'toggle') {
    const applied = state === 'applied';
    actions = applied
      ? `<button class="btn sm" data-act="revert" data-id="${esc(it.id)}" ${dis}>Revert</button>`
      : `${state === 'partial' ? `<button class="btn sm ghost" data-act="revert" data-id="${esc(it.id)}" ${dis}>Revert</button>` : ''}<button class="btn sm ${it.tier === 'extreme' ? 'danger-solid' : 'primary'}" data-act="apply" data-id="${esc(it.id)}" ${dis}>Apply</button>`;
  } else if (it.kind === 'action') {
    actions = `<button class="btn sm" data-act="run" data-id="${esc(it.id)}" ${dis}>${svg('M8 5v14l11-7z')} Run</button>`;
  }
  let choice = '';
  if (it.kind === 'choice') {
    const rec = presetOption(it, m);
    choice = `<div class="seg">${it.options.map((o) => `<button data-act="choose" data-id="${esc(it.id)}" data-opt="${esc(o.id)}" class="${st.option === o.id ? 'active' : ''} ${rec && rec.id === o.id ? 'rec' : ''}" ${S.busy || o.naReason || !it.applicable ? 'disabled' : ''} title="${esc(o.naReason || (rec && rec.id === o.id ? `Used by ${activePreset().name}` : ''))}">${st.option === o.id ? '● ' : ''}${esc(o.label)}</button>`).join('')}</div>`;
  }
  const steps = it.kind === 'choice' ? it.options.flatMap((o) => [{ type: 'ps', script: `# ${o.label}` }, ...o.apply]) : (it.kind === 'action' ? it.run : it.apply);
  return `<article class="card ${it.applicable ? '' : 'is-na'} ${it.tier === 'extreme' ? 'is-x' : ''}" id="card-${esc(it.id)}">
    <div class="card-top">
      <div class="card-text"><div class="card-title">${esc(it.name)}</div><div class="card-sum">${esc(it.summary)}</div></div>
      <div class="card-actions">${actions}</div>
    </div>
    ${choice}
    ${it.tradeoff && it.tier === 'extreme' ? `<div class="tradeoff">${svg('M1 21h22L12 2zm12-3h-2v-2h2zm0-4h-2v-4h2z')}${esc(it.tradeoff)}</div>` : ''}
    <div class="card-meta">${meta.join('')}</div>
    ${!it.applicable && it.naReason ? `<div class="na-reason">${esc(it.naReason)}</div>` : ''}
    <details><summary>How it works</summary>
      ${it.details ? `<p class="more">${esc(it.details)}</p>` : ''}
      ${it.tradeoff && it.tier !== 'extreme' ? `<p class="more warn">Trade-off: ${esc(it.tradeoff)}</p>` : ''}
      ${it.evidence ? `<p class="more muted">${esc(EVIDENCE[it.evidence] || it.evidence)}</p>` : ''}
      <pre class="steps">${(steps || []).map((s) => esc(stepText(s))).join('\n')}</pre>
    </details>
  </article>`;
}

function pageTweaks() {
  if (!S.catalog) return '<div class="skeleton" style="height:400px"></div>';
  const q = S.search.trim().toLowerCase();
  const cats = S.catalog.categories;
  const itemsIn = (c) => S.catalog.items.filter((i) => i.category === c);
  let list = q ? S.catalog.items.filter((i) => `${i.name} ${i.summary} ${i.details || ''}`.toLowerCase().includes(q)) : itemsIn(S.cat);
  const f = S.filter;
  if (f === 'applied') list = list.filter((i) => (S.states[i.id] || {}).state === 'applied');
  if (f === 'pending') list = list.filter((i) => i.applicable && i.kind !== 'action' && (S.states[i.id] || {}).state !== 'applied');
  if (f === 'preset') list = list.filter((i) => inPreset(i));
  list = [...list].sort((a, b) => (b.applicable - a.applicable));
  const cur = cats.find((c) => c.id === S.cat) || cats[0];
  return `<div class="tweaks-layout">
    <nav class="cat-list">${cats.map((c) => {
      const its = itemsIn(c.id).filter((i) => i.applicable && i.kind !== 'action');
      const done = its.filter((i) => (S.states[i.id] || {}).state === 'applied').length;
      return `<button class="cat-btn ${!q && c.id === S.cat ? 'active' : ''} ${c.id === 'extreme' || c.id === 'security' ? 'x' : ''}" data-act="cat" data-cat="${c.id}"><span>${esc(c.label)}</span><span class="count">${its.length ? `${done}/${its.length}` : itemsIn(c.id).length}</span></button>`;
    }).join('')}</nav>
    <div class="tweaks-main">
      <div class="cat-head">
        <div>${q ? `<h2>Results for “${esc(S.search)}”</h2>` : `<h2>${esc(cur.label)}</h2><p>${esc(cur.blurb)}</p>`}</div>
        <div class="seg small">${[['all', 'All'], ['preset', 'In preset'], ['pending', 'Pending'], ['applied', 'Applied']].map(([k, l]) => `<button data-act="filter" data-filter="${k}" class="${f === k ? 'active' : ''}">${l}</button>`).join('')}</div>
      </div>
      ${S.detecting ? '<p class="muted small" style="margin-bottom:10px"><span class="spinner"></span> Reading current state…</p>' : ''}
      <div class="cards">${list.length ? list.map(tweakCard).join('') : '<div class="empty">Nothing here for this filter.</div>'}</div>
    </div>
  </div>`;
}

const fmtBytes = (b) => {
  const n = Number(b) || 0;
  if (n >= 1073741824) return `${(n / 1073741824).toFixed(n >= 10737418240 ? 0 : 1)} GB`;
  if (n >= 1048576) return `${Math.round(n / 1048576)} MB`;
  if (n >= 1024) return `${Math.round(n / 1024)} KB`;
  return n ? `${n} B` : '0 MB';
};

function pageSpeedBoost() {
  const c = S.cleaner;
  if (!c) return '<div class="skeleton" style="height:400px"></div>';
  const scan = S.cleanScan || {};
  const sel = S.cleanSel;
  const selBytes = c.targets.filter((t) => sel.has(t.id)).reduce((a, t) => a + ((scan[t.id] || {}).bytes || 0), 0);
  const allBytes = c.targets.reduce((a, t) => a + ((scan[t.id] || {}).bytes || 0), 0);
  const busy = S.cleaning || S.scanning || S.busy;
  return `
  <section class="sb-hero">
    <div class="sb-gauge">
      <div class="sb-num">${S.scanning ? '<span class="spinner lg"></span>' : S.cleanScan ? fmtBytes(selBytes) : '—'}</div>
      <div class="muted small">${S.cleanScan ? `selected of ${fmtBytes(allBytes)} found` : 'Scan to see what can be cleaned'}</div>
    </div>
    <div class="sb-copy">
      <h2>${sel.size} of ${c.targets.length} cleaners selected</h2>
      <p class="muted">Only caches, logs and leftovers that apps and Windows rebuild on their own. Your files, passwords, game installs and saves are never touched. Files that are in use are skipped.</p>
      ${S.lastFreed != null ? `<p class="sb-freed">${svg('M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z')} Freed ${fmtBytes(S.lastFreed)} last run</p>` : ''}
      <div class="row" style="margin-top:14px">
        <button class="btn" data-act="clean-scan" ${busy ? 'disabled' : ''}>${S.cleanScan ? 'Re-scan' : 'Scan'}</button>
        <div class="seg small"><button data-act="clean-pick" data-pick="rec">Recommended</button><button data-act="clean-pick" data-pick="all">All</button><button data-act="clean-pick" data-pick="none">None</button></div>
        <span class="spacer"></span>
        <button class="btn primary lg" data-act="clean-run" ${busy || !sel.size ? 'disabled' : ''}>${S.cleaning ? '<span class="spinner"></span> Cleaning…' : `${svg('M16 11h-1V3a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v8H8a5 5 0 0 0-5 5v7h18v-7a5 5 0 0 0-5-5')} Clean selected${S.cleanScan ? ` · ${fmtBytes(selBytes)}` : ''}`}</button>
      </div>
    </div>
  </section>
  <div class="sb-groups">${c.groups.map((g) => {
    const ts = c.targets.filter((t) => t.group === g);
    if (!ts.length) return '';
    return `<div class="panel sb-group"><div class="panel-head"><h3>${esc(g)}</h3><span class="muted small">${fmtBytes(ts.reduce((a, t) => a + ((scan[t.id] || {}).bytes || 0), 0))}</span></div>
      ${ts.map((t) => {
        const r = scan[t.id];
        return `<label class="sb-row ${sel.has(t.id) ? 'on' : ''}">
          <input type="checkbox" data-clean="${esc(t.id)}" ${sel.has(t.id) ? 'checked' : ''} ${busy ? 'disabled' : ''} />
          <span class="sb-main"><span class="sb-name">${esc(t.name)}</span>${t.note ? `<span class="sb-note">${esc(t.note)}</span>` : ''}</span>
          <span class="sb-size ${r && r.bytes > 104857600 ? 'big' : ''}">${S.scanning ? '<span class="spinner"></span>' : r ? (r.bytes ? fmtBytes(r.bytes) : '<span class="muted">clean</span>') : ''}</span>
        </label>`;
      }).join('')}</div>`;
  }).join('')}</div>`;
}

async function loadCleaner() {
  if (!S.cleaner) {
    const r = await api.listCleaner();
    if (!r.ok) { toast('Could not load the cleaner list.', 'error'); return; }
    S.cleaner = r;
    let saved = null;
    try { saved = JSON.parse(localStorage.getItem('falcon.cleanSel') || 'null'); } catch (_) {}
    S.cleanSel = new Set(Array.isArray(saved) ? saved : r.targets.filter((t) => t.default).map((t) => t.id));
    render();
  }
  if (!S.cleanScan) await scanCleaner();
}
function saveCleanSel() { try { localStorage.setItem('falcon.cleanSel', JSON.stringify([...S.cleanSel])); } catch (_) {} }

async function scanCleaner() {
  S.scanning = true; render();
  const r = await api.runCleaner('scan');
  S.scanning = false;
  if (r.ok) S.cleanScan = Object.fromEntries((r.targets || []).map((t) => [t.id, t]));
  else toast(`Scan failed: ${r.error || 'unknown error'}`, 'error');
  render();
}

async function runCleaner() {
  const ids = [...S.cleanSel];
  S.cleaning = true; render();
  const r = await api.runCleaner('clean', ids);
  S.cleaning = false;
  if (r.cancelled) { toast(r.error || 'Cancelled.', 'error'); render(); return; }
  if (r.dryRun) { toast('Dry run is on — nothing was deleted.'); render(); return; }
  if (!r.ok && !r.targets) { toast(`Cleanup failed: ${r.error || 'unknown error'}`, 'error'); render(); return; }
  S.lastFreed = r.freedBytes || 0;
  const skipped = (r.targets || []).reduce((a, t) => a + (t.skipped || 0), 0);
  toast(`Freed ${fmtBytes(S.lastFreed)}${skipped ? ` · ${skipped} in-use file(s) skipped` : ''}.`, 'ok');
  await scanCleaner();
  if (S.profile) loadProfile(true); // free-space health check
}

function pageGames() {
  if (S.gamesLoading || !S.games) return `<div class="games-grid">${[0, 1, 2].map(() => '<div class="skeleton" style="height:340px"></div>').join('')}</div><p class="muted center">Scanning Steam, Epic, Riot and Battle.net libraries…</p>`;
  if (!S.games.length) return `<div class="empty big">${svg('M21 6H3a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h18a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2m-10 7H8v3H6v-3H3v-2h3V8h2v3h3z', 'empty-ic')}<div>No supported games found.</div><button class="btn primary" data-act="add-game">Add a game manually</button></div>`;
  return `<div class="games-grid">${S.games.map((g) => {
    const presetItems = g.items.filter((i) => i.preset);
    const done = presetItems.filter((i) => (S.states[i.id] || {}).state === 'applied').length;
    const all = done === presetItems.length;
    return `<article class="game">
      <div class="game-art ${g.art ? '' : 'no-art'}" ${g.art ? '' : `data-hue="${[...g.id].reduce((a, c) => a + c.charCodeAt(0), 0) % 360}"`}>
        ${g.art ? `<img src="${g.art}" alt="" />` : ''}
        <div class="game-art-shade"></div>
        <div class="game-id">
          <div class="game-logo">${g.icon ? `<img src="${g.icon}" alt="" />` : `<span>${esc(g.name.slice(0, 1))}</span>`}</div>
          <div><div class="game-name">${esc(g.name)}</div><div class="game-store">${esc(g.store)} · ${esc(g.exe)}</div></div>
        </div>
        <span class="game-badge ${all ? 'ok' : ''}">${done}/${presetItems.length}</span>
      </div>
      <div class="game-body">
        <div class="game-rows">${g.items.map((it) => {
          const st = (S.states[it.id] || {}).state || '';
          const applied = st === 'applied';
          return `<div class="game-row" title="${esc(it.details)}">
            <div><div class="n">${esc(it.name)}</div><div class="s">${esc(it.summary)}</div></div>
            ${st ? statePill(st) : '<span class="spinner"></span>'}
            <button class="btn sm ${applied ? '' : 'primary'}" data-act="${applied ? 'revert' : 'apply'}" data-id="${esc(it.id)}" ${S.busy ? 'disabled' : ''}>${applied ? 'Revert' : 'Apply'}</button>
          </div>`;
        }).join('')}</div>
        ${g.tips && g.tips.length ? `<details class="tips-box"><summary>Recommended in-game settings</summary><ul class="tips">${g.tips.map((t) => `<li>${esc(t)}</li>`).join('')}</ul></details>` : ''}
        <div class="row">
          ${g.store === 'Custom' ? `<button class="btn sm ghost" data-act="remove-game" data-game="${esc(g.id)}">Remove</button>` : ''}
          <span class="spacer"></span>
          <button class="btn primary" data-act="game-opt" data-game="${esc(g.id)}" ${S.busy || all ? 'disabled' : ''}>${all ? 'Optimized' : 'Optimize game'}</button>
        </div>
      </div>
    </article>`;
  }).join('')}</div>`;
}

function pageTools() {
  const t = S.timer;
  const timerItem = itemById('sched.timer_service');
  const globalItem = itemById('sched.global_timer_requests');
  const st = timerItem ? (S.states[timerItem.id] || {}).state : null;
  const res = Number(S.settings.timerResolution) || 5000;
  const groups = {};
  for (const tool of S.tools) (groups[tool.group] = groups[tool.group] || []).push(tool);
  return `
  <div class="panel timer">
    <div class="timer-read">
      <div class="timer-big">${t ? t.currentMs : '—'}<small>ms</small></div>
      <div class="muted small">current system timer resolution${t ? ` · finest ${t.maxMs} ms` : ''}</div>
    </div>
    <div class="timer-body">
      <h3>Timer resolution service</h3>
      <p class="muted small">Holds the Windows timer at high resolution from boot — a 2 KB native helper compiled locally, running as SYSTEM with Windows 11 timer throttling opted out.</p>
      <div class="row" style="margin:12px 0">
        <span class="pill ${t && t.installed ? 'st-applied' : ''}">${t ? (t.installed ? `Service installed${t.running ? ' · running' : ''}${t.resolution ? ` · ${t.resolution / 10000} ms` : ''}` : 'Service not installed') : '…'}</span>
        ${globalItem ? (globalItem.applicable ? `<span class="pill ${(S.states[globalItem.id] || {}).state === 'applied' ? 'st-applied' : ''}">System-wide: ${esc(STATE_LABEL[(S.states[globalItem.id] || {}).state] || 'Unknown')}</span>` : `<span class="pill">${esc(globalItem.naReason)}</span>`) : ''}
      </div>
      <div class="row">
        <div class="seg">${[[5000, '0.500'], [5070, '0.507'], [5200, '0.520'], [10000, '1.000']].map(([v, l]) => `<button data-act="timer-res" data-res="${v}" class="${v === res ? 'active' : ''}" ${S.busy ? 'disabled' : ''}>${l} ms</button>`).join('')}</div>
        ${timerItem && timerItem.applicable ? `
          <button class="btn primary" data-act="apply" data-id="sched.timer_service" ${S.busy ? 'disabled' : ''}>${st === 'applied' ? 'Reinstall' : 'Install'}</button>
          ${st === 'applied' ? `<button class="btn" data-act="revert" data-id="sched.timer_service" ${S.busy ? 'disabled' : ''}>Remove</button>` : ''}
          ${globalItem && globalItem.applicable && (S.states[globalItem.id] || {}).state !== 'applied' ? `<button class="btn" data-act="apply" data-id="sched.global_timer_requests" ${S.busy ? 'disabled' : ''}>Enable system-wide</button>` : ''}`
          : `<span class="muted small">${esc(timerItem ? timerItem.naReason : '')}</span>`}
        <button class="btn ghost sm" data-act="timer-refresh">Refresh</button>
      </div>
      <p class="muted small" style="margin-top:10px">0.5 ms is the usual choice. On some systems 0.507 ms gives more precise Sleep(1) timing — measure and keep what is most consistent.</p>
    </div>
  </div>
  <div class="tools-grid">${Object.entries(groups).map(([gname, tools]) => `<div class="panel"><h3>${esc(gname)}</h3><div class="tool-list">${tools.map((tool) => `
    <div class="tool"><div><div class="n">${esc(tool.name)}</div><div class="s">${esc(tool.summary)}</div></div>
    <div class="row">${tool.importNip ? '<button class="btn sm" data-act="import-nip">Import Falcon profile</button>' : ''}
    ${tool.url ? `<button class="btn sm ghost" data-act="url" data-url="${esc(tool.url)}">Website ↗</button>` : ''}
    ${tool.folder ? `<button class="btn sm" data-act="folder" data-folder="${esc(tool.folder)}">Open folder</button>` : ''}</div></div>`).join('')}</div></div>`).join('')}</div>`;
}

function pageHistory() {
  const name = (id) => {
    if (String(id).startsWith('clean.') && S.cleaner) { const t = S.cleaner.targets.find((x) => `clean.${x.id}` === id); if (t) return t.name; }
    return (itemById(id) || {}).name || id;
  };
  const appliedCount = Object.keys((S.catalog && S.catalog.applied) || {}).length;
  return `
  <div class="panel undo">
    <div><h3>Undo everything</h3><p class="muted small">Restores the exact original value of every setting Falcon changed (from its journal), falling back to Windows defaults where no original was recorded. ${appliedCount} setting(s) currently tracked.</p></div>
    <div class="row"><button class="btn ghost" data-act="open-logs">Open logs</button><button class="btn danger" data-act="undo-all" ${S.busy || !appliedCount ? 'disabled' : ''}>Undo all Falcon changes</button></div>
  </div>
  ${S.history.length ? `<div class="hist">${S.history.map((h) => `
    <details class="hist-item">
      <summary><span class="hist-dot ${h.ok ? 'ok' : 'fail'}"></span><span class="hist-label">${esc(h.label)}${h.dryRun ? ' <span class="pill">dry run</span>' : ''}</span><span class="muted small">${(h.results || []).length} item(s)</span><span class="muted small">${esc(new Date(h.ts).toLocaleString())}</span></summary>
      <div class="hist-res">${(h.results || []).map((r) => `<div><span class="${r.ok ? 'ok' : 'fail'}">${r.ok ? '✓' : '✕'}</span><span>${esc(r.action)}</span><b>${esc(name(r.id))}${r.option ? ` → ${esc(r.option)}` : ''}</b>${r.messages && r.messages.length ? `<em>${esc(r.messages.join(' · '))}</em>` : ''}</div>`).join('')}</div>
    </details>`).join('')}</div>
    <div class="row" style="margin-top:12px"><span class="spacer"></span><button class="btn ghost sm" data-act="clear-history">Clear history</button></div>` : '<div class="empty big">No changes yet.</div>'}`;
}

function pageSettings() {
  const s = S.settings;
  const u = S.updater || {};
  return `<div class="settings">
    <div class="panel">
      <h3>Appearance</h3>
      <div class="set-row"><div><b>Theme</b><span>Dark is tuned for late-night sessions.</span></div>
        <div class="seg">${['dark', 'light', 'system'].map((t) => `<button data-act="set" data-key="theme" data-val="${t}" class="${(s.theme || 'dark') === t ? 'active' : ''}">${t[0].toUpperCase() + t.slice(1)}</button>`).join('')}</div></div>
      <div class="set-row"><div><b>Accent</b><span>Highlight color across the app.</span></div>
        <div class="swatches">${ACCENTS.map((a) => `<button class="swatch ${(s.accent || 'falcon') === a.id ? 'active' : ''}" data-act="set" data-key="accent" data-val="${a.id}" title="${a.name}" style="--sw:${a.color}"><span></span>${a.name}</button>`).join('')}</div></div>
      <div class="set-row"><div><b>Density</b><span>Compact fits more tweaks on screen.</span></div>
        <div class="seg">${['comfortable', 'compact'].map((d) => `<button data-act="set" data-key="density" data-val="${d}" class="${(s.density || 'comfortable') === d ? 'active' : ''}">${d[0].toUpperCase() + d.slice(1)}</button>`).join('')}</div></div>
    </div>
    <div class="panel">
      <h3>Safety</h3>
      <div class="set-row"><div><b>Dry run</b><span>Show what would change without changing anything.</span></div><label class="switch"><input type="checkbox" id="setDry" ${s.dryRun ? 'checked' : ''}/><i></i></label></div>
      <div class="set-row"><div><b>Restore point before presets</b><span>Creates a Windows restore point before one-click apply.</span></div><label class="switch"><input type="checkbox" id="setRp" ${s.createRestorePoint !== false ? 'checked' : ''}/><i></i></label></div>
      ${s.customPreset ? `<div class="set-row"><div><b>Custom preset</b><span>${s.customPreset.ids.length} changes saved ${esc(new Date(s.customPreset.savedAt).toLocaleDateString())}.</span></div><button class="btn sm ghost" data-act="clear-custom">Delete</button></div>` : ''}
    </div>
    <div class="panel">
      <h3>About</h3>
      <dl class="kv">
        <dt>Version</dt><dd>${esc(S.info.version || '')}</dd>
        <dt>Administrator</dt><dd>${S.info.isAdmin ? 'Yes' : 'No'}</dd>
        <dt>Data folder</dt><dd class="mono">${esc(S.info.dataDir || '')}</dd>
        <dt>Updates</dt><dd>${esc(!S.info.packaged ? 'Automatic in installed builds (not when running from source)' : ({ 'not-available': 'Up to date', available: 'Update available', downloading: 'Downloading…', downloaded: 'Ready to install', checking: 'Checking…', error: 'Last check failed' }[u.lastCheckResult] || 'Automatic'))}</dd>
      </dl>
      <div class="row" style="margin-top:14px"><button class="btn" data-act="check-updates" ${S.info.packaged ? '' : 'disabled'}>Check for updates</button><button class="btn ghost" data-act="open-logs">Open logs</button>${S.info.isAdmin ? '' : '<button class="btn" data-act="relaunch-admin">Relaunch as admin</button>'}</div>
    </div>
  </div>`;
}

// ------------------------------------------------------------------ render
function renderBanner() {
  const b = $('#banner');
  if (S.reboot !== 'none') {
    b.hidden = false; b.className = 'banner reboot';
    b.innerHTML = `<span class="grow">${S.reboot === 'reboot' ? 'Restart Windows to finish applying your changes.' : 'Sign out and back in to finish applying your changes.'}</span>${S.reboot === 'reboot' ? '<button class="btn sm" data-act="restart-pc">Restart now</button>' : ''}<button class="icon-btn" data-act="dismiss-banner" aria-label="Dismiss">✕</button>`;
  } else if (S.info && S.info.isAdmin === false) {
    b.hidden = false; b.className = 'banner';
    b.innerHTML = '<span class="grow">Running without administrator rights — boot settings cannot be read and every change shows a UAC prompt.</span><button class="btn sm" data-act="relaunch-admin">Relaunch as admin</button>';
  } else b.hidden = true;
}

function render() {
  const r = ROUTES[S.route];
  const root = document.documentElement;
  root.dataset.theme = S.settings.theme || 'dark';
  root.dataset.accent = S.settings.accent || 'falcon';
  root.dataset.density = S.settings.density || 'comfortable';
  root.dataset.tier = tier();
  $('#pageTitle').textContent = r.title;
  $('#pageSub').textContent = r.sub;
  document.querySelectorAll('.nav-item').forEach((n) => n.classList.toggle('active', n.dataset.route === S.route));

  const ap = activePreset();
  $('#presetChip').innerHTML = `<span class="pc-label">Active preset</span><span class="pc-name ${ap.danger ? 'x' : ''}">${esc(ap.name)}</span>`;
  const admin = $('#adminState');
  admin.className = `admin-state ${S.info.isAdmin ? '' : 'no'}`;
  admin.innerHTML = `<span class="dot"></span>${S.info.isAdmin ? 'Administrator' : 'Standard user'}`;

  const actions = $('#topbarActions');
  if (S.route === 'tweaks') {
    const prev = $('#search');
    if (!prev) actions.innerHTML = `<label class="search">${svg('M15.5 14h-.8l-.3-.3A6.5 6.5 0 1 0 9.5 16a6.5 6.5 0 0 0 4.2-1.6l.3.3v.8l5 5 1.5-1.5zm-6 0a4.5 4.5 0 1 1 0-9 4.5 4.5 0 0 1 0 9')}<input type="search" id="search" placeholder="Search tweaks" value="${esc(S.search)}" /></label><button class="btn" data-act="rescan-states" ${S.detecting ? 'disabled' : ''}>Refresh status</button>`;
    else if (document.activeElement !== prev) prev.value = S.search;
  } else if (S.route === 'games') actions.innerHTML = '<button class="btn" data-act="rescan-games">Rescan</button><button class="btn primary" data-act="add-game">Add game</button>';
  else actions.innerHTML = '';

  renderBanner();
  const pages = { dashboard: pageDashboard, tweaks: pageTweaks, speedboost: pageSpeedBoost, games: pageGames, tools: pageTools, history: pageHistory, settings: pageSettings };
  const content = $('#content');
  const scroll = content.scrollTop;
  const open = [...content.querySelectorAll('details[open]')].map((d) => { const host = d.closest('[id]'); return host && host.id; }).filter(Boolean);
  content.innerHTML = `<div class="page page-${S.route}">${pages[S.route]()}</div>`;
  for (const id of open) { const el = document.getElementById(id); const d = el && el.querySelector('details'); if (d) d.open = true; }
  content.scrollTop = scroll;
}

async function go(route) {
  if (!ROUTES[route]) return;
  const changed = S.route !== route;
  S.route = route;
  render();
  if (changed) $('#content').scrollTop = 0;
  if (route === 'games' && !S.games) await loadGames(false);
  if (route === 'speedboost') await loadCleaner();
  if (route === 'history') {
    const r = await api.getHistory();
    if (r.ok) S.history = r.history;
    const c = await api.getCatalog();
    if (c.ok) { if (S.catalog) S.catalog.applied = c.applied; else S.catalog = c; }
    render();
  }
  if (route === 'tools') { if (!S.tools.length) { const r = await api.listTools(); if (r.ok) S.tools = r.tools; render(); } refreshTimer(); }
  if (route === 'settings') { S.updater = await api.updaterStatus(); render(); }
}

async function loadGames(rescan) {
  S.gamesLoading = true; render();
  const r = await api.listGames(!!rescan);
  S.gamesLoading = false;
  if (!r.ok) { toast(`Game scan failed: ${r.error}`, 'error'); S.games = []; render(); return; }
  S.games = r.games;
  render();
  await detectIds(S.games.flatMap((g) => g.items.map((i) => i.id)));
  render();
}

async function refreshTimer() {
  const r = await api.timerStatus();
  S.timer = r.ok ? r.status : null;
  if (S.route === 'tools') render();
}

async function saveSetting(patch, rerender = true) {
  const r = await api.setSettings(patch);
  if (r.ok) S.settings = r.settings;
  if (rerender) render();
}

// ------------------------------------------------------------------ events
document.addEventListener('click', async (e) => {
  const nav = e.target.closest('.nav-item');
  if (nav) return go(nav.dataset.route);
  if (e.target.closest('#modalClose') || e.target.id === 'modal') return closeModal();
  if (e.target.closest('#presetChip')) return go('dashboard');

  const el = e.target.closest('[data-act]');
  if (!el || el.disabled) return;
  const { act, id } = el.dataset;
  switch (act) {
    case 'preset': {
      const p = PRESETS.find((x) => x.id === el.dataset.preset);
      if (p) await saveSetting({ mode: p.mode, tier: p.tier });
      return;
    }
    case 'optimize': return openOptimize();
    case 'custom-preset': return openOptimize(S.settings.customPreset.ids);
    case 'rescan': await loadProfile(true); return detectAll();
    case 'rescan-states': return detectAll();
    case 'filter': S.filter = el.dataset.filter; return render();
    case 'cat': {
      S.cat = el.dataset.cat; S.search = '';
      const sb = $('#search'); if (sb) sb.value = '';
      $('#content').scrollTop = 0;
      return render();
    }
    case 'apply': return execute([{ id, action: 'apply' }], (itemById(id) || {}).name || 'Apply').then(() => { if (id === 'sched.timer_service') refreshTimer(); });
    case 'revert': return execute([{ id, action: 'revert' }], `Revert: ${(itemById(id) || {}).name || id}`).then(() => { if (id === 'sched.timer_service') refreshTimer(); });
    case 'run': return execute([{ id, action: 'run' }], (itemById(id) || {}).name || 'Run');
    case 'choose': {
      const it = itemById(id);
      const opt = it && it.options.find((o) => o.id === el.dataset.opt);
      return execute([{ id, option: el.dataset.opt, action: opt && opt.isDefault ? 'revert' : 'apply' }], `${it ? it.name : id}: ${opt ? opt.label : ''}`);
    }
    case 'game-opt': {
      const g = (S.games || []).find((x) => x.id === el.dataset.game);
      if (!g) return;
      return execute(g.items.filter((i) => i.preset && (S.states[i.id] || {}).state !== 'applied').map((i) => ({ id: i.id, action: 'apply' })), `Optimize ${g.name}`);
    }
    case 'add-game': { const r = await api.addCustomGame(); if (r.ok) await loadGames(false); return; }
    case 'remove-game': await api.removeCustomGame(el.dataset.game); return loadGames(false);
    case 'rescan-games': return loadGames(true);
    case 'undo-all': {
      const ok = await confirmModal({ title: 'Undo all Falcon changes?', body: '<p>Every setting Falcon changed is restored to its original value. A restart may be required afterwards. Removed bloat apps must be reinstalled from the Store.</p>', okLabel: 'Undo all', danger: true });
      if (!ok) return;
      S.busy = true; render();
      const r = await api.undoAll();
      S.busy = false;
      if (r.cancelled) toast(r.error || 'Cancelled.', 'error');
      else { toast(r.ok ? `Reverted ${r.results.length} change(s).` : 'Some changes could not be reverted — see History.', r.ok ? 'ok' : 'error'); if (r.reboot === 'reboot') S.reboot = 'reboot'; }
      await detectAll();
      return go('history');
    }
    case 'clear-history': await api.clearHistory(); S.history = []; return render();
    case 'clear-custom': return saveSetting({ customPreset: null });
    case 'open-logs': return api.openLogs();
    case 'url': return api.openExternal(el.dataset.url);
    case 'folder': { const r = await api.openToolFolder(el.dataset.folder); if (!r.ok) toast(r.error || 'Folder not found', 'error'); return; }
    case 'import-nip': { const r = await api.importNvidiaProfile(); if (!r.ok && !r.cancelled) toast(r.error || 'Import failed', 'error'); else if (r.ok) toast('NVIDIA Profile Inspector opened with the Falcon profile — confirm the import there.', 'ok'); return; }
    case 'timer-res': await saveSetting({ timerResolution: Number(el.dataset.res) }); await loadCatalog(); render(); return toast('Resolution saved — click Install / Reinstall to apply it.');
    case 'timer-refresh': return refreshTimer();
    case 'clean-scan': return scanCleaner();
    case 'clean-run': return runCleaner();
    case 'clean-pick': {
      const p = el.dataset.pick;
      S.cleanSel = new Set(p === 'all' ? S.cleaner.targets.map((t) => t.id) : p === 'rec' ? S.cleaner.targets.filter((t) => t.default).map((t) => t.id) : []);
      saveCleanSel();
      return render();
    }
    case 'set': return saveSetting({ [el.dataset.key]: el.dataset.val });
    case 'relaunch-admin': { const r = await api.relaunchAsAdmin(); if (!r.ok) toast(r.error, 'error'); return; }
    case 'restart-pc': { const ok = await confirmModal({ title: 'Restart now?', body: '<p>Windows restarts in 5 seconds. Save your work first.</p>', okLabel: 'Restart' }); if (ok) await api.restartPc(); return; }
    case 'dismiss-banner': S.reboot = 'none'; return renderBanner();
    case 'check-updates': { const r = await api.checkForUpdates(); toast(r.ok ? 'Checking for updates…' : r.message || 'Update check failed', r.ok ? '' : 'error'); return; }
    default:
  }
});

document.addEventListener('input', (e) => { if (e.target.id === 'search') { S.search = e.target.value; render(); } });
document.addEventListener('change', async (e) => {
  if (e.target.id === 'setDry') { await saveSetting({ dryRun: e.target.checked }); toast(e.target.checked ? 'Dry run on — nothing will be changed.' : 'Dry run off.'); }
  if (e.target.id === 'setRp') await saveSetting({ createRestorePoint: e.target.checked });
  if (e.target.dataset && e.target.dataset.clean) {
    if (e.target.checked) S.cleanSel.add(e.target.dataset.clean); else S.cleanSel.delete(e.target.dataset.clean);
    saveCleanSel();
    render();
  }
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !$('#modal').hidden) closeModal();
  if (e.ctrlKey && e.key.toLowerCase() === 'f' && S.route === 'tweaks') { e.preventDefault(); const s = $('#search'); if (s) s.focus(); }
});

// ------------------------------------------------------------------ boot
(async function boot() {
  const [info, settings] = await Promise.all([api.info(), api.getSettings()]);
  S.info = info.ok ? info : {};
  if (settings.ok) S.settings = settings.settings;
  $('#appVersion').textContent = S.info.version ? `v${S.info.version}` : '';
  render();
  api.onUpdateStatus((p) => {
    S.updater = { ...(S.updater || {}), lastCheckResult: p.status };
    if (p.status === 'available') toast(`Update ${p.version || ''} available — downloading.`);
    if (p.status === 'downloaded') toast('Update downloaded — restarting to install.');
    if (S.route === 'settings') render();
  });
  await loadProfile(false);
  await loadCatalog();
  render();
  await detectAll();
})();
