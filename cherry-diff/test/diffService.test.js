const test = require('node:test');
const assert = require('node:assert/strict');
const { computeHunks, reconstructFile, getChangedLineRange } = require('../out/diffService');

test('computes and reconstructs independent content hunks', () => {
  const lines = Array.from({ length: 20 }, (_, index) => `line ${index + 1}`);
  const baseline = `${lines.join('\n')}\n`;
  const changedLines = [...lines];
  changedLines[0] = 'LINE 1';
  changedLines[19] = 'LINE 20';
  const current = `${changedLines.join('\n')}\n`;
  const hunks = computeHunks('file.txt', baseline, current, true, true);

  assert.equal(hunks.length, 2);
  assert.ok(hunks.every((hunk) => hunk.kind === 'content'));
  assert.deepEqual(
    computeHunks('file.txt', baseline, current, true, true).map((hunk) => hunk.id),
    hunks.map((hunk) => hunk.id)
  );

  const firstOnly = reconstructFile('file.txt', baseline, [hunks[0].hunk]);
  assert.equal(firstOnly, `LINE 1\n${lines.slice(1).join('\n')}\n`);
});

test('represents creation of an empty file as a reviewable hunk', () => {
  const hunks = computeHunks('empty.txt', '', '', false, true);

  assert.equal(hunks.length, 1);
  assert.equal(hunks[0].kind, 'file-created');
  assert.deepEqual(getChangedLineRange(hunks[0].hunk), { startLine: 0, endLine: 0 });
});

test('represents deletion of an empty file as a reviewable hunk', () => {
  const hunks = computeHunks('empty.txt', '', '', true, false);

  assert.equal(hunks.length, 1);
  assert.equal(hunks[0].kind, 'file-deleted');
});

test('aborts pathological diffs beyond the configured edit bound', () => {
  const baseline = 'a\n'.repeat(501);
  const current = 'b\n'.repeat(501);
  assert.equal(computeHunks('large.txt', baseline, current, true, true), undefined);
});

test('does not create an existence hunk when state is unchanged', () => {
  assert.deepEqual(computeHunks('empty.txt', '', '', true, true), []);
  assert.deepEqual(computeHunks('missing.txt', '', '', false, false), []);
});
