const { execSync } = require("child_process");

function safeExec(cmd) {
  try {
    return execSync(cmd, { stdio: ["ignore", "pipe", "pipe"], windowsHide: true }).toString("utf8");
  } catch (e) {
    const out = (e && e.stdout) ? e.stdout.toString("utf8") : "";
    const err = (e && e.stderr) ? e.stderr.toString("utf8") : "";
    return out + "\n" + err;
  }
}

function parseStartType(scQcOutput) {
  const m = scQcOutput.match(/START_TYPE\s*:\s*\d+\s+(\w+)/i);
  if (!m) return "UNKNOWN";
  const v = m[1].toUpperCase();
  if (v.includes("AUTO")) return "AUTO";
  if (v.includes("DEMAND")) return "DEMAND";
  if (v.includes("DISABLED")) return "DISABLED";
  return v;
}

function parseRunState(scQueryOutput) {
  const m = scQueryOutput.match(/STATE\s*:\s*\d+\s+(\w+)/i);
  if (!m) return "UNKNOWN";
  return m[1].toUpperCase();
}

function getServiceStatus(name) {
  const qc = safeExec(`sc qc "${name}"`);
  const q = safeExec(`sc query "${name}"`);
  const startType = parseStartType(qc);
  const state = parseRunState(q);
  return { name, startType, state };
}

function getTamperState() {
  const out = safeExec(`reg query "HKLM\\SOFTWARE\\Microsoft\\Windows Defender\\Features" /v TamperProtection`);
  // value 0x5 commonly indicates ON
  if (/0x5\b/i.test(out)) return "ON";
  if (/0x0\b/i.test(out) || /0x4\b/i.test(out) || /0x1\b/i.test(out)) return "OFF";
  return "UNKNOWN";
}

function healthCheck() {
  const services = [
    "WinDefend",
    "WdNisSvc",
    "SecurityHealthService",
    "wscsvc",
    "msiserver"
  ].map(getServiceStatus);

  return {
    ok: true,
    tamperProtection: getTamperState(),
    services
  };
}

module.exports = { healthCheck, getServiceStatus, getTamperState };
