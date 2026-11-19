'use strict';
const { contextBridge, ipcRenderer } = require('electron');

const call = (channel) => (...args) => ipcRenderer.invoke(channel, ...args);

contextBridge.exposeInMainWorld('falcon', {
  info: call('app:info'),
  relaunchAsAdmin: call('app:relaunchAsAdmin'),
  restartPc: call('system:restart'),

  getSettings: call('settings:get'),
  setSettings: call('settings:set'),

  getProfile: call('system:profile'),
  getCatalog: call('catalog:get'),
  detect: call('catalog:detect'),
  execute: call('engine:execute'),

  planOptimize: call('optimize:plan'),
  runOptimize: call('optimize:run'),
  undoAll: call('undo:all'),

  getHistory: call('history:get'),
  clearHistory: call('history:clear'),

  listGames: call('games:list'),
  addCustomGame: call('games:addCustom'),
  removeCustomGame: call('games:removeCustom'),

  listCleaner: call('cleaner:list'),
  runCleaner: call('cleaner:run'),

  timerStatus: call('timer:status'),
  listTools: call('tools:list'),
  openToolFolder: call('tools:openFolder'),
  importNvidiaProfile: call('tools:importNvidiaProfile'),

  openExternal: call('shell:openExternal'),
  openLogs: call('shell:openLogs'),

  checkForUpdates: call('falcon:checkForUpdates'),
  updaterStatus: call('updater:getStatus'),
  onUpdateStatus: (cb) => {
    if (typeof cb !== 'function') return () => {};
    const listener = (_e, payload) => { try { cb(payload || {}); } catch (_) {} };
    ipcRenderer.on('falcon:update-status', listener);
    return () => ipcRenderer.removeListener('falcon:update-status', listener);
  }
});
