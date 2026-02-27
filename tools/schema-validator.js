#!/usr/bin/env node
/* Falcon Optimizer schema validator + migrator (v2) */
const fs = require("fs");
const path = require("path");

const VALID_RISKS = ["Safe","Warning","High","Critical"];
const VALID_STEP_TYPES = new Set([
  "cmd","cmd.run","ps.run",
  "registry.set","registry.remove",
  "service.disable","service.enable","service.startup",
  "process.kill","process.start","shell.start",
  "task","timer.set","timer.reset","powercfg.set",
  "open.url","open.file","open.path",
  "run.exe","file.copy","file.write"
]);

function isObj(v){ return v && typeof v === "object" && !Array.isArray(v); }

function inferRequiresAdmin(item){
  try{
    const steps = []
      .concat((item.apply && Array.isArray(item.apply.steps)) ? item.apply.steps : [])
      .concat((item.revert && Array.isArray(item.revert.steps)) ? item.revert.steps : []);
    for(const s of steps){
      if(!isObj(s)) continue;
      const t = s.type;
      if(["service.disable","service.enable","service.startup","task","powercfg.set","timer.set","timer.reset"].includes(t)) return true;
      if(t==="registry.set" || t==="registry.remove"){
        const p = String(s.path||"").toUpperCase();
        if(p.startsWith("HKLM") || p.startsWith("HKCR") || p.startsWith("HKU") || p.startsWith("HKCC")) return true;
      }
      if(t==="cmd" || t==="cmd.run" || t==="ps.run" || t==="run.exe") return true; // conservative
    }
  }catch(_){}
  return false;
}

function defaultCategoryForFile(file){
  const f = String(file||"").toLowerCase();
  if(f.startsWith("windows.core")) return "General / Core";
  if(f.startsWith("windows.privacy")) return "General / Privacy";
  if(f.startsWith("windows.qol")) return "General / QOL";
  if(f.startsWith("windows.power")) return "General / Power";
  if(f.startsWith("hardware.gpu")) return "Hardware / GPU";
  if(f.startsWith("hardware.cpu")) return "Hardware / CPU";
  if(f.startsWith("hardware.memory")) return "Hardware / Memory";
  if(f.startsWith("hardware.peripherals")) return "Hardware / Peripherals";
  if(f.startsWith("hardware.storage")) return "Hardware / Storage";
  if(f.startsWith("network.")) return "Network";
  if(f.startsWith("debloat.")) return "Debloat";
  if(f.startsWith("advanced.")) return "Advanced";
  if(f.startsWith("fortnite.")) return "Fortnite";
  if(f.startsWith("gamemode.")) return "Game Mode";
  if(f==="utilities.json" || f.endsWith(".utilities.json")) return "Utilities";
  if(f.startsWith("expansion.")) return "Expansion";
  return "Misc";
}

function migrateStep(step, warnings){
  if(!isObj(step)) return step;

  // ps.run: script -> command
  if(step.type === "ps.run" && step.script && !step.command){
    step.command = step.script;
    delete step.script;
    warnings.push({code:"MIGRATE_PS_SCRIPT", msg:"ps.run: migrated script->command"});
  }

  // cmd.run: script -> command (legacy)
  if((step.type === "cmd" || step.type==="cmd.run") && step.script && !step.command){
    step.command = step.script;
    delete step.script;
    warnings.push({code:"MIGRATE_CMD_SCRIPT", msg:"cmd: migrated script->command"});
  }

  // service.startup: startup -> startType
  if(step.type === "service.startup" && step.startup && !step.startType){
    step.startType = step.startup;
    delete step.startup;
    warnings.push({code:"MIGRATE_SERVICE_STARTUP", msg:"service.startup: migrated startup->startType"});
  }

  // process.start: command/args -> filePath/arguments
  if(step.type === "process.start"){
    if(step.command && !step.filePath){
      step.filePath = step.command;
      delete step.command;
      warnings.push({code:"MIGRATE_PROCSTART_COMMAND", msg:"process.start: migrated command->filePath"});
    }
    if(step.args !== undefined && step.arguments === undefined){
      step.arguments = Array.isArray(step.args) ? step.args.join(" ") : String(step.args);
      delete step.args;
      warnings.push({code:"MIGRATE_PROCSTART_ARGS", msg:"process.start: migrated args->arguments"});
    }
    if(step.arguments === undefined) step.arguments = "";
  }

  // process.kill: strip .exe (Get-Process -Name expects without suffix)
  if(step.type === "process.kill" && typeof step.name === "string" && step.name.toLowerCase().endsWith(".exe")){
    const before = step.name;
    step.name = step.name.replace(/\.exe$/i,"");
    warnings.push({code:"MIGRATE_PROCKILL_EXE", msg:`process.kill: migrated ${before} -> ${step.name}`});
  }

    // task: normalize action case
  if(step.type === "task" && typeof step.action === "string"){
    step.action = step.action.toLowerCase();
  }

  return step;
}

function validateStep(step, errors, warnings, where){
  if(!isObj(step)){
    errors.push({where, msg:"Step must be an object"}); return;
  }
  if(!VALID_STEP_TYPES.has(step.type)){
    errors.push({where, msg:`Invalid step type: ${step.type}`}); return;
  }
  const t = step.type;
  const require = (k)=>{ if(step[k]===undefined || step[k]===null || (step[k]==="" && !((t==="registry.set"||t==="registry.remove") && k==="name"))) errors.push({where, msg:`${t} requires '${k}'`}); };
  const looksLikeFolder = (p)=> typeof p === 'string' && ((/^[A-Za-z]:\\/.test(p) || /^\\\\/.test(p)) && p.endsWith('\\'));
  if(t==="ps.run"||t==="cmd"||t==="cmd.run") require("command");
  if(t==="process.start"){ require("filePath"); if(step.arguments===undefined) errors.push({where, msg:"process.start requires 'arguments' (string, allow empty)"}); }
  if(t==="process.kill") require("name");
  if(t==="service.startup"){ require("name"); require("startType"); }
  if(t==="shell.start"){ require("file"); if(!Array.isArray(step.args)) errors.push({where, msg:"shell.start requires 'args' array"}); }
  if(t==="registry.set"){ require("path"); require("name"); if(step.value===undefined) errors.push({where, msg:"registry.set requires 'value'"}); }
  if(t==="registry.remove"){ require("path"); require("name"); }
  if(t==="task"){ require("name"); require("action"); if(!["enable","disable"].includes(String(step.action))) errors.push({where,msg:"task.action must be enable|disable"}); }
  // Warnings to prevent accidental Explorer launches
  if((t==="process.start" || t==="run.exe") && looksLikeFolder(step.filePath) && !step.allowExplorer){
    warnings.push({where, msg:"Folder-like filePath would open File Explorer. Use open.path/open.file or set allowExplorer:true."});
  }
  if(t==="shell.start" && looksLikeFolder(step.file) && !step.allowExplorer){
    warnings.push({where, msg:"Folder-like shell.start file would open File Explorer. Use open.path/open.file or set allowExplorer:true."});
  }
}

function ensureFields(item, file, warnings){
  if(!item.category){
    item.category = defaultCategoryForFile(file);
    warnings.push({code:"MIGRATE_CATEGORY", msg:`Added default category '${item.category}'`});
  }
  if(!item.type){
    item.type = "toggle";
    warnings.push({code:"MIGRATE_TYPE", msg:"Added default type 'toggle'"});
  }
  if(item.requiresAdmin === undefined){
    item.requiresAdmin = inferRequiresAdmin(item);
    warnings.push({code:"MIGRATE_REQUIRESADMIN", msg:`Inferred requiresAdmin=${item.requiresAdmin}`});
  }
  if(!item.apply) item.apply = { steps: [] };
  if(!Array.isArray(item.apply.steps)) item.apply.steps = [];
  if(!item.revert) item.revert = { steps: [] };
  if(!Array.isArray(item.revert.steps)) item.revert.steps = [];
  if(!item.description){
    item.description = "";
  }
  if(!item.riskLevel && item.risk) item.riskLevel = item.risk;
  if(!item.riskLevel) item.riskLevel = "Safe";
  if(!VALID_RISKS.includes(item.riskLevel)){
    warnings.push({code:"MIGRATE_RISKLEVEL", msg:`Invalid riskLevel '${item.riskLevel}', defaulting to Safe`});
    item.riskLevel="Safe";
  }
}

function validateItem(item, errors, warnings, where, file){
  if(!isObj(item)){
    errors.push({where, msg:"Item must be an object"}); return;
  }
  if(!item.id) errors.push({where, msg:"Item missing 'id'"});
  if(!item.name) errors.push({where, msg:"Item missing 'name'"});

  ensureFields(item, file, warnings);

  // migrate + validate steps
  ["apply","revert"].forEach(mode=>{
    const arr = item[mode] && Array.isArray(item[mode].steps) ? item[mode].steps : [];
    for(let i=0;i<arr.length;i++){
      arr[i] = migrateStep(arr[i], warnings);
      validateStep(arr[i], errors, warnings, `${where}.${mode}.steps[${i}]`);
    }
  });
}

function main(){
  const args = process.argv.slice(2);
  const fix = args.includes("--fix");
  const root = process.cwd();
  const tweaksDir = path.join(root, "tweaks");
  const outPath = path.join(root, "schema-report.json");

  const report = {
    version: 2,
    generatedAt: new Date().toISOString(),
    ok: true,
    files: [],
    errors: [],
    warnings: []
  };

  const files = fs.readdirSync(tweaksDir).filter(f=>f.endsWith(".json") && f!=="profiles.json");
  const idSet = new Set();

  for(const f of files){
    const full = path.join(tweaksDir, f);
    let data;
    try { data = JSON.parse(fs.readFileSync(full,"utf8")); }
    catch(e){
      report.ok=false;
      report.errors.push({where:`${f}`, msg:`Invalid JSON: ${e.message}`});
      continue;
    }
    const items = Array.isArray(data.items) ? data.items : [];
    const fileErrors = [];
    const fileWarnings = [];

    for(let i=0;i<items.length;i++){
      const item = items[i];
      const where = `${f}.items[${i}](${item && item.id ? item.id : "no-id"})`;

      if(item && item.id){
        if(idSet.has(item.id)){
          report.ok=false;
          report.errors.push({where, msg:`Duplicate id detected: ${item.id}`});
        } else idSet.add(item.id);
      }

      validateItem(item, fileErrors, fileWarnings, where, f);
    }

    if(fileErrors.length) report.ok=false;
    report.errors.push(...fileErrors);
    report.warnings.push(...fileWarnings);
    report.files.push({file:f, itemCount: items.length});

    if(fix){
      try{
        fs.writeFileSync(full, JSON.stringify(data,null,2), "utf8");
      }catch(e){
        report.ok=false;
        report.errors.push({where:f, msg:`Failed to write --fix: ${e.message}`});
      }
    }
  }

  fs.writeFileSync(outPath, JSON.stringify(report,null,2), "utf8");
  console.log(JSON.stringify({ ok: report.ok, errors: report.errors.length, warnings: report.warnings.length, report: "schema-report.json" }));
}

main();
