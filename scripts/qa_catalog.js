#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const manifestPath = path.join(repoRoot, 'tweaks', '_manifest.json');
const reportPath = path.join(repoRoot, 'QA_REPORT.txt');

function readJson(p){
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function getStepsFromItem(item){
  const modes = ['apply','revert','check','fix','verify'];
  const out = [];
  for(const m of modes){
    if(item && item[m] && Array.isArray(item[m].steps)){
      for(const s of item[m].steps) out.push({ mode:m, step:s });
    }
  }
  if (Array.isArray(item.steps)) {
    for (const s of item.steps) out.push({ mode:'steps', step:s });
  }
  return out;
}

const lines = [];
const errors = [];
const warns = [];

let manifest = null;
try {
  manifest = readJson(manifestPath);
} catch (e) {
  errors.push(`Manifest parse failure: ${e.message}`);
}

const files = (manifest && Array.isArray(manifest.files)) ? manifest.files : [];
const seenIds = new Map();
let totalTweaks = 0;
let totalSteps = 0;
const stepTypeCounts = new Map();
const riskRawCounts = new Map();
const catSet = new Set();
const malformed = [];

for(const rel of files){
  const abs = path.join(repoRoot, rel);
  if(!fs.existsSync(abs)){
    errors.push(`Missing file in manifest: ${rel}`);
    continue;
  }

  let data = null;
  try {
    data = readJson(abs);
  } catch (e) {
    errors.push(`JSON parse failure: ${rel} :: ${e.message}`);
    continue;
  }

  const items = Array.isArray(data.items) ? data.items : [];
  for(const item of items){
    totalTweaks += 1;
    const id = item && item.id ? String(item.id) : '';
    const name = item && item.name != null ? String(item.name) : '';
    const category = item && item.category != null ? String(item.category) : '';
    const risk = String((item && (item.riskLevel || item.risk)) || '').trim();
    if(risk) riskRawCounts.set(risk, (riskRawCounts.get(risk)||0)+1);
    if(category) catSet.add(category);

    if(!id || !name || !category) malformed.push(`${rel} :: missing required field(s) id/name/category for item ${id || '<no-id>'}`);

    const stepEntries = getStepsFromItem(item);
    if(stepEntries.length === 0) malformed.push(`${rel} :: tweak ${id || '<no-id>'} has no steps in apply/revert/check/fix/verify/steps`);

    for(const {mode, step} of stepEntries){
      totalSteps += 1;
      const type = step && step.type ? String(step.type) : '<missing-type>';
      stepTypeCounts.set(type, (stepTypeCounts.get(type)||0)+1);
      if(type === '<missing-type>') malformed.push(`${rel} :: tweak ${id || '<no-id>'} has step without type in mode ${mode}`);
    }

    if(!id) continue;
    if(seenIds.has(id)){
      errors.push(`Duplicate tweak id: ${id} in ${rel} and ${seenIds.get(id)}`);
    } else {
      seenIds.set(id, rel);
    }
  }
}

if(malformed.length) warns.push(...malformed);

lines.push('Falcon Optimizer Catalog QA Report');
lines.push(`Generated: ${new Date().toISOString()}`);
lines.push('');
lines.push('Summary');
lines.push(`Manifest files listed: ${files.length}`);
lines.push(`Unique categories: ${catSet.size}`);
lines.push(`Total tweaks: ${totalTweaks}`);
lines.push(`Total steps: ${totalSteps}`);
lines.push('');
lines.push('Step type counts:');
for(const [k,v] of [...stepTypeCounts.entries()].sort((a,b)=>String(a[0]).localeCompare(String(b[0])))){
  lines.push(`- ${k}: ${v}`);
}
lines.push('');
lines.push('Raw risk values:');
for(const [k,v] of [...riskRawCounts.entries()].sort((a,b)=>String(a[0]).localeCompare(String(b[0])))){
  lines.push(`- ${k}: ${v}`);
}
lines.push('');
lines.push(`Errors (${errors.length}):`);
for(const e of errors) lines.push(`- ${e}`);
lines.push('');
lines.push(`Warnings (${warns.length}):`);
for(const w of warns) lines.push(`- ${w}`);

fs.writeFileSync(reportPath, lines.join('\n') + '\n', 'utf8');

if(errors.length){
  console.error(lines.join('\n'));
  process.exit(1);
}
console.log(lines.join('\n'));
