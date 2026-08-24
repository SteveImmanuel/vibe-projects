const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path').posix;
const Module = require('node:module');

class FakeUri {
  constructor(fsPath, scheme = 'file') {
    this.fsPath = path.normalize(fsPath);
    this.path = this.fsPath;
    this.scheme = scheme;
    this.authority = '';
    this.query = '';
    this.fragment = '';
  }

  static file(fsPath) {
    return new FakeUri(fsPath);
  }

  static parse(value) {
    const match = /^([^:]+):(.*)$/.exec(value);
    return new FakeUri(match?.[2] ?? value, match?.[1] ?? 'file');
  }

  static joinPath(base, ...segments) {
    return new FakeUri(path.join(base.fsPath, ...segments), base.scheme);
  }

  toString() {
    return `${this.scheme}:${this.fsPath}`;
  }

  with(changes) {
    return new FakeUri(changes.path ?? this.path, this.scheme);
  }
}

class FakeFileSystemError extends Error {
  constructor(message, code) {
    super(message);
    this.code = code;
  }
}

class FakeEventEmitter {
  constructor() {
    this.listeners = new Set();
    this.event = (listener) => {
      this.listeners.add(listener);
      return { dispose: () => this.listeners.delete(listener) };
    };
  }
  fire(value) {
    for (const listener of this.listeners) listener(value);
  }
  dispose() {
    this.listeners.clear();
  }
}

class FakePosition {
  constructor(line, character) {
    this.line = line;
    this.character = character;
  }
}

class FakeRange {
  constructor(start, end) {
    this.start = start;
    this.end = end;
  }
}

class FakeWorkspaceEdit {
  constructor() {
    this.operations = [];
  }
  replace(uri, _range, content) {
    this.operations.push({ kind: 'replace', uri, content });
  }
  deleteFile(uri) {
    this.operations.push({ kind: 'delete', uri });
  }
}

function createFakeVscode() {
  const files = new Map();
  const mtimes = new Map();
  const messages = [];
  let applyEditResult = true;

  function putBytes(uri, bytes) {
    files.set(uri.toString(), new Uint8Array(bytes));
    mtimes.set(uri.toString(), (mtimes.get(uri.toString()) ?? 0) + 1);
  }

  function putText(uri, text) {
    putBytes(uri, new TextEncoder().encode(text));
  }

  const workspace = {
    textDocuments: [],
    getWorkspaceFolder: () => ({ name: 'workspace', uri: FakeUri.file('/workspace') }),
    asRelativePath: (uri) => uri.fsPath.replace(/^\/workspace\//, ''),
    getConfiguration: () => ({ get: (_key, fallback) => fallback === true ? false : fallback }),
    fs: {
      async stat(uri) {
        const bytes = files.get(uri.toString());
        if (!bytes) throw new FakeFileSystemError('missing', 'FileNotFound');
        return {
          type: 1,
          ctime: 1,
          mtime: mtimes.get(uri.toString()),
          size: bytes.length,
        };
      },
      async readFile(uri) {
        const bytes = files.get(uri.toString());
        if (!bytes) throw new FakeFileSystemError('missing', 'FileNotFound');
        return new Uint8Array(bytes);
      },
      async writeFile(uri, bytes) {
        putBytes(uri, bytes);
      },
      async createDirectory() {},
    },
    async openTextDocument(uri) {
      const text = new TextDecoder().decode(files.get(uri.toString()) ?? new Uint8Array());
      const lines = text.split('\n');
      return {
        uri,
        version: 1,
        isDirty: false,
        getText: () => new TextDecoder().decode(
          files.get(uri.toString()) ?? new Uint8Array()
        ),
        lineCount: lines.length,
        lineAt(index) {
          return {
            range: {
              start: new FakePosition(index, 0),
              end: new FakePosition(index, lines[index]?.length ?? 0),
            },
          };
        },
        save: async () => true,
      };
    },
    async applyEdit(edit) {
      if (!applyEditResult) return false;
      for (const operation of edit.operations) {
        if (operation.kind === 'replace') putText(operation.uri, operation.content);
        if (operation.kind === 'delete') {
          files.delete(operation.uri.toString());
          mtimes.delete(operation.uri.toString());
        }
      }
      return true;
    },
  };

  return {
    vscode: {
      Uri: FakeUri,
      FileSystemError: FakeFileSystemError,
      FileType: { File: 1, Directory: 2, SymbolicLink: 64 },
      EventEmitter: FakeEventEmitter,
      Position: FakePosition,
      Range: FakeRange,
      WorkspaceEdit: FakeWorkspaceEdit,
      workspace,
      window: {
        showErrorMessage: (message) => messages.push(message),
        showInformationMessage: (message) => messages.push(message),
        showWarningMessage: (message) => messages.push(message),
      },
    },
    files,
    messages,
    putBytes,
    putText,
    setApplyEditResult(value) {
      applyEditResult = value;
    },
  };
}

class FakeChangeTracker {
  constructor() {
    this.changes = new Map();
    this.revision = 0;
  }
  isTracking() { return true; }
  shouldTrack() { return true; }
  markChange(uri, kind = 'changed') {
    const change = {
      key: uri.toString(), uri, kind, revision: ++this.revision,
    };
    this.changes.set(change.key, change);
    return change;
  }
  getChanges() { return [...this.changes.values()]; }
  getChange(key) { return this.changes.get(key); }
  acknowledge(key, revision) {
    if (this.changes.get(key)?.revision !== revision) return false;
    return this.changes.delete(key);
  }
}

class FakeBaselineService {
  constructor() {
    this.snapshots = new Map();
    this.complete = true;
  }
  async getSnapshot(uri) { return this.snapshots.get(uri.toString()); }
  async updateBaseline(uri, snapshot) { this.snapshots.set(uri.toString(), snapshot); }
  isComplete() { return this.complete; }
}

const fake = createFakeVscode();
const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') return fake.vscode;
  return originalLoad.call(this, request, parent, isMain);
};
const { ReviewManager } = require('../out/reviewManager');
const { snapshotFromBytes, textFileSnapshot } = require('../out/fileSnapshot');
Module._load = originalLoad;

function createReviewFixture(baselineText, currentText) {
  const uri = FakeUri.file('/workspace/file.txt');
  const baselines = new FakeBaselineService();
  baselines.snapshots.set(uri.toString(), textFileSnapshot(baselineText));
  const changes = new FakeChangeTracker();
  fake.putText(uri, currentText);
  changes.markChange(uri);
  const reviews = new ReviewManager(baselines, changes);
  return { uri, baselines, changes, reviews };
}

test('refreshes only dirty resources and preserves unrelated reviews', async () => {
  const firstUri = FakeUri.file('/workspace/first.txt');
  const secondUri = FakeUri.file('/workspace/second.txt');
  const baselines = new FakeBaselineService();
  baselines.snapshots.set(firstUri.toString(), textFileSnapshot('one\n'));
  baselines.snapshots.set(secondUri.toString(), textFileSnapshot('two\n'));
  const changes = new FakeChangeTracker();
  fake.putText(firstUri, 'ONE\n');
  fake.putText(secondUri, 'TWO\n');
  changes.markChange(firstUri);
  changes.markChange(secondUri);
  const reviews = new ReviewManager(baselines, changes);
  await reviews.refreshDirty();
  const secondHunkId = reviews.getFileReview(secondUri.toString()).hunks[0].id;

  fake.putText(firstUri, 'ONE AGAIN\n');
  changes.markChange(firstUri);
  await reviews.refreshDirty();
  assert.equal(
    reviews.getFileReview(secondUri.toString()).hunks[0].id,
    secondHunkId
  );
});

test('does not reject a stale hunk over newer file content', async () => {
  const fixture = createReviewFixture('before\n', 'reviewed\n');
  await fixture.reviews.refreshDirty();
  const review = fixture.reviews.getFileReview(fixture.uri.toString());
  const hunkId = review.hunks[0].id;

  fake.putText(fixture.uri, 'newer\n');
  assert.equal(await fixture.reviews.rejectHunk(fixture.uri.toString(), hunkId), false);
  assert.equal(new TextDecoder().decode(fake.files.get(fixture.uri.toString())), 'newer\n');
  assert.equal(
    fixture.reviews.getFileReview(fixture.uri.toString()).current.text,
    'newer\n'
  );
});

test('keeps a review pending when VS Code refuses an edit', async () => {
  const fixture = createReviewFixture('before\n', 'after\n');
  await fixture.reviews.refreshDirty();
  const hunkId = fixture.reviews
    .getFileReview(fixture.uri.toString())
    .hunks[0].id;

  fake.setApplyEditResult(false);
  await assert.rejects(
    fixture.reviews.rejectHunk(fixture.uri.toString(), hunkId),
    /refused to update/
  );
  fake.setApplyEditResult(true);
  assert.ok(fixture.reviews.getFileReview(fixture.uri.toString()));
  assert.equal(new TextDecoder().decode(fake.files.get(fixture.uri.toString())), 'after\n');
});

test('keeps a new-file review pending when VS Code refuses deletion', async () => {
  const uri = FakeUri.file('/workspace/new.txt');
  const baselines = new FakeBaselineService();
  const changes = new FakeChangeTracker();
  fake.putText(uri, 'new content\n');
  changes.markChange(uri, 'created');
  const reviews = new ReviewManager(baselines, changes);

  await reviews.refreshDirty();
  const hunkId = reviews.getFileReview(uri.toString()).hunks[0].id;
  fake.setApplyEditResult(false);
  await assert.rejects(
    reviews.rejectHunk(uri.toString(), hunkId),
    /refused to delete/
  );
  fake.setApplyEditResult(true);
  assert.ok(reviews.getFileReview(uri.toString()));
  assert.equal(new TextDecoder().decode(fake.files.get(uri.toString())), 'new content\n');
});

test('reviews binary content as one whole-file hunk and restores exact bytes', async () => {
  const uri = FakeUri.file('/workspace/image.bin');
  const baselines = new FakeBaselineService();
  baselines.snapshots.set(uri.toString(), snapshotFromBytes(new Uint8Array([0, 1, 2])));
  const changes = new FakeChangeTracker();
  fake.putBytes(uri, [0, 9, 2]);
  changes.markChange(uri);
  const reviews = new ReviewManager(baselines, changes);

  await reviews.refreshDirty();
  const review = reviews.getFileReview(uri.toString());
  assert.equal(review.hunks.length, 1);
  assert.equal(review.hunks[0].kind, 'binary');

  assert.equal(await reviews.rejectHunk(uri.toString(), review.hunks[0].id), true);
  assert.deepEqual([...fake.files.get(uri.toString())], [0, 1, 2]);
  assert.equal(reviews.getFileReview(uri.toString()), undefined);
});

test('does not interpret an absent baseline as a new file before capture completes', async () => {
  const uri = FakeUri.file('/workspace/unknown.txt');
  const baselines = new FakeBaselineService();
  baselines.complete = false;
  const changes = new FakeChangeTracker();
  fake.putText(uri, 'content\n');
  changes.markChange(uri);
  const reviews = new ReviewManager(baselines, changes);

  const originalConsoleError = console.error;
  console.error = () => {};
  try {
    await reviews.refreshDirty();
  } finally {
    console.error = originalConsoleError;
  }
  assert.equal(reviews.getFileReview(uri.toString()), undefined);
  assert.equal(changes.getChanges().length, 1);
});
