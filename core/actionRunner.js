
'use strict';

/**
 * ActionRunner is a small wrapper around the existing PowerShell step runner.
 * It provides a stable API for the UI and JobManager.
 */
class ActionRunner {
  constructor({ runPsSteps }) {
    if (typeof runPsSteps !== 'function') throw new Error('ActionRunner requires runPsSteps');
    this.runPsSteps = runPsSteps;
  }

  async runSteps({ steps = [], meta = {} } = {}) {
    if (!Array.isArray(steps) || steps.length === 0) {
      return { ok: false, rawStdout: '', rawStderr: 'No steps.', logFile: null };
    }
    return await this.runPsSteps({ steps, meta });
  }

  async runTweak({ id, mode = 'apply', steps = [], meta = {}, revertSteps = [] } = {}) {
    if (!id) return { ok: false, rawStdout: '', rawStderr: 'Missing id.', logFile: null };
    if (!Array.isArray(steps) || steps.length === 0) {
      return { ok: false, rawStdout: '', rawStderr: 'No runnable steps.', logFile: null };
    }
    const res = await this.runPsSteps({ steps, meta });
    // Carry revertSteps back for UI/undo bookkeeping
    res._revertSteps = (mode === 'apply') ? revertSteps : undefined;
    return res;
  }
}

module.exports = { ActionRunner };
