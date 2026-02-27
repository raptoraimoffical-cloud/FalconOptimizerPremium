
'use strict';

const fs = require('fs');
const path = require('path');

function listJsonFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listJsonFiles(p));
    else if (entry.isFile() && entry.name.toLowerCase().endsWith('.json')) out.push(p);
  }
  return out;
}

function collectItems(obj) {
  const items = [];
  const visit = (node) => {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node.items)) {
      for (const it of node.items) {
        if (it && typeof it === 'object') items.push(it);
      }
    }
    for (const k of Object.keys(node)) visit(node[k]);
  };
  visit(obj);
  return items;
}

function validateCatalogs(projectRoot) {
  const tweaksDir = path.join(projectRoot, 'tweaks');
  const report = { ts: new Date().toISOString(), totals: {}, problems: [] };

  if (!fs.existsSync(tweaksDir)) {
    report.totals = { catalogs: 0, items: 0 };
    report.problems.push({ type: 'missing_dir', message: 'tweaks/ directory not found' });
    return report;
  }

  const files = listJsonFiles(tweaksDir);
  let totalItems = 0;

  for (const file of files) {
    let json;
    try {
      json = JSON.parse(fs.readFileSync(file, 'utf8'));
    } catch (e) {
      report.problems.push({ type: 'json_parse', file, message: String(e.message || e) });
      continue;
    }

    const items = collectItems(json);
    totalItems += items.length;

    for (const it of items) {
      const id = it.id || it.key || it.name || it.title || 'unknown';
      const applySteps = (it.apply && Array.isArray(it.apply.steps)) ? it.apply.steps
        : (it.action && it.action.steps && Array.isArray(it.action.steps)) ? it.action.steps
        : null;

      if (!applySteps) continue;

      if (applySteps.length === 0) {
        report.problems.push({ type: 'empty_steps', file, id, title: it.title || it.name || '', message: 'apply.steps is empty' });
      }

      // Flag unknown step types (best-effort)
      for (const st of applySteps) {
        if (!st || typeof st !== 'object') continue;
        const t = String(st.type || '');
        if (!t) report.problems.push({ type: 'missing_step_type', file, id, title: it.title || '', step: st });
      }
    }
  }

  report.totals = { catalogs: files.length, items: totalItems, problems: report.problems.length };
  return report;
}

module.exports = { validateCatalogs };
