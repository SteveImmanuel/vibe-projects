const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path').posix;
const Module = require('node:module');

class FakeUri {
  constructor(fsPath, scheme = 'file', authority = '') {
    this.fsPath = path.normalize(fsPath);
    this.path = this.fsPath;
    this.scheme = scheme;
    this.authority = authority;
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
    return new FakeUri(path.join(base.fsPath, ...segments), base.scheme, base.authority);
  }

  toString() {
    return `${this.scheme}:${this.fsPath}`;
  }

  with(changes) {
    return new FakeUri(changes.path ?? this.path, this.scheme, this.authority);
  }
}

class FakeFileSystemError extends Error {
  constructor(message, code) {
    super(message);
    this.code = code;
  }
}

function createFakeVscode() {
  const files = new Map();
  const directories = new Set(['/']);
  let blobReads = 0;

  const createDirectory = async (uri) => {
    let current = uri.fsPath;
    while (current !== '/') {
      directories.add(current);
      current = path.dirname(current);
    }
    directories.add('/');
  };

  const vscode = {
    Uri: FakeUri,
    FileSystemError: FakeFileSystemError,
    FileType: { File: 1, Directory: 2, SymbolicLink: 64 },
    workspace: {
      textDocuments: [],
      fs: {
        createDirectory,
        async stat(uri) {
          if (files.has(uri.fsPath)) {
            return {
              type: 1,
              ctime: 1,
              mtime: 1,
              size: files.get(uri.fsPath).byteLength,
            };
          }
          if (directories.has(uri.fsPath)) {
            return { type: 2, ctime: 1, mtime: 1, size: 0 };
          }
          throw new FakeFileSystemError(`ENOENT: ${uri.fsPath}`, 'FileNotFound');
        },
        async readFile(uri) {
          const bytes = files.get(uri.fsPath);
          if (!bytes) {
            throw new FakeFileSystemError(`ENOENT: ${uri.fsPath}`, 'FileNotFound');
          }
          if (uri.fsPath.startsWith('/storage/')) {
            blobReads++;
          }
          return new Uint8Array(bytes);
        },
        async writeFile(uri, bytes) {
          await createDirectory(new FakeUri(path.dirname(uri.fsPath)));
          files.set(uri.fsPath, new Uint8Array(bytes));
        },
        async delete(uri, options = {}) {
          if (options.recursive) {
            let deleted = false;
            for (const filePath of [...files.keys()]) {
              if (filePath === uri.fsPath || filePath.startsWith(`${uri.fsPath}/`)) {
                files.delete(filePath);
                deleted = true;
              }
            }
            for (const directory of [...directories]) {
              if (directory === uri.fsPath || directory.startsWith(`${uri.fsPath}/`)) {
                directories.delete(directory);
                deleted = true;
              }
            }
            if (!deleted) {
              throw new FakeFileSystemError(`ENOENT: ${uri.fsPath}`, 'FileNotFound');
            }
            return;
          }
          if (!files.delete(uri.fsPath) && !directories.delete(uri.fsPath)) {
            throw new FakeFileSystemError(`ENOENT: ${uri.fsPath}`, 'FileNotFound');
          }
        },
      },
    },
  };

  return {
    vscode,
    files,
    getBlobReads: () => blobReads,
    putBytes(fsPath, bytes) {
      files.set(fsPath, new Uint8Array(bytes));
    },
    putText(fsPath, content) {
      files.set(fsPath, new TextEncoder().encode(content));
    },
    blobFiles() {
      return [...files.keys()].filter((filePath) => filePath.startsWith('/storage/blobs/'));
    },
  };
}

const fake = createFakeVscode();
const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') {
    return fake.vscode;
  }
  return originalLoad.call(this, request, parent, isMain);
};
const { BaselineService } = require('../out/baselineService');
const { textFileSnapshot } = require('../out/fileSnapshot');
Module._load = originalLoad;

test('stores path-addressed baselines on disk and loads them lazily', async () => {
  const a = FakeUri.file('/workspace/a.txt');
  const b = FakeUri.file('/workspace/b.txt');
  fake.putText(a.fsPath, 'same content');
  fake.putText(b.fsPath, 'same content');
  const service = new BaselineService(FakeUri.file('/storage'));

  await service.clearBaselines();
  assert.equal(await service.captureBaseline(a), 'captured');
  assert.equal(await service.captureBaseline(b), 'captured');
  assert.equal(service.getBaselineCount(), 2);
  assert.equal(fake.blobFiles().length, 2);
  assert.equal(fake.getBlobReads(), 0);

  const snapshot = await service.getSnapshot(a);
  assert.equal(snapshot.exists, true);
  assert.equal(snapshot.text, 'same content');
  assert.equal(fake.getBlobReads(), 1);

  await service.updateBaseline(a, textFileSnapshot('accepted content'));
  assert.equal((await service.getSnapshot(a)).text, 'accepted content');

  service.removeBaseline(a);
  service.removeBaseline(b);
  assert.equal(service.getBaselineCount(), 0);
});

test('records missing files without creating content blobs', async () => {
  const service = new BaselineService(FakeUri.file('/storage'));
  const missing = FakeUri.file('/workspace/missing.txt');
  await service.clearBaselines();

  assert.equal(await service.captureBaseline(missing), 'missing');
  const snapshot = await service.getSnapshot(missing);
  assert.equal(snapshot.exists, false);
  assert.equal(snapshot.text, '');
  assert.equal(fake.blobFiles().length, 0);
});

test('captures unsaved text from an already-open UTF-8 document', async () => {
  const uri = FakeUri.file('/workspace/open.txt');
  fake.putText(uri.fsPath, 'saved content');
  fake.vscode.workspace.textDocuments.push({
    uri,
    version: 3,
    getText: () => 'unsaved content',
  });
  const service = new BaselineService(FakeUri.file('/storage'));
  await service.clearBaselines();

  assert.equal(await service.captureBaseline(uri), 'captured');
  assert.equal((await service.getSnapshot(uri)).text, 'unsaved content');
});

test('preserves UTF-8 BOM metadata and bytes', async () => {
  const uri = FakeUri.file('/workspace/bom.txt');
  fake.putBytes(uri.fsPath, [0xef, 0xbb, 0xbf, 104, 105]);
  const service = new BaselineService(FakeUri.file('/storage'));
  await service.clearBaselines();

  assert.equal(await service.captureBaseline(uri), 'captured');
  const snapshot = await service.getSnapshot(uri);
  assert.equal(snapshot.text, 'hi');
  assert.equal(snapshot.encoding, 'utf8bom');
  assert.deepEqual([...snapshot.bytes], [0xef, 0xbb, 0xbf, 104, 105]);
});

test('preserves binary bytes without decoding them as text', async () => {
  const uri = FakeUri.file('/workspace/image.bin');
  fake.putBytes(uri.fsPath, [0, 255, 10, 20]);
  const service = new BaselineService(FakeUri.file('/storage'));
  await service.clearBaselines();

  assert.equal(await service.captureBaseline(uri), 'captured');
  const snapshot = await service.getSnapshot(uri);
  assert.equal(snapshot.text, undefined);
  assert.deepEqual([...snapshot.bytes], [0, 255, 10, 20]);
});
