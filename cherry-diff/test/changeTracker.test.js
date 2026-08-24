const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

class FakeUri {
  constructor(value) {
    const match = /^([^:]+):\/\/(.*?)((?:\/.*)?)$/.exec(value);
    this.scheme = match?.[1] ?? 'file';
    this.authority = match?.[2] ?? '';
    this.path = match?.[3] || value;
    this.fsPath = this.path;
    this.value = value;
  }
  static parse(value) { return new FakeUri(value); }
  toString() { return this.value; }
}

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

function disposable() { return { dispose() {} }; }

const fakeVscode = {
  Uri: FakeUri,
  EventEmitter: FakeEventEmitter,
  workspace: {
    getWorkspaceFolder: () => ({ name: 'root' }),
    onDidChangeTextDocument: () => disposable(),
    createFileSystemWatcher: () => ({
      onDidChange: () => disposable(),
      onDidCreate: () => disposable(),
      onDidDelete: () => disposable(),
      dispose() {},
    }),
  },
};

const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') return fakeVscode;
  return originalLoad.call(this, request, parent, isMain);
};
const { ChangeTracker } = require('../out/changeTracker');
Module._load = originalLoad;

const filters = { isIncluded: () => true };

test('uses revisions so an older review cannot acknowledge a newer edit', () => {
  const tracker = new ChangeTracker(filters);
  const uri = FakeUri.parse('vscode-remote://host/workspace/file.txt');
  tracker.beginInitialization();
  tracker.markChange(uri, 'changed');
  assert.equal(tracker.takeInitializationChanges().length, 1);
  tracker.finishInitialization();

  const first = tracker.markChange(uri, 'changed');
  const second = tracker.markChange(uri, 'changed');
  assert.equal(tracker.acknowledge(first.key, first.revision), false);
  assert.equal(tracker.getChange(uri.toString()).revision, second.revision);
  assert.equal(tracker.acknowledge(second.key, second.revision), true);
  assert.equal(tracker.getChanges().length, 0);
  tracker.dispose();
});

test('clears dirty resources when tracking stops', () => {
  const tracker = new ChangeTracker(filters);
  tracker.beginInitialization();
  tracker.finishInitialization();
  tracker.markChange(FakeUri.parse('file:///workspace/a.txt'));
  assert.equal(tracker.getChanges().length, 1);

  tracker.stopTracking();
  assert.equal(tracker.getChanges().length, 0);
  assert.equal(tracker.isTracking(), false);
  tracker.dispose();
});

