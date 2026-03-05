#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const tweaksDir = path.join(root, 'tweaks');

function templateFor(item) {
  const text = `${item.category || ''} ${item.description || ''} ${item.id || ''}`.toLowerCase();
  const maybe = (k, fallback) => text.includes(k) ? fallback : null;
  return {
    recommendedFor: maybe('network', 'Online competitive players prioritizing packet consistency.') || 'Users targeting smoother gameplay and reduced background overhead.',
    benefits: [
      maybe('telemetry', 'Reduces diagnostics/background noise.') || 'Improves responsiveness for target scenario.'
    ],
    tradeoffs: [
      maybe('defender', 'Can lower built-in security defaults.') || 'May reduce convenience features or compatibility on some systems.'
    ],
    riskNotes: [String(item.risk || item.riskLevel || 'Safe') + ' risk. Validate before wide rollout.'],
    reversible: ((item.revert && item.revert.steps && item.revert.steps.length) ? 'Use Revert to restore defaults.' : 'No explicit revert steps in this item.'),
    requiresReboot: !!item.requiresReboot
  };
}

for (const file of fs.readdirSync(tweaksDir)) {
  if (!file.endsWith('.json')) continue;
  const full = path.join(tweaksDir, file);
  let json;
  try { json = JSON.parse(fs.readFileSync(full, 'utf8')); } catch { continue; }
  if (!Array.isArray(json.items)) continue;
  let changed = false;
  for (const item of json.items) {
    const tpl = templateFor(item);
    const existing = (item && item.details && typeof item.details === 'object') ? item.details : {};
    const next = { ...existing };
    for (const key of ['recommendedFor','benefits','tradeoffs','riskNotes','reversible','requiresReboot']) {
      const cur = existing[key];
      const missing = (cur === undefined || cur === null || (typeof cur === 'string' && !cur.trim()) || (Array.isArray(cur) && cur.length === 0));
      if (missing) next[key] = tpl[key];
    }
    const before = JSON.stringify(existing);
    const after = JSON.stringify(next);
    if (before !== after) {
      item.details = next;
      changed = true;
    }
  }
  if (changed) fs.writeFileSync(full, JSON.stringify(json, null, 2) + '\n');
}
console.log('Done');
