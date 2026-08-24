const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path').posix;
const Module = require('node:module');

class FakeUri {
  constructor(fsPath) {
    this.fsPath = path.normalize(fsPath);
    this.path = this.fsPath;
    this.scheme = 'file';
    this.authority = '';
  }
  static file(fsPath) { return new FakeUri(fsPath); }
  static parse(value) { return new FakeUri(value.replace(/^file:/, '')); }
  static joinPath(base, ...segments) { return new FakeUri(path.join(base.fsPath, ...segments)); }
  toString() { return `file:${this.fsPath}`; }
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

class FakeMemento {
  constructor() { this.values = new Map(); }
  get(key) { return this.values.get(key); }
  async update(key, value) { this.values.set(key, value); }
  keys() { return [...this.values.keys()]; }
}

const roots = [
  { name: 'one', uri: FakeUri.file('/one') },
  { name: 'two', uri: FakeUri.file('/two') },
];
const configuration = {
  includePaths: ['**/*'],
  excludePaths: ['**/generated/**'],
};

const fakeVscode = {
  Uri: FakeUri,
  EventEmitter: FakeEventEmitter,
  workspace: {
    workspaceFolders: roots,
    getWorkspaceFolder(uri) {
      return roots.find((root) => uri.fsPath === root.uri.fsPath
        || uri.fsPath.startsWith(`${root.uri.fsPath}/`));
    },
    asRelativePath(uri) {
      const root = this.getWorkspaceFolder(uri);
      return root ? path.relative(root.uri.fsPath, uri.fsPath) : uri.fsPath;
    },
    getConfiguration: () => ({
      get: (key, fallback) => configuration[key] ?? fallback,
    }),
    onDidChangeConfiguration: () => ({ dispose() {} }),
  },
};

const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') return fakeVscode;
  return originalLoad.call(this, request, parent, isMain);
};
const { FilterService } = require('../out/filterService');
Module._load = originalLoad;

test('visual overrides beat glob filters and are scoped to one workspace root', async () => {
  const service = new FilterService(new FakeMemento());

  // Exclude globs apply until an override re-includes the path.
  assert.equal(service.isIncluded(FakeUri.file('/one/generated/app.ts')), false);
  await service.updateOverrides([{
    uri: FakeUri.file('/one/generated'),
    included: true,
    recursive: true,
  }]);
  assert.equal(service.isIncluded(FakeUri.file('/one/generated/app.ts')), true);
  assert.equal(service.isIncluded(FakeUri.file('/two/generated/app.ts')), false);

  // The nearest override wins, and selections leave the other root alone.
  await service.updateOverrides([
    { uri: FakeUri.file('/one/src'), included: false, recursive: true },
    { uri: FakeUri.file('/one/src/selected'), included: true, recursive: true },
  ]);
  assert.equal(service.isIncluded(FakeUri.file('/one/src/other.ts')), false);
  assert.equal(service.isIncluded(FakeUri.file('/one/src/selected/app.ts')), true);
  assert.equal(service.isIncluded(FakeUri.file('/two/src/app.ts')), true);
  service.dispose();
});

test('overrides persist through workspace state', async () => {
  const memento = new FakeMemento();
  const first = new FilterService(memento);
  await first.updateOverrides([{
    uri: FakeUri.file('/one/src'),
    included: false,
    recursive: true,
  }]);
  first.dispose();

  const second = new FilterService(memento);
  assert.equal(second.isIncluded(FakeUri.file('/one/src/app.ts')), false);
  assert.equal(second.isIncluded(FakeUri.file('/one/lib/app.ts')), true);
  second.dispose();
});
