
'use strict';

class StateStore {
  constructor(initial = {}) {
    this._state = { ...initial };
    this._subs = new Set();
  }
  get() { return this._state; }
  set(patch = {}) {
    const next = { ...this._state, ...patch };
    this._state = next;
    for (const fn of this._subs) {
      try { fn(next); } catch (_) {}
    }
    return next;
  }
  subscribe(fn) {
    this._subs.add(fn);
    return () => this._subs.delete(fn);
  }
}

module.exports = { StateStore };
