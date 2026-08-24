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
  excludePaths: [],
  pathOverrides: {},
};

const fakeVscode = {
  Uri: FakeUri,
  EventEmitter: FakeEventEmitter,
  ConfigurationTarget: { Workspace: 2, Global: 1 },
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
      inspect: () => undefined,
      update: async () => {},
    }),
    onDidChangeConfiguration: () => ({ dispose() {} }),
  },
};

const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') return fakeVscode;
  return originalLoad.call(this, request, parent, isMain);
};
const { FilterService, isPathIncluded, normalizeFilterPath } = require('../out/filterService');
Module._load = originalLoad;

test('path overrides take precedence over include and exclude globs', () => {
  assert.equal(isPathIncluded('src/app.ts', ['**/*'], [], { src: false }), false);
  assert.equal(
    isPathIncluded('generated/app.ts', ['**/*'], ['generated/**'], { generated: true }),
    true
  );
});

test('the nearest path override wins', () => {
  const overrides = {
    src: false,
    'src/selected': true,
    'src/selected/private': false,
  };

  assert.equal(isPathIncluded('src/other.ts', ['**/*'], [], overrides), false);
  assert.equal(isPathIncluded('src/selected/app.ts', ['**/*'], [], overrides), true);
  assert.equal(
    isPathIncluded('src/selected/private/secret.ts', ['**/*'], [], overrides),
    false
  );
});

test('paths are normalized for portable tree selections', () => {
  assert.equal(normalizeFilterPath('.\\src\\app.ts'), 'src/app.ts');
  assert.equal(normalizeFilterPath('./src/app.ts'), 'src/app.ts');
});

test('visual overrides are scoped to one workspace root', async () => {
  const service = new FilterService(new FakeMemento());
  await service.initialize();
  await service.updateOverrides([{
    uri: FakeUri.file('/one/src'),
    included: false,
    recursive: true,
  }]);

  assert.equal(service.isIncluded(FakeUri.file('/one/src/app.ts')), false);
  assert.equal(service.isIncluded(FakeUri.file('/two/src/app.ts')), true);

  await service.updateOverrides([{
    uri: FakeUri.file('/one/src/selected'),
    included: true,
    recursive: true,
  }]);
  assert.equal(service.isIncluded(FakeUri.file('/one/src/selected/app.ts')), true);
  assert.equal(service.isIncluded(FakeUri.file('/one/src/other.ts')), false);
  service.dispose();
});
