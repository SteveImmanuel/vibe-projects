const test = require('node:test');
const assert = require('node:assert/strict');
const { globMatch } = require('../out/glob');

const cases = [
  ['src/extension.ts', '**/*', true],
  ['extension.ts', '**/*', true],
  ['src/extension.ts', 'src/**', true],
  ['src/deep/extension.ts', 'src/**', true],
  ['src/extension.ts', '*.ts', false],
  ['extension.ts', '*.ts', true],
  ['node_modules/diff/lib/index.js', '**/node_modules/**', true],
  ['src/app.min.js', '**/*.min.js', true],
  ['src/app.js', '**/*.min.js', false],
  ['src/a.ts', 'src/?.ts', true],
  ['src/ab.ts', 'src/?.ts', false],
  ['src\\extension.ts', 'src/**', true],
];

for (const [filepath, pattern, expected] of cases) {
  test(`${pattern} ${expected ? 'matches' : 'does not match'} ${filepath}`, () => {
    assert.equal(globMatch(filepath, pattern), expected);
  });
}
