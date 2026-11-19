'use strict';
/**
 * Falcon catalog.
 *
 * Item kinds
 *   toggle  apply/revert with real state detection
 *   choice  mutually exclusive options (e.g. Latency vs FPS); revert = the isDefault option
 *   action  one-shot maintenance task (run), no persistent state
 *
 * Presets
 *   One-click Optimize applies every applicable toggle whose `presets` includes the selected
 *   mode, and for choices the option whose `presets` includes the mode. Input latency wins every
 *   conflict in Latency mode; FPS mode resolves conflicts toward throughput/boost headroom.
 *
 * Tiers
 *   regular  daily-driver safe: the PC keeps working exactly as before (default)
 *   extreme  strips Windows down for a dedicated gaming PC; items break things on purpose and
 *            say exactly what in `tradeoff`. Extreme presets = regular + extreme items.
 */

const CATEGORIES = [
  { id: 'input', label: 'Input & Peripherals', icon: 'mouse', blurb: 'Mouse, keyboard and USB power — the first link in the input chain.' },
  { id: 'scheduler', label: 'Scheduler & Timers', icon: 'clock', blurb: 'How quickly Windows schedules the game thread and wakes on timers.' },
  { id: 'power', label: 'Power & CPU', icon: 'bolt', blurb: 'Boost behavior, idle states and device power management.' },
  { id: 'gpu', label: 'GPU & Display', icon: 'display', blurb: 'Presentation path, GPU scheduling and capture overhead.' },
  { id: 'network', label: 'Network', icon: 'net', blurb: 'NIC latency settings and removing old network "optimizations" that hurt.' },
  { id: 'windows', label: 'Windows & Background', icon: 'win', blurb: 'Background work that competes with your game for CPU, disk and bandwidth.' },
  { id: 'extreme', label: 'Extreme Strip-Down', icon: 'flame', blurb: 'For dedicated gaming PCs only. Each change removes a Windows feature to cut background work — read the trade-off on every card.' },
  { id: 'security', label: 'Security Trade-offs', icon: 'shield', blurb: 'The biggest remaining FPS gains, at the cost of real protection. Only applied by Extreme presets.' },
  { id: 'maintenance', label: 'Maintenance', icon: 'wrench', blurb: 'One-shot cleanup and repair tools.' }
];

const MODULES = ['input', 'scheduler', 'power', 'gpu', 'network', 'windows', 'extreme', 'security', 'maintenance'];
const TIERS = new Set(['regular', 'extreme']);
const RISKS = new Set(['safe', 'moderate', 'advanced']);
const KINDS = new Set(['toggle', 'choice', 'action']);
const REBOOTS = new Set(['none', 'signout', 'reboot']);
const STEP_TYPES = new Set(['reg', 'service', 'task', 'bcd', 'powercfg', 'netadapter', 'ps']);
const REG_TYPES = new Set(['DWORD', 'QWORD', 'SZ', 'EXPAND_SZ', 'MULTI_SZ', 'BINARY']);

function validateSteps(id, steps, where, errors) {
  if (!Array.isArray(steps)) { errors.push(`${id}: ${where} must be an array`); return; }
  for (const s of steps) {
    if (!s || !STEP_TYPES.has(s.type)) { errors.push(`${id}: ${where} has unknown step type ${s && s.type}`); continue; }
    if (s.type === 'reg') {
      if (!s.path || typeof s.name !== 'string') errors.push(`${id}: reg step missing path/name`);
      if (!s.delete && !REG_TYPES.has(s.regType)) errors.push(`${id}: reg step has bad regType ${s.regType}`);
      if (!/^(HKLM|HKCU|HKCR|HKU)\\/.test(s.path)) errors.push(`${id}: reg path must start with a hive: ${s.path}`);
    }
    if (s.type === 'ps' && !s.script) errors.push(`${id}: ps step missing script`);
  }
}

function evalWhen(fn, ctx) {
  if (typeof fn !== 'function') return null;
  try { return fn(ctx) || null; } catch (e) { return `Applicability check failed: ${e.message}`; }
}

/**
 * @param {{ profile: object, settings: object }} input
 * @returns {{ categories: object[], items: object[], errors: string[] }}
 */
function buildCatalog({ profile, settings = {} }) {
  const ctx = { profile, settings, isLaptop: profile.formFactor === 'laptop' };
  const errors = [];
  const seen = new Set();
  const items = [];

  for (const mod of MODULES) {
    // Fresh require each build so catalog edits apply on reload during development.
    const file = require.resolve(`./${mod}`);
    delete require.cache[file];
    const raw = require(file)(ctx);
    for (const it of raw) {
      if (seen.has(it.id)) errors.push(`duplicate id ${it.id}`);
      seen.add(it.id);
      if (!KINDS.has(it.kind)) errors.push(`${it.id}: bad kind ${it.kind}`);
      if (!RISKS.has(it.risk)) errors.push(`${it.id}: bad risk ${it.risk}`);
      if (!REBOOTS.has(it.reboot)) errors.push(`${it.id}: bad reboot ${it.reboot}`);
      if (!it.name || !it.summary) errors.push(`${it.id}: missing name/summary`);
      if (it.category !== mod) errors.push(`${it.id}: category ${it.category} does not match module ${mod}`);

      if (it.tier && !TIERS.has(it.tier)) errors.push(`${it.id}: bad tier ${it.tier}`);
      if (it.risk === 'advanced' && (it.presets || []).length && it.tier !== 'extreme') errors.push(`${it.id}: advanced items may only be in Extreme presets`);
      if (it.tier === 'extreme' && !it.tradeoff && it.kind !== 'action') errors.push(`${it.id}: extreme items must state their trade-off`);
      const out = { ...it, tier: it.tier || 'regular', presets: it.presets || [], tags: it.tags || [], impact: it.impact || { latency: 0, fps: 0 } };
      delete out.when;
      out.naReason = evalWhen(it.when, ctx);
      out.applicable = !out.naReason;

      if (it.kind === 'toggle') {
        validateSteps(it.id, it.apply, 'apply', errors);
        validateSteps(it.id, it.revert, 'revert', errors);
        if (!it.apply || it.apply.length === 0) { if (out.applicable) errors.push(`${it.id}: toggle has no apply steps`); }
      } else if (it.kind === 'choice') {
        if (!Array.isArray(it.options) || it.options.length < 2) errors.push(`${it.id}: choice needs 2+ options`);
        if (!(it.options || []).some((o) => o.isDefault)) errors.push(`${it.id}: choice needs an isDefault option`);
        out.options = (it.options || []).map((o) => {
          validateSteps(`${it.id}/${o.id}`, o.apply, 'apply', errors);
          const oo = { ...o, presets: o.presets || [] };
          delete oo.when;
          oo.naReason = evalWhen(o.when, ctx);
          return oo;
        });
      } else if (it.kind === 'action') {
        validateSteps(it.id, it.run, 'run', errors);
      }
      items.push(out);
    }
  }
  return { categories: CATEGORIES, items, errors };
}

/** Engine payload for an item in a given mode. For choices pass optionId. */
function engineItem(item, mode, optionId) {
  if (item.kind === 'action') return { id: item.id, apply: item.run, revert: [] };
  if (item.kind === 'choice') {
    const opt = item.options.find((o) => o.id === optionId) || item.options.find((o) => o.isDefault);
    return { id: `${item.id}#${opt.id}`, apply: opt.apply, revert: [] };
  }
  return { id: item.id, apply: item.apply, revert: item.revert || [] };
}

module.exports = { buildCatalog, engineItem, CATEGORIES };
