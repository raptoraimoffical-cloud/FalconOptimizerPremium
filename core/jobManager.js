
'use strict';

const fs = require('fs');
const path = require('path');

function nowIso() { return new Date().toISOString(); }

function safeReadJson(filePath, fallback) {
  try {
    if (filePath && fs.existsSync(filePath)) {
      const t = fs.readFileSync(filePath, 'utf8').trim();
      return t ? JSON.parse(t) : fallback;
    }
  } catch (_) {}
  return fallback;
}

function safeWriteJson(filePath, obj) {
  try {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, JSON.stringify(obj, null, 2), 'utf8');
    return true;
  } catch (_) {
    return false;
  }
}

class JobManager {
  constructor({ historyFilePath, maxSessions = 50, maxEntriesPerSession = 250 } = {}) {
    this.historyFilePath = historyFilePath;
    this.maxSessions = maxSessions;
    this.maxEntriesPerSession = maxEntriesPerSession;

    this.historyState = safeReadJson(historyFilePath, { version: 1, sessions: [] });
    if (!this.historyState || typeof this.historyState !== 'object') this.historyState = { version: 1, sessions: [] };
    if (!Array.isArray(this.historyState.sessions)) this.historyState.sessions = [];

    this.currentSessionId = null;
    this._queue = Promise.resolve();
    this._activeJobs = 0;
  }

  _ensureSession() {
    const today = nowIso().slice(0, 10);
    let s = this.historyState.sessions.find(x => x && x.id === this.currentSessionId);
    if (!s || !Array.isArray(s.entries) || (s.date && s.date !== today)) {
      this.currentSessionId = `${today}-${Date.now()}`;
      s = { id: this.currentSessionId, date: today, entries: [] };
      this.historyState.sessions.unshift(s);
      this.historyState.sessions = this.historyState.sessions.slice(0, this.maxSessions);
    }
    return s;
  }

  _pushEntry(entry) {
    const s = this._ensureSession();
    s.entries.unshift(entry);
    s.entries = s.entries.slice(0, this.maxEntriesPerSession);
    safeWriteJson(this.historyFilePath, this.historyState);
  }

  getHistory() { return this.historyState; }
  isBusy() { return this._activeJobs > 0; }

  /**
   * Enqueue a job to avoid overlapping runs.
   * runnerFn should return { ok, rawStdout, rawStderr, logFile }.
   */
  enqueue({ id, mode = 'apply', stepsCount = 0, meta = {}, entryExtra = {} }, runnerFn) {
    const startTs = Date.now();
    const entryBase = {
      ts: nowIso(),
      id: String(id || ''),
      mode: String(mode || 'apply'),
      ok: false,
      durationMs: null,
      logFile: null,
      meta: (meta && typeof meta === 'object') ? meta : {},
      ...(entryExtra && typeof entryExtra === 'object' ? entryExtra : {}),
      stepsCount: stepsCount
    };

    // Do not emit a separate STARTED entry.
    // It created confusing duplicate FAIL entries in the UI.

    const run = async () => {
      this._activeJobs += 1;
      try {
        const res = await runnerFn();
        const durationMs = Date.now() - startTs;
        const entry = {
          ...entryBase,
          ok: !!(res && res.ok),
          durationMs,
          logFile: (res && res.logFile) ? res.logFile : null,
          stderr: (res && res.rawStderr) ? String(res.rawStderr).slice(0, 4000) : '',
          stdout: (res && res.rawStdout) ? String(res.rawStdout).slice(0, 4000) : ''
        };
        this._pushEntry(entry);
        return res;
      } catch (e) {
        const durationMs = Date.now() - startTs;
        const entry = { ...entryBase, ok: false, durationMs, error: String(e && e.message ? e.message : e) };
        this._pushEntry(entry);
        return { ok: false, rawStdout: '', rawStderr: entry.error, logFile: null };
      } finally {
        this._activeJobs -= 1;
      }
    };

    // Serialize to avoid overlapping and to keep state consistent.
    this._queue = this._queue.then(run, run);
    return this._queue;
  }
}

module.exports = { JobManager };
