const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

class FakeUri {
  constructor(value) {
    this.value = value;
    this.path = value;
    this.fsPath = value;
    this.scheme = 'file';
    this.authority = '';
  }
  toString() { return this.value; }
}

const fakeVscode = {
  workspace: {
    getConfiguration: () => ({ get: (_key, fallback) => fallback }),
    asRelativePath: (uri) => uri.toString(),
  },
};

const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') return fakeVscode;
  return originalLoad.call(this, request, parent, isMain);
};
const { BaselineCaptureService } = require('../out/baselineCaptureService');
Module._load = originalLoad;

const token = {
  isCancellationRequested: false,
  onCancellationRequested: () => ({ dispose() {} }),
};

test('waits for every capture worker before reporting a failure', async () => {
  let slowCaptureFinished = false;
  const baselines = {
    async captureBaseline(uri) {
      if (uri.toString() === 'bad') throw new Error('capture failed');
      await new Promise((resolve) => setTimeout(resolve, 20));
      slowCaptureFinished = true;
      return 'captured';
    },
  };
  const captures = new BaselineCaptureService(baselines, {});

  await assert.rejects(
    captures.captureUntilStable(
      [new FakeUri('bad'), new FakeUri('slow')],
      undefined,
      token,
      () => false
    ),
    /Failed to capture 1 file/
  );
  assert.equal(slowCaptureFinished, true);
});

test('retries unstable files with a bounded capture loop', async () => {
  let attempts = 0;
  const baselines = {
    async captureBaseline() {
      attempts++;
      return attempts < 3 ? 'unstable' : 'captured';
    },
  };
  const captures = new BaselineCaptureService(baselines, {});

  await captures.captureUntilStable(
    [new FakeUri('changing')],
    undefined,
    token,
    () => false
  );
  assert.equal(attempts, 3);
});
