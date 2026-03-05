#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'tweaks', '_manifest.json');
const reportPath = path.join(root, 'QA_LINKS_REPORT.txt');

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function normalizePath(p) {
  return String(p || '').replace(/\\/g, '/');
}

function collectFalconlibRunSteps(manifestFiles) {
  const steps = [];

  for (const relPath of manifestFiles) {
    const filePath = path.join(root, relPath);
    if (!fs.existsSync(filePath) || path.extname(filePath).toLowerCase() !== '.json') continue;

    let doc;
    try {
      doc = readJson(filePath);
    } catch (error) {
      console.error(`ERROR invalid-json file=${relPath} message=${error.message}`);
      continue;
    }

    const containers = [];
    if (Array.isArray(doc.tweaks)) containers.push(...doc.tweaks);
    if (Array.isArray(doc.items)) containers.push(...doc.items);

    for (const tweak of containers) {
      const tweakId = tweak?.id || tweak?.name || relPath;
      const groups = [tweak?.apply, tweak?.revert, tweak?.check, tweak?.fix];
      if (Array.isArray(tweak?.steps)) groups.push({ steps: tweak.steps });

      for (const group of groups) {
        if (!group || !Array.isArray(group.steps)) continue;
        for (const step of group.steps) {
          if (step?.type !== 'falconlib.run') continue;
          steps.push({
            tweakId,
            tweakFile: relPath,
            toolPath: normalizePath(step.toolPath)
          });
        }
      }
    }
  }

  return steps;
}

const manifest = readJson(manifestPath);
const manifestFiles = Array.isArray(manifest.files) ? manifest.files : [];
const runSteps = collectFalconlibRunSteps(manifestFiles);

const errors = [];
let valid = 0;
let invalid = 0;
let legacyReferences = 0;

for (const entry of runSteps) {
  const toolPath = entry.toolPath;
  const isLegacy = toolPath.startsWith('FalconLibrary/') || toolPath.startsWith('FalconLibrary/FalconLibrary/');
  if (isLegacy) {
    legacyReferences += 1;
    invalid += 1;
    errors.push(`ERROR legacy-toolpath tweak=${entry.tweakId} file=${entry.tweakFile} toolPath=${toolPath}`);
    continue;
  }

  if (!toolPath) {
    invalid += 1;
    errors.push(`ERROR missing-toolpath tweak=${entry.tweakId} file=${entry.tweakFile}`);
    continue;
  }

  const absoluteToolPath = path.join(root, toolPath);
  if (!fs.existsSync(absoluteToolPath)) {
    invalid += 1;
    errors.push(`ERROR missing-tool tweak=${entry.tweakId} file=${entry.tweakFile} toolPath=${toolPath}`);
    continue;
  }

  valid += 1;
}

const summary = [
  `falconlib.run steps: ${runSteps.length}`,
  `valid: ${valid}`,
  `invalid: ${invalid}`,
  `legacy references: ${legacyReferences}`
];

const reportLines = ['QA_LINKS_REPORT', `generated: ${new Date().toISOString()}`, '', ...summary, ''];
if (errors.length) {
  reportLines.push('errors:');
  reportLines.push(...errors);
} else {
  reportLines.push('errors: none');
}

fs.writeFileSync(reportPath, reportLines.join('\n') + '\n', 'utf8');
console.log(reportLines.join('\n'));
process.exit(errors.length > 0 ? 1 : 0);
