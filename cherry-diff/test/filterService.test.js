const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');

const fakeVscode = {
  workspace: {
    asRelativePath: (uri) => uri.fsPath,
    getConfiguration: () => ({
      get: (_key, fallback) => fallback,
    }),
  },
  ConfigurationTarget: { Workspace: 2, Global: 1 },
};

const originalLoad = Module._load;
Module._load = function patchedLoad(request, parent, isMain) {
  if (request === 'vscode') {
    return fakeVscode;
  }
  return originalLoad.call(this, request, parent, isMain);
};
const { isPathIncluded, normalizeFilterPath } = require('../out/filterService');
Module._load = originalLoad;

test('path overrides take precedence over include and exclude globs', () => {
  assert.equal(
    isPathIncluded('src/app.ts', ['**/*'], [], { src: false }),
    false
  );
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
