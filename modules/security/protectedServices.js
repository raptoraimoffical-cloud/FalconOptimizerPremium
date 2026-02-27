const PROTECTED_SERVICES = [
  "msiserver",
  "TrustedInstaller",
  "EventLog",
  "RpcSs",
  "DcomLaunch",
  "SecurityHealthService"
];

function isProtected(serviceName) {
  if (!serviceName) return false;
  const n = String(serviceName).trim();
  return PROTECTED_SERVICES.some(s => s.toLowerCase() === n.toLowerCase());
}

module.exports = { PROTECTED_SERVICES, isProtected };
