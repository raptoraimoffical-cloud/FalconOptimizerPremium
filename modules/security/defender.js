// NOTE: Falcon uses tweak steps for execution. This module is used for health + future expansion.
const { getTamperState } = require("./healthCheck");

function canToggleDefender() {
  const tp = getTamperState();
  return { tamperProtection: tp, allowed: tp !== "ON" };
}

module.exports = { canToggleDefender };
