'use strict';
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const PS = 'powershell.exe';
const BASE_ARGS = ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass'];

function run(cmd, args, { timeoutMs = 120000, cwd } = {}) {
  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';
    let done = false;
    const p = spawn(cmd, args, { windowsHide: true, cwd });
    const finish = (code, timedOut) => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      resolve({ code, stdout, stderr: timedOut ? `${stderr}\nTimed out after ${timeoutMs} ms` : stderr, timedOut: !!timedOut });
    };
    const timer = setTimeout(() => { try { p.kill(); } catch (_) {} finish(-1, true); }, timeoutMs);
    p.stdout.on('data', (d) => { stdout += d.toString(); });
    p.stderr.on('data', (d) => { stderr += d.toString(); });
    p.on('error', (e) => { stderr += String(e && e.message ? e.message : e); finish(-1, false); });
    p.on('close', (code) => finish(typeof code === 'number' ? code : -1, false));
  });
}

const runPowerShellFile = (file, args = [], opts = {}) => run(PS, [...BASE_ARGS, '-File', file, ...args], opts);
const runPowerShellCommand = (command, opts = {}) => run(PS, [...BASE_ARGS, '-Command', command], opts);

let elevatedCache = null;
async function isElevated() {
  if (elevatedCache !== null) return elevatedCache;
  const r = await runPowerShellCommand('([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)', { timeoutMs: 15000 });
  elevatedCache = /true/i.test(r.stdout);
  return elevatedCache;
}

const psQuote = (s) => `'${String(s).replace(/'/g, "''")}'`;

/**
 * Runs scripts/engine.ps1 with a request object. Detect runs as the current user; apply/revert
 * (and cleaner 'clean') are elevated through a single UAC prompt per call when the app itself is not elevated.
 */
async function runEngine(appRoot, request, { timeoutMs = 10 * 60 * 1000, script = 'engine.ps1' } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'falcon-'));
  const reqFile = path.join(dir, 'request.json');
  const resFile = path.join(dir, 'result.json');
  const engine = path.join(appRoot, 'scripts', script);
  fs.writeFileSync(reqFile, JSON.stringify(request), 'utf8');

  try {
    const needsAdmin = request.mode !== 'detect' && request.mode !== 'scan';
    let r;
    if (needsAdmin && !(await isElevated())) {
      const argList = [...BASE_ARGS, '-File', engine, '-RequestFile', reqFile, '-ResultFile', resFile].map((a) => `"${a}"`).join(' ');
      const cmd = `try { $p = Start-Process -FilePath ${PS} -ArgumentList ${psQuote(argList)} -Verb RunAs -WindowStyle Hidden -Wait -PassThru; exit $p.ExitCode } catch { Write-Error $_.Exception.Message; exit 1223 }`;
      r = await runPowerShellCommand(cmd, { timeoutMs });
      if (r.code === 1223 && !fs.existsSync(resFile)) {
        return { ok: false, cancelled: true, items: [], error: 'Administrator approval was declined.' };
      }
    } else {
      r = await runPowerShellFile(engine, ['-RequestFile', reqFile, '-ResultFile', resFile], { timeoutMs });
    }
    if (!fs.existsSync(resFile)) {
      return { ok: false, items: [], error: (r.stderr || r.stdout || 'Engine produced no result').trim().slice(0, 2000) };
    }
    const txt = fs.readFileSync(resFile, 'utf8').replace(/^﻿/, '');
    const out = JSON.parse(txt);
    out.items = Array.isArray(out.items) ? out.items : (out.items ? [out.items] : []);
    for (const it of out.items) it.messages = Array.isArray(it.messages) ? it.messages : (it.messages ? [it.messages] : []);
    return out;
  } catch (e) {
    return { ok: false, items: [], error: String(e && e.message ? e.message : e) };
  } finally {
    try { fs.rmSync(dir, { recursive: true, force: true }); } catch (_) {}
  }
}

module.exports = { run, runPowerShellFile, runPowerShellCommand, runEngine, isElevated, psQuote };
