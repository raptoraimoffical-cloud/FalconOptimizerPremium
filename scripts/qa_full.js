const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'tweaks', '_manifest.json');
const runActionPath = path.join(root, 'scripts', 'run-action.ps1');
const reportPath = path.join(root, 'QA_REPORT.txt');

function readJson(p){ return JSON.parse(fs.readFileSync(p,'utf8')); }
function walkSteps(obj, out=[]){
  if (!obj || typeof obj !== 'object') return out;
  if (Array.isArray(obj.steps)) obj.steps.forEach(s=>out.push(s));
  ['apply','check','revert','fix'].forEach(k=>{ if(obj[k]) walkSteps(obj[k], out); });
  return out;
}

const report=[];
const errors=[];
const warnings=[];

const manifest = readJson(manifestPath);
report.push(`Manifest files: ${manifest.files.length}`);
const allTweaks=[];
for (const rel of manifest.files){
  const abs = path.join(root, rel);
  if (!fs.existsSync(abs)) { errors.push(`Missing file: ${rel}`); continue; }
  try {
    const j=readJson(abs);
    const items = Array.isArray(j.items)?j.items:[];
    items.forEach(i=>allTweaks.push({file:rel,item:i}));
  } catch (e){ errors.push(`JSON parse failed: ${rel} :: ${e.message}`); }
}
report.push(`Parsed tweak items: ${allTweaks.length}`);

const idMap=new Map();
for (const {file,item} of allTweaks){
  if (!item.id) errors.push(`Missing id in ${file}`);
  if (!item.name) errors.push(`Missing name in ${file} id=${item.id||'unknown'}`);
  if (!item.category) errors.push(`Missing category in ${file} id=${item.id||'unknown'}`);
  const applySteps = item.apply && Array.isArray(item.apply.steps) ? item.apply.steps : null;
  if (!applySteps || !applySteps.length) warnings.push(`No apply steps: ${file} id=${item.id||'unknown'}`);
  if (item.id){
    if (!idMap.has(item.id)) idMap.set(item.id,[]);
    idMap.get(item.id).push(file);
  }
}
for (const [id,files] of idMap){ if(files.length>1) errors.push(`Duplicate id: ${id} in ${[...new Set(files)].join(', ')}`); }

const runAction = fs.readFileSync(runActionPath,'utf8');
const implementedTypes = new Set([...runAction.matchAll(/^\s*"([a-zA-Z0-9._-]+)"\s*\{/gm)].map(m=>m[1]));
report.push(`Runner step handlers: ${implementedTypes.size}`);

const stepTypes=new Set();
for (const {item} of allTweaks){
  for (const s of walkSteps(item,[])){
    if (s && s.type) stepTypes.add(s.type);
    if (s && s.type==='falconlib.run' && s.toolPath){
      const candidates=[
        path.join(root,s.toolPath),
        path.join(root,'tools',s.toolPath),
        path.join(root,'FalconLibrary',s.toolPath),
        path.join(root,'FalconLibrary','FalconLibrary',s.toolPath)
      ];
      if (!candidates.some(c=>fs.existsSync(c))) errors.push(`Missing falconlib toolPath: ${s.toolPath}`);
    }
  }
}
for (const t of stepTypes){ if (!implementedTypes.has(t)) errors.push(`No handler for step type: ${t}`); }
report.push(`Unique step types in tweaks: ${stepTypes.size}`);

const strictHits=[...runAction.matchAll(/\$[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*/g)].map(m=>m[0]);
report.push(`StrictMode property access scan matches: ${strictHits.length}`);
if (strictHits.length>0) warnings.push('Review property access manually for null/missing guards.');

report.push('');
if (errors.length){ report.push('ERRORS:'); errors.forEach(e=>report.push(`- ${e}`)); }
if (warnings.length){ report.push('WARNINGS:'); warnings.slice(0,60).forEach(w=>report.push(`- ${w}`)); if (warnings.length>60) report.push(`- ... ${warnings.length-60} more warnings`); }
report.push('');
report.push(`QA STATUS: ${errors.length? 'FAIL':'PASS'}`);
fs.writeFileSync(reportPath, report.join('\n'));
console.log(`Wrote ${path.relative(root, reportPath)} with status ${errors.length? 'FAIL':'PASS'}`);
if (errors.length) process.exit(1);
