#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'tweaks', '_manifest.json');
const reportPath = path.join(root, 'QA_LINKS_REPORT.txt');

const readJson = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const normalize = (p) => String(p || '').replace(/\\/g, '/');

function collectFalconRunSteps() {
  const manifest = readJson(manifestPath);
  const files = Array.isArray(manifest.files) ? manifest.files : [];
  const out = [];

  for (const rel of files) {
    const abs = path.join(root, rel);
    if (!fs.existsSync(abs) || path.extname(abs).toLowerCase() !== '.json') continue;

    let data;
    try { data = readJson(abs); } catch { continue; }

    const cards = [];
    if (Array.isArray(data.tweaks)) cards.push(...data.tweaks);
    if (Array.isArray(data.items)) cards.push(...data.items);

    for (const card of cards) {
      const id = card.id || card.name || rel;
      const groups = [card.apply, card.revert, card.check, card.fix];
      if (Array.isArray(card.steps)) groups.push({ steps: card.steps });
      for (const group of groups) {
        if (!group || !Array.isArray(group.steps)) continue;
        for (const step of group.steps) {
          if (!step || step.type !== 'falconlib.run') continue;
          out.push({
            tweakId: id,
            tweakFile: rel,
            toolPath: normalize(step.toolPath || ''),
            elevation: String(step.elevation || 'none').toLowerCase()
          });
        }
      }
    }
  }

  return out;
}

function walkHasEntries(dir) {
  if (!fs.existsSync(dir)) return false;
  const stack = [dir];
  while (stack.length) {
    const cur = stack.pop();
    for (const ent of fs.readdirSync(cur, { withFileTypes: true })) {
      const full = path.join(cur, ent.name);
      if (ent.isDirectory()) stack.push(full);
      else return true;
    }
  }
  return false;
}

const runSteps = collectFalconRunSteps();
const failures = [];
const warnings = [];
let passing = 0;

for (const step of runSteps) {
  const hasLegacyPrefix = step.toolPath.startsWith('FalconLibrary/') || step.toolPath.startsWith('FalconLibrary/FalconLibrary/');
  const expectedAbs = path.join(root, step.toolPath);
  const exists = !!step.toolPath && fs.existsSync(expectedAbs);

  if (hasLegacyPrefix) {
    failures.push(`FAIL legacy-root-reference tweakId=${step.tweakId} file=${step.tweakFile} toolPath=${step.toolPath}`);
    continue;
  }

  if (!exists) {
    failures.push(`FAIL missing-tool tweakId=${step.tweakId} file=${step.tweakFile} toolPath=${step.toolPath} expected=${expectedAbs}`);
  } else {
    passing += 1;
  }
}

const legacyRoot = path.join(root, 'FalconLibrary');
const legacyNestedRoot = path.join(root, 'FalconLibrary', 'FalconLibrary');
if (walkHasEntries(legacyRoot)) warnings.push(`WARN legacy root still exists: ${legacyRoot}`);
if (walkHasEntries(legacyNestedRoot)) warnings.push(`WARN nested legacy root still exists: ${legacyNestedRoot}`);

const hasTrustedInstaller = runSteps.some((s) => s.elevation === 'trustedinstaller');
const nsudoPath = path.join(root, 'tools/FalconLibrary/NSudo/NSudoLG.exe');
if (hasTrustedInstaller && !fs.existsSync(nsudoPath)) {
  failures.push(`FAIL trustedinstaller-requires-nsudo missing=${nsudoPath}`);
}

const hasTimerCard = runSteps.some((s) => /timer_resolution/i.test(s.tweakId) || /SetTimerResolution\.exe$/i.test(s.toolPath));
const timerPath = path.join(root, 'tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe');
if (hasTimerCard && !fs.existsSync(timerPath)) {
  failures.push(`FAIL timer-resolution-tool-missing missing=${timerPath}`);
}

const report = [];
report.push('QA LINKS REPORT');
report.push(`Generated: ${new Date().toISOString()}`);
report.push('');
report.push(`total falconlib.run steps: ${runSteps.length}`);
report.push(`number passing: ${passing}`);
report.push(`number failing: ${failures.length}`);
report.push('');
report.push('Warnings:');
if (warnings.length) warnings.forEach((w) => report.push(`- ${w}`));
else report.push('- none');
report.push('');
report.push('Failures:');
if (failures.length) failures.forEach((f) => report.push(`- ${f}`));
else report.push('- none');

fs.writeFileSync(reportPath, report.join('\n') + '\n', 'utf8');
console.log(report.join('\n'));
process.exit(failures.length ? 1 : 0);
