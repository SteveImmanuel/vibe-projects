const path = require('node:path').posix;
const Module = require('node:module');
const { minimatch } = require('minimatch');

class Uri {
  constructor(value) {
    const parsed = new URL(value);
    this.scheme = parsed.protocol.slice(0, -1);
    this.authority = parsed.host;
    this.path = parsed.pathname;
    this.fsPath = this.path;
  }
  static file(value) { return new Uri(`file://${value}`); }
  static parse(value) { return new Uri(value); }
  static joinPath(base, ...parts) { return base.with({ path: path.join(base.path, ...parts) }); }
  with(changes) { return new Uri(`${this.scheme}://${this.authority}${changes.path ?? this.path}`); }
  toString() { return `${this.scheme}://${this.authority}${this.path}`; }
}

class EventEmitter {
  listeners = new Set();
  event = listener => {
    this.listeners.add(listener);
    return { dispose: () => this.listeners.delete(listener) };
  };
  fire(value) { for (const listener of this.listeners) listener(value); }
  dispose() { this.listeners.clear(); }
}

class Memento {
  values = new Map();
  get(key) { return this.values.get(key); }
  async update(key, value) { this.values.set(key, value); }
}

const timers = new Map();
const originalSetTimeout = global.setTimeout;
const originalClearTimeout = global.clearTimeout;
let nextTimer = 1;
let now = 0;
const scheduleTimeout = (callback, delay) => {
  const id = nextTimer++;
  timers.set(id, { callback, due: now + delay });
  return id;
};


let env;
const vscode = {
  Uri, EventEmitter,
  FileType: { File: 1, Directory: 2, SymbolicLink: 64 },
  ProgressLocation: { Notification: 1 },
  get workspace() { return env.workspace; },
  get window() { return env.window; },
};
const originalLoad = Module._load;
Module._load = function (request, ...rest) {
  return request === 'vscode' ? vscode : originalLoad.call(this, request, ...rest);
};

const { FilterService } = require('../../out/filterService');
const { ChangeTracker } = require('../../out/changeTracker');
const { BaselineService } = require('../../out/baselineService');
const { BaselineCaptureService } = require('../../out/baselineCaptureService');
const { ReviewManager } = require('../../out/reviewManager');
const { TrackingController } = require('../../out/trackingController');
Module._load = originalLoad;

function createFixture(includes = ['**/*']) {
  timers.clear();
  now = 0;
  global.setTimeout = scheduleTimeout;
  global.clearTimeout = id => timers.delete(id);
  const files = new Map();
  const directories = new Set(['/workspace', '/storage']);
  const configuration = { includePaths: includes, excludePaths: [], autoSave: false };
  const events = { config: new EventEmitter(), folders: new EventEmitter(), documents: new EventEmitter() };
  const watchers = [];
  let reads = 0;
  let discoveries = 0;
  const root = { name: 'workspace', uri: Uri.file('/workspace') };
  const put = (uri, text) => {
    const previous = files.get(uri.path);
    files.set(uri.path, { bytes: new TextEncoder().encode(text), mtime: (previous?.mtime ?? 0) + 1 });
    for (let parent = path.dirname(uri.path); parent !== '/'; parent = path.dirname(parent)) directories.add(parent);
  };
  const missing = () => Object.assign(new Error('missing'), { code: 'FileNotFound' });
  const workspace = {
    workspaceFolders: [root], textDocuments: [],
    getWorkspaceFolder: uri => uri.path.startsWith('/workspace/') || uri.path === '/workspace' ? root : undefined,
    asRelativePath: uri => path.relative('/workspace', uri.path),
    getConfiguration: () => ({ get: (key, fallback) => configuration[key] ?? fallback }),
    onDidChangeConfiguration: events.config.event,
    onDidChangeWorkspaceFolders: events.folders.event,
    onDidChangeTextDocument: events.documents.event,
    createFileSystemWatcher() {
      const change = new EventEmitter(), create = new EventEmitter(), deletion = new EventEmitter();
      const watcher = {
        onDidChange: change.event, onDidCreate: create.event, onDidDelete: deletion.event,
        emit: (uri, kind) => ({ changed: change, created: create, deleted: deletion })[kind].fire(uri),
        dispose() { change.dispose(); create.dispose(); deletion.dispose(); },
      };
      watchers.push(watcher);
      return watcher;
    },
    async findFiles(include, exclude) {
      discoveries++;
      return [...files.keys()].filter(value => value.startsWith('/workspace/')).filter(value => {
        const relative = path.relative('/workspace', value);
        return minimatch(relative, include, { dot: true }) && (!exclude || !minimatch(relative, exclude, { dot: true }));
      }).map(Uri.file);
    },
    fs: {
      async stat(uri) {
        const file = files.get(uri.path);
        if (file) return { type: 1, mtime: file.mtime, ctime: 1, size: file.bytes.length };
        if (directories.has(uri.path)) return { type: 2, mtime: 1, ctime: 1, size: 0 };
        throw missing();
      },
      async readFile(uri) {
        reads++;
        const file = files.get(uri.path);
        if (!file) throw missing();
        return new Uint8Array(file.bytes);
      },
      async writeFile(uri, bytes) { files.set(uri.path, { bytes: new Uint8Array(bytes), mtime: 1 }); },
      async createDirectory(uri) { directories.add(uri.path); },
      async delete(uri) {
        let found = false;
        for (const key of files.keys()) {
          if (key === uri.path || key.startsWith(`${uri.path}/`)) { files.delete(key); found = true; }
        }
        for (const key of directories) {
          if (key === uri.path || key.startsWith(`${uri.path}/`)) { directories.delete(key); found = true; }
        }
        if (!found) throw missing();
      },
      async readDirectory(uri) {
        return [
          ...[...directories].filter(key => key !== uri.path && path.dirname(key) === uri.path).map(key => [path.basename(key), 2]),
          ...[...files.keys()].filter(key => path.dirname(key) === uri.path).map(key => [path.basename(key), 1]),
        ];
      },
    },
  };
  env = {
    workspace,
    window: {
      withProgress: async (_options, body) => body({ report() {} }, {
        isCancellationRequested: false, onCancellationRequested: () => ({ dispose() {} }),
      }),
      showInformationMessage() {}, showErrorMessage() {}, showWarningMessage() {},
    },
  };
  const filters = new FilterService(new Memento());
  const baselines = new BaselineService(Uri.file('/storage/session'));
  const changes = new ChangeTracker(filters);
  const captures = new BaselineCaptureService(baselines, filters);
  const reviews = new ReviewManager(baselines, changes);
  const controller = new TrackingController(baselines, captures, filters, changes, reviews);
  return { files, put, filters, baselines, changes, captures, reviews, controller, workspace,
    setConfiguration(key, value) {
      configuration[key] = value;
      events.config.fire({ affectsConfiguration: setting => setting === `cherryDiff.${key}` });
    },
    getReads: () => reads,
    getDiscoveries: () => discoveries,
    getTimerCount: () => timers.size,
    async dispose() {
      await controller.stopTracking();
      controller.dispose();
      changes.dispose();
      filters.dispose();
      reviews.dispose();
      global.setTimeout = originalSetTimeout;
      global.clearTimeout = originalClearTimeout;
    },
    emit(uri, kind) { for (const watcher of watchers) watcher.emit(uri, kind); },
    async advance(ms) {
      now += ms;
      for (const [id, timer] of [...timers]) {
        if (timer.due <= now) { timers.delete(id); timer.callback(); }
      }
      await controller.operations.run(async () => {});
    },
  };
}

module.exports = { createFixture, Uri };
