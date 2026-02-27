const { contextBridge, ipcRenderer } = require("electron");

function pickStepsFromPayload(payload){
  if (!payload) return [];
  if (Array.isArray(payload.steps)) return payload.steps;

  // Legacy: { action:'apply'|'revert', tweak:{apply:{steps}, revert:{steps}} }
  if (payload.tweak) {
    const action = String(payload.action || "apply").toLowerCase();
    if (action === "revert") return (payload.tweak.revert && Array.isArray(payload.tweak.revert.steps)) ? payload.tweak.revert.steps : [];
    return (payload.tweak.apply && Array.isArray(payload.tweak.apply.steps)) ? payload.tweak.apply.steps : [];
  }
  return [];
}

contextBridge.exposeInMainWorld("falcon", {
  // Execute raw steps

  runSteps: (payload) => {
    const steps = pickStepsFromPayload(payload);
    const meta = payload && payload.meta ? payload.meta : {};
    return ipcRenderer.invoke("falcon:runSteps", { steps, meta });
  },

  // Compatibility wrapper used by renderer
  runAction: (payload) => {
    const steps = pickStepsFromPayload(payload);
    return ipcRenderer.invoke("falcon:runSteps", { steps });
  },

  // New safety-aware runner (recommended)
  runTweak: (payload) => ipcRenderer.invoke("falcon:runTweak", payload),

  // Tests / validation
    performanceLibraryApply: (args) => ipcRenderer.invoke("falcon:performanceLibraryApply", args),
selfTest: () => ipcRenderer.invoke("falcon:selfTest"),
  validateTweaks: () => ipcRenderer.invoke("falcon:validateTweaks"),
  dryRunSteps: (steps) => ipcRenderer.invoke("falcon:dryRunSteps", { steps }),

  // backups
  createBackup: () => ipcRenderer.invoke("falcon:createBackup"),
  restoreBackup: () => ipcRenderer.invoke("falcon:restoreBackup"),

  // state
  setState: (id, on) => ipcRenderer.invoke("falcon:setState", { id, on }),
  getState: () => ipcRenderer.invoke("falcon:getState"),

  // system info
  getSystemInfo: () => ipcRenderer.invoke("falcon:getSystemInfo"),
  getThermals: () => ipcRenderer.invoke("falcon:getThermals"),
  getBiosInfo: () => ipcRenderer.invoke("falcon:getBiosInfo"),
  saveTextFile: (name, text) => ipcRenderer.invoke("falcon:saveTextFile", { name, text }),

  // timer resolution
  timerStatus: () => ipcRenderer.invoke("falcon:timerStatus"),
  timerStart: (resolution) => ipcRenderer.invoke("falcon:timerStart", { resolution }),
  timerStop: () => ipcRenderer.invoke("falcon:timerStop"),
  timerInstallStartup: (resolution) => ipcRenderer.invoke("falcon:timerInstallStartup", { resolution }),
  timerRemoveStartup: () => ipcRenderer.invoke("falcon:timerRemoveStartup"),

  // latency overrides
  getLatencyOverrides: () => ipcRenderer.invoke("falcon:getLatencyOverrides"),
  setLatencyOverrides: (overrides) => ipcRenderer.invoke("falcon:setLatencyOverrides", overrides),

  // history
  getHistory: () => ipcRenderer.invoke("falcon:getHistory"),
  undoLastSession: () => ipcRenderer.invoke("falcon:undoLastSession"),
  undoAll: () => ipcRenderer.invoke("falcon:undoAll"),

  // process / system helpers
  listProcesses: () => ipcRenderer.invoke("falcon:listProcesses"),
  terminateProcesses: (processes) => ipcRenderer.invoke("falcon:terminateProcesses", { processes: processes || [] }),
  runProcessPreset: (mode) => ipcRenderer.invoke("falcon:runProcessPreset", { mode }),
  restoreProcessLab: () => ipcRenderer.invoke("falcon:restoreProcessLab"),
  runProcessCustomPreset: (baseMode, overrides) => ipcRenderer.invoke("falcon:runProcessCustomPreset", { baseMode, overrides }),


  // utils
  openExternal: (url) => ipcRenderer.invoke("falcon:openExternal", { url }),
  openPath: (p) => ipcRenderer.invoke("falcon:openPath", { path: p }),

  detectXmpStatus: () => ipcRenderer.invoke("falcon:detectXmpStatus"),
  getRebarStatus: () => ipcRenderer.invoke("falcon:getRebarStatus")

,
// game scan + per-game QoS (Network Priority)
scanInstalledGames: () => ipcRenderer.invoke("falcon:scanInstalledGames"),
runGamePack: (gameId, action) => ipcRenderer.invoke("falcon:runGamePack", { gameId, action }),

// power plans
applyPowerPlan: (mode) => ipcRenderer.invoke("falcon:applyPowerPlan", { mode }),
removePowerPlans: () => ipcRenderer.invoke("falcon:removePowerPlans"),

  // power plans v2
  powerPlansInstallAll: () => ipcRenderer.invoke("falcon:powerPlansInstallAll"),
  powerPlansApply: (plan) => ipcRenderer.invoke("falcon:powerPlansApply", { plan }),
  powerPlansApplyWindows: (which) => ipcRenderer.invoke("falcon:powerPlansApplyWindows", { which }),
  powerPlansRestorePrevious: () => ipcRenderer.invoke("falcon:powerPlansRestorePrevious"),

  getSystemVitals: () => ipcRenderer.invoke("falcon:getSystemVitals"),
  runLatencyBenchmark: (seconds=5) => ipcRenderer.invoke("falcon:runLatencyBenchmark", { seconds }),

  getAutoSwitchPowerPlan: () => ipcRenderer.invoke("falcon:getAutoSwitchPowerPlan"),
  setAutoSwitchPowerPlan: (state) => ipcRenderer.invoke("falcon:setAutoSwitchPowerPlan", state),
  // local asset readers (renderer-safe way to load tweaks/*.json under file://)
  readText: async (relPath) => { const r = await ipcRenderer.invoke("falcon:readText", { path: relPath }); if(!r||!r.ok) throw new Error((r&&r.error)||"readText failed"); return r.text; },
  readJson: async (relPath) => { const r = await ipcRenderer.invoke("falcon:readJson", { path: relPath }); if(!r||!r.ok) throw new Error((r&&r.error)||"readJson failed"); return r.json; },

  securityHealthCheck: () => ipcRenderer.invoke("falcon:securityHealthCheck"),
  // Tool manager
  toolStatus: (payload) => ipcRenderer.invoke("falcon:toolStatus", payload),
  toolEnsure: (payload) => ipcRenderer.invoke("falcon:toolEnsure", payload),
  toolLaunch: (payload) => ipcRenderer.invoke("falcon:toolLaunch", payload)

});