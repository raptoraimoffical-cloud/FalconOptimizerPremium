#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'tweaks', '_manifest.json');
const runnerPath = path.join(root, 'scripts', 'run-action.ps1');
const reportPath = path.join(root, 'QA_LINKS_REPORT.txt');

const ALLOWLIST_NOT_USER_FACING = new Set([
  'tools/FalconLibrary/NSudo/NSudoLG.exe'
]);

function readJson(p){ return JSON.parse(fs.readFileSync(p, 'utf8')); }
function normRel(p){ return p.split(path.sep).join('/'); }

function walkToolFiles(dir){
  const out=[];
  if(!fs.existsSync(dir)) return out;
  const stack=[dir];
  while(stack.length){
    const cur=stack.pop();
    for(const ent of fs.readdirSync(cur,{withFileTypes:true})){
      const full=path.join(cur,ent.name);
      if(ent.isDirectory()) stack.push(full);
      else if(/\.(exe|bat|ps1|cmd)$/i.test(ent.name)) out.push(normRel(path.relative(root, full)));
    }
  }
  out.sort((a,b)=>a.localeCompare(b));
  return out;
}

function traverse(node, fn, ctx={}){
  if(Array.isArray(node)) return node.forEach((n)=>traverse(n,fn,ctx));
  if(!node || typeof node!=='object') return;
  fn(node, ctx);
  const nextCtx = {...ctx};
  if(node.id && (node.apply || node.revert || node.check || node.steps)) nextCtx.item=node;
  for(const v of Object.values(node)) if(v && typeof v==='object') traverse(v,fn,nextCtx);
}

const manifest = readJson(manifestPath);
const files = Array.isArray(manifest.files)?manifest.files:[];
const allIds = new Map();
const duplicateIds = [];
const nullNameOrCategory = [];
const falconRun = [];
const stepTypesUsed = new Set();

for(const rel of files){
  const abs=path.join(root, rel);
  if(!fs.existsSync(abs)) continue;
  let data;
  try{ data=readJson(abs); }catch{ continue; }
  traverse(data, (node, ctx)=>{
    if(node.id && (node.apply || node.revert || node.check || node.steps)){
      const id=String(node.id);
      if(allIds.has(id)) duplicateIds.push({id, first:allIds.get(id), second:rel});
      else allIds.set(id, rel);
      if(node.name == null || node.category == null) nullNameOrCategory.push({id, file:rel, name:node.name, category:node.category});
    }
    if(node.type && typeof node.type==='string' && (Object.prototype.hasOwnProperty.call(node,'command') || Object.prototype.hasOwnProperty.call(node,'path') || Object.prototype.hasOwnProperty.call(node,'toolPath') || Object.prototype.hasOwnProperty.call(node,'name') || Object.prototype.hasOwnProperty.call(node,'url') || Object.prototype.hasOwnProperty.call(node,'args') || Object.prototype.hasOwnProperty.call(node,'action'))) stepTypesUsed.add(node.type);
    if(node.type === 'falconlib.run'){
      const item = ctx.item || {};
      falconRun.push({
        id:item.id||'', name:item.name||'', category:item.category||'',
        toolPath:String(node.toolPath||''), elevation:String(node.elevation||'none'), file:rel
      });
    }
  });
}

const missingFalconPaths = [];
for(const step of falconRun){
  const abs = path.join(root, step.toolPath);
  if(!step.toolPath || !fs.existsSync(abs)) missingFalconPaths.push(step);
}

const toolFiles = walkToolFiles(path.join(root, 'tools', 'FalconLibrary'));
const referenced = new Set(falconRun.map((s)=>normRel(s.toolPath)));
const unreferencedTools = toolFiles.filter((t)=>!referenced.has(t) && !ALLOWLIST_NOT_USER_FACING.has(t));

const runnerText = fs.readFileSync(runnerPath, 'utf8');
const implementedTypes = new Set();
for(const m of runnerText.matchAll(/"([a-zA-Z0-9_.-]+)"\s*\{/g)) implementedTypes.add(m[1]);
const missingHandlers = [...stepTypesUsed].filter((t)=>!implementedTypes.has(t)).sort();

const hasServiceShape = /Get-ServiceInfoSafe[\s\S]*?catch\s*\{[\s\S]*?startMode\s*=\s*""[\s\S]*?state\s*=\s*""/m.test(runnerText);
const timerCard = falconRun.find((x)=>x.id==='falcon.timer_resolution.apply');
const timerCardExists = !!(timerCard && fs.existsSync(path.join(root, timerCard.toolPath)) && normRel(timerCard.toolPath)==='tools/FalconLibrary/Timer Resolution/SetTimerResolution.exe');

const ok = !missingFalconPaths.length && !duplicateIds.length && !nullNameOrCategory.length && !missingHandlers.length && hasServiceShape && timerCardExists && !unreferencedTools.length;

let out = '';
out += `QA LINKS REPORT\nGenerated: ${new Date().toISOString()}\n\n`;
out += `Manifest files scanned: ${files.length}\n`;
out += `falconlib.run steps: ${falconRun.length}\n`;
out += `tools/FalconLibrary tool files: ${toolFiles.length}\n\n`;
out += `Checks\n`;
out += `- Missing falconlib tool paths: ${missingFalconPaths.length}\n`;
out += `- Unreferenced tools (non-allowlisted): ${unreferencedTools.length}\n`;
out += `- Duplicate tweak IDs: ${duplicateIds.length}\n`;
out += `- Null name/category items: ${nullNameOrCategory.length}\n`;
out += `- Step types missing runner handlers: ${missingHandlers.length}\n`;
out += `- Get-ServiceInfoSafe full missing-shape: ${hasServiceShape ? 'yes':'no'}\n`;
out += `- Timer Resolution card canonical path valid: ${timerCardExists ? 'yes':'no'}\n`;
out += `\nResult: ${ok ? 'PASS':'FAIL'}\n\n`;

if(missingFalconPaths.length){
  out += 'Missing falconlib tool paths:\n';
  for(const m of missingFalconPaths) out += `- ${m.id} :: ${m.toolPath} (${m.file})\n`;
  out += '\n';
}
if(unreferencedTools.length){
  out += 'Unreferenced tools:\n';
  for(const t of unreferencedTools) out += `- ${t}\n`;
  out += '\n';
}
if(duplicateIds.length){
  out += 'Duplicate IDs:\n';
  for(const d of duplicateIds) out += `- ${d.id} (${d.first} / ${d.second})\n`;
  out += '\n';
}
if(nullNameOrCategory.length){
  out += 'Null name/category:\n';
  for(const r of nullNameOrCategory.slice(0,40)) out += `- ${r.id} (${r.file}) name=${r.name} category=${r.category}\n`;
  out += '\n';
}
if(missingHandlers.length){
  out += 'Missing handlers:\n';
  for(const t of missingHandlers) out += `- ${t}\n`;
  out += '\n';
}

fs.writeFileSync(reportPath, out, 'utf8');
console.log(out);
process.exit(ok ? 0 : 1);
