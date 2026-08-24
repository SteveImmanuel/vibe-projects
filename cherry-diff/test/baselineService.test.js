const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path').posix;
const Module = require('node:module');

class FakeUri {
  constructor(fsPath, scheme = 'file') {
    this.fsPath = path.normalize(fsPath);
    this.path = this.fsPath;
    this.scheme = scheme;
  }

  static file(fsPath) {
    return new FakeUri(fsPath);
  }

  static joinPath(base, ...segments) {
    return new FakeUri(path.join(base.fsPath, ...segments), base.scheme);
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
    FileType: { File: 1, Directory: 2 },
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
          throw new Error(`ENOENT: ${uri.fsPath}`);
        },
        async readFile(uri) {
          const bytes = files.get(uri.fsPath);
          if (!bytes) {
            throw new Error(`ENOENT: ${uri.fsPath}`);
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
            for (const filePath of [...files.keys()]) {
              if (filePath === uri.fsPath || filePath.startsWith(`${uri.fsPath}/`)) {
                files.delete(filePath);
              }
            }
            for (const directory of [...directories]) {
              if (directory === uri.fsPath || directory.startsWith(`${uri.fsPath}/`)) {
                directories.delete(directory);
              }
            }
            return;
          }
          if (!files.delete(uri.fsPath) && !directories.delete(uri.fsPath)) {
            throw new Error(`ENOENT: ${uri.fsPath}`);
          }
        },
      },
    },
  };

  return {
    vscode,
    files,
    getBlobReads: () => blobReads,
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
Module._load = originalLoad;

test('stores deduplicated baselines on disk and loads them lazily', async () => {
  fake.putText('/workspace/a.txt', 'same content');
  fake.putText('/workspace/b.txt', 'same content');
  const service = new BaselineService(FakeUri.file('/storage'));

  await service.clearBaselines();
  assert.equal(await service.captureBaseline(FakeUri.file('/workspace/a.txt')), 'captured');
  assert.equal(await service.captureBaseline(FakeUri.file('/workspace/b.txt')), 'captured');
  assert.equal(service.getBaselineCount(), 2);
  assert.equal(fake.blobFiles().length, 1);
  assert.equal(fake.getBlobReads(), 0);

  assert.deepEqual(await service.getSnapshot('/workspace/a.txt'), {
    content: 'same content',
    exists: true,
  });
  assert.equal(fake.getBlobReads(), 1);

  await service.updateBaseline('/workspace/a.txt', 'accepted content', true);
  assert.equal(fake.blobFiles().length, 2);
  await service.updateBaseline('/workspace/b.txt', 'accepted content', true);
  assert.equal(fake.blobFiles().length, 1);

  await service.removeBaseline('/workspace', true);
  assert.equal(service.getBaselineCount(), 0);
  assert.equal(fake.blobFiles().length, 0);
});

test('records missing files without creating content blobs', async () => {
  const service = new BaselineService(FakeUri.file('/storage'));
  await service.clearBaselines();

  assert.equal(await service.captureBaseline(FakeUri.file('/workspace/missing.txt')), 'missing');
  assert.deepEqual(await service.getSnapshot('/workspace/missing.txt'), {
    content: '',
    exists: false,
  });
  assert.equal(fake.blobFiles().length, 0);
});

test('captures unsaved text from an already-open document', async () => {
  fake.putText('/workspace/open.txt', 'saved content');
  fake.vscode.workspace.textDocuments.push({
    uri: FakeUri.file('/workspace/open.txt'),
    version: 3,
    getText: () => 'unsaved content',
  });
  const service = new BaselineService(FakeUri.file('/storage'));
  await service.clearBaselines();

  assert.equal(await service.captureBaseline(FakeUri.file('/workspace/open.txt')), 'captured');
  assert.deepEqual(await service.getSnapshot('/workspace/open.txt'), {
    content: 'unsaved content',
    exists: true,
  });
});
