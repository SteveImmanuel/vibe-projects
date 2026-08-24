const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

class FakeEventEmitter {
  constructor() {
    this.listeners = new Set();
    this.event = (listener) => {
      this.listeners.add(listener);
      return { dispose: () => this.listeners.delete(listener) };
    };
  }
  fire(value) { for (const listener of this.listeners) listener(value); }
  dispose() { this.listeners.clear(); }
}

const fakeVscode = {
  EventEmitter: FakeEventEmitter,
  workspace: {
    onDidChangeWorkspaceFolders: () => ({ dispose() {} }),
  },
};

const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') return fakeVscode;
  return originalLoad.call(this, request, parent, isMain);
};
const { TrackingController } = require('../out/trackingController');
Module._load = originalLoad;

function eventSource() {
  const emitter = new FakeEventEmitter();
  return { event: emitter.event, emitter };
}

test('serializes an active resolution before Stop Tracking cleanup', async () => {
  const order = [];
  const changeEvent = eventSource();
  const stateEvent = eventSource();
  const filterEvent = eventSource();
  const reviewEvent = eventSource();
  let tracking = true;

  const baselines = {
    async deleteSessionStore() { order.push('delete-baselines'); },
  };
  const changes = {
    onDidChangeTrackedFiles: changeEvent.event,
    onDidChangeState: stateEvent.event,
    isTracking: () => tracking,
    isInitializing: () => false,
    stopTracking() { tracking = false; order.push('stop-watchers'); },
    getChanges: () => [],
  };
  const reviews = {
    onDidChangeReview: reviewEvent.event,
    async acceptHunk() {
      order.push('accept-start');
      await new Promise((resolve) => setTimeout(resolve, 20));
      order.push('accept-end');
      return true;
    },
    clearReview() { order.push('clear-review'); },
    getAllFileReviews: () => new Map(),
    getPendingHunks: () => [],
  };
  const filters = { onDidChange: filterEvent.event };
  const controller = new TrackingController(
    baselines,
    {},
    filters,
    changes,
    reviews
  );

  const acceptPromise = controller.acceptHunk('file:key', 'hunk');
  await Promise.resolve();
  const stopPromise = controller.stopTracking();
  await Promise.all([acceptPromise, stopPromise]);

  assert.deepEqual(order, [
    'accept-start',
    'stop-watchers',
    'accept-end',
    'clear-review',
    'delete-baselines',
  ]);
  controller.dispose();
});
