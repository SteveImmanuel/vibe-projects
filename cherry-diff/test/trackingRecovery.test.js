const test = require('node:test');
const assert = require('node:assert/strict');
const { createFixture, Uri } = require('./helpers/workspace');

function fixture(t, includes) {
  const f = createFixture(includes);
  t.after(() => f.dispose());
  return f;
}

for (const reviewed of [false, true]) {
  test(`unrelated filter changes preserve ${reviewed ? 'reviewed' : 'unreviewed'} new files`, async (t) => {
    const f = fixture(t);
    await f.controller.startTracking();
    const uri = Uri.file('/workspace/new.ts');
    f.put(uri, 'new content\n');
    f.emit(uri, 'created');
    if (reviewed) await f.advance(800);

    await f.filters.updateOverrides([{ uri: Uri.file('/workspace/unrelated'), included: false, recursive: true }]);
    await f.advance(300);

    assert.equal(f.filters.isIncluded(uri), true);
    assert.equal(f.baselines.hasBaseline(uri), false);
    assert.equal(f.reviews.getFileReview(uri.toString()).baseline.exists, false);
    assert.equal(f.reviews.getFileReview(uri.toString()).current.text, 'new content\n');
  });
}

test('newly included files receive baselines while previously included new files remain pending', async (t) => {
  const f = fixture(t);
  const newlyIncluded = Uri.file('/workspace/excluded.ts');
  const newFile = Uri.file('/workspace/new.ts');
  await f.filters.updateOverrides([{ uri: newlyIncluded, included: false, recursive: false }]);
  f.put(newlyIncluded, 'existing excluded content\n');
  await f.controller.startTracking();
  f.put(newFile, 'new content\n');
  // No event: changing a selection must preserve even a missed creation.
  await f.filters.clearOverrides();
  await f.advance(300);

  assert.equal((await f.baselines.getSnapshot(newlyIncluded)).text, 'existing excluded content\n');
  assert.equal(f.reviews.getFileReview(newlyIncluded.toString()), undefined);
  assert.equal(f.reviews.getFileReview(newFile.toString()).baseline.exists, false);
});

test('manual refresh applies pending filter changes before reviewing newly included files', async (t) => {
  const f = fixture(t);
  const uri = Uri.file('/workspace/excluded.ts');
  f.put(uri, 'existing\n');
  await f.filters.updateOverrides([{ uri, included: false, recursive: false }]);
  await f.controller.startTracking();
  await f.filters.clearOverrides();
  await f.controller.refreshReview();
  assert.equal((await f.baselines.getSnapshot(uri)).text, 'existing\n');
  assert.equal(f.reviews.getAllFileReviews().size, 0);
});

test('filter synchronization clears a premature review of a newly included file', async (t) => {
  const f = fixture(t);
  const uri = Uri.file('/workspace/excluded.ts');
  f.put(uri, 'existing\n');
  await f.filters.updateOverrides([{ uri, included: false, recursive: false }]);
  await f.controller.startTracking();
  await f.filters.clearOverrides();
  f.emit(uri, 'changed');
  await f.controller.refreshReview(false);
  assert.equal(f.reviews.getFileReview(uri.toString()).baseline.exists, false);
  await f.advance(300);
  assert.equal((await f.baselines.getSnapshot(uri)).text, 'existing\n');
  assert.equal(f.reviews.getAllFileReviews().size, 0);
});

for (const mode of ['glob', 'checked-file']) {
  test(`parent-only deletion reviews an included child selected by ${mode}`, async (t) => {
    const f = fixture(t, mode === 'glob' ? ['**/*.ts'] : ['**/*']);
    const directory = Uri.file('/workspace/src');
    const uri = Uri.file('/workspace/src/app.ts');
    f.put(uri, 'original\n');
    if (mode === 'checked-file') {
      await f.filters.updateOverrides([
        { uri: directory, included: false, recursive: true },
        { uri, included: true, recursive: false },
      ]);
    }
    await f.controller.startTracking();
    await f.workspace.fs.delete(directory);
    f.emit(directory, 'deleted');
    await f.advance(800);

    const review = f.reviews.getFileReview(uri.toString());
    assert.equal(review.baseline.text, 'original\n');
    assert.equal(review.current.exists, false);
  });
}

test('parent-only creation discovers included descendants without tracking excluded files', async (t) => {
  const f = fixture(t, ['**/*.ts']);
  await f.controller.startTracking();
  const directory = Uri.file('/workspace/src');
  const uri = Uri.file('/workspace/src/app.ts');
  const excluded = Uri.file('/workspace/src/notes.txt');
  f.put(uri, 'new code\n');
  f.put(excluded, 'notes\n');
  f.emit(directory, 'created');
  await f.advance(800);

  assert.equal(f.reviews.getFileReview(uri.toString()).baseline.exists, false);
  assert.equal(f.reviews.getFileReview(excluded.toString()), undefined);
  assert.equal(f.baselines.hasBaseline(excluded), false);
});

test('excluded subtree events stay ignored unless they contain an explicit inclusion', async (t) => {
  const f = fixture(t, ['**/*.ts']);
  const directory = Uri.file('/workspace/generated');
  const selected = Uri.file('/workspace/generated/selected.ts');
  f.setConfiguration('excludePaths', ['**/generated/**']);
  await f.controller.startTracking();
  f.put(selected, 'generated\n');
  f.emit(directory, 'created');
  f.emit(selected, 'created');
  assert.equal(f.changes.getChanges().length, 0);

  await f.filters.updateOverrides([{ uri: selected, included: true, recursive: false }]);
  await f.advance(300);
  assert.equal((await f.baselines.getSnapshot(selected)).text, 'generated\n');
  await f.workspace.fs.delete(directory);
  f.emit(directory, 'deleted');
  await f.advance(800);
  assert.equal(f.reviews.getFileReview(selected.toString()).current.exists, false);
});

test('coalesced directory replacement reviews modified, deleted, and new children', async (t) => {
  const f = fixture(t);
  const directory = Uri.file('/workspace/src');
  const modified = Uri.file('/workspace/src/app.ts');
  const deleted = Uri.file('/workspace/src/old.ts');
  const created = Uri.file('/workspace/src/new.ts');
  f.put(modified, 'original\n');
  f.put(deleted, 'old\n');
  await f.controller.startTracking();
  await f.workspace.fs.delete(directory);
  f.emit(directory, 'deleted');
  f.put(modified, 'replacement\n');
  f.put(created, 'new\n');
  f.emit(directory, 'created');
  await f.advance(800);

  assert.equal(f.reviews.getFileReview(modified.toString()).current.text, 'replacement\n');
  assert.equal(f.reviews.getFileReview(deleted.toString()).current.exists, false);
  assert.equal(f.reviews.getFileReview(created.toString()).baseline.exists, false);
  assert.equal(f.reviews.getAllFileReviews().size, 3);
});

test('ordinary file events refresh incrementally without running discovery', async (t) => {
  const f = fixture(t);
  const uri = Uri.file('/workspace/app.ts');
  f.put(uri, 'original\n');
  await f.controller.startTracking();
  const discoveries = f.getDiscoveries();
  f.put(uri, 'edit\n');
  f.emit(uri, 'changed');
  await f.advance(800);
  assert.equal(f.reviews.getFileReview(uri.toString()).current.text, 'edit\n');
  assert.equal(f.getDiscoveries(), discoveries);
});
