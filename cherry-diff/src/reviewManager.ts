import * as vscode from 'vscode';
import { BaselineService } from './baselineService';
import { MAX_TEXT_DIFF_BYTES } from './constants';
import { ChangeTracker } from './changeTracker';
import { computeHunks, createSyntheticHunk, reconstructFile } from './diffService';
import {
  FileSnapshot,
  isFileNotFound,
  missingFileSnapshot,
  readFileSnapshot,
  snapshotsEqual,
  textFileSnapshot,
} from './fileSnapshot';
import type { FileReview, HunkReview, Resolution } from './types';

export class ReviewManager implements vscode.Disposable {
  private readonly fileReviews = new Map<string, FileReview>();
  private readonly reportedReadErrors = new Set<string>();
  private readonly _onDidChangeReview = new vscode.EventEmitter<void>();
  readonly onDidChangeReview = this._onDidChangeReview.event;

  constructor(
    private readonly baselineService: BaselineService,
    private readonly changeTracker: ChangeTracker
  ) {}

  /** Recompute only resources dirtied since the previous refresh. */
  async refreshDirty(): Promise<number> {
    if (!this.changeTracker.isTracking()) {
      return this.getPendingHunks().length;
    }

    let changed = false;
    for (const change of this.changeTracker.getChanges()) {
      if (!this.changeTracker.shouldTrack(change.uri)) {
        this.fileReviews.delete(change.key);
        this.changeTracker.acknowledge(change.key, change.revision);
        changed = true;
        continue;
      }

      try {
        const baseline = await this.getBaseline(change.uri);
        const currentResult = await readFileSnapshot(change.uri);
        if (currentResult.kind === 'unstable') {
          continue;
        }
        if (currentResult.kind === 'directory') {
          this.fileReviews.delete(change.key);
          this.changeTracker.acknowledge(change.key, change.revision);
          changed = true;
          continue;
        }

        // A newer event arrived while this resource was being read. Leave it
        // dirty so an older snapshot can never overwrite a newer review.
        if (this.changeTracker.getChange(change.key)?.revision !== change.revision) {
          continue;
        }

        const current = currentResult.snapshot;
        const hunks = getReviewHunks(
          vscode.workspace.asRelativePath(change.uri),
          baseline,
          current
        );
        if (hunks.length === 0) {
          this.fileReviews.delete(change.key);
        } else {
          this.fileReviews.set(change.key, {
            key: change.key,
            uri: change.uri,
            relativePath: vscode.workspace.asRelativePath(change.uri),
            baseline,
            current,
            hunks,
          });
        }

        this.changeTracker.acknowledge(change.key, change.revision);
        this.reportedReadErrors.delete(change.key);
        changed = true;
      } catch (error) {
        console.error(`[Cherry Diff] Failed to review ${change.uri.toString()}`, error);
        if (!this.reportedReadErrors.has(change.key)) {
          this.reportedReadErrors.add(change.key);
          vscode.window.showErrorMessage(
            `Cherry Diff: Failed to read ${vscode.workspace.asRelativePath(change.uri)}. It remains pending.`
          );
        }
      }
    }

    if (changed) {
      this._onDidChangeReview.fire();
    }
    return this.getPendingHunks().length;
  }

  async acceptHunk(resourceKey: string, hunkId: string): Promise<boolean> {
    const review = this.fileReviews.get(resourceKey);
    const hunk = review?.hunks.find((candidate) => candidate.id === hunkId);
    if (!review || !hunk || !await this.ensureCurrent(review)) {
      return false;
    }

    if (hunk.kind !== 'content') {
      await this.baselineService.updateBaseline(review.uri, review.current);
      this.fileReviews.delete(resourceKey);
      await this.autoSave(review.uri);
      this._onDidChangeReview.fire();
      return true;
    }

    if (review.baseline.text === undefined) {
      return false;
    }
    const newBaselineText = reconstructFile(
      review.relativePath,
      review.baseline.text,
      [hunk.hunk]
    );
    if (newBaselineText === false) {
      vscode.window.showErrorMessage('Cherry Diff: Failed to accept the selected hunk.');
      return false;
    }

    const exists = newBaselineText !== '' || review.current.exists;
    const newBaseline = exists
      ? textFileSnapshot(
        newBaselineText,
        getTextEncoding(review.baseline, review.current)
      )
      : missingFileSnapshot();
    await this.baselineService.updateBaseline(review.uri, newBaseline);
    review.baseline = newBaseline;
    this.updateReviewHunks(review);

    await this.autoSave(review.uri);
    this._onDidChangeReview.fire();
    return true;
  }

  async rejectHunk(resourceKey: string, hunkId: string): Promise<boolean> {
    const review = this.fileReviews.get(resourceKey);
    const hunkIndex = review?.hunks.findIndex((candidate) => candidate.id === hunkId) ?? -1;
    if (!review || hunkIndex === -1 || !await this.ensureCurrent(review)) {
      return false;
    }

    const rejectedHunk = review.hunks[hunkIndex];
    let target: FileSnapshot;
    if (rejectedHunk.kind !== 'content') {
      target = review.baseline;
    } else {
      if (review.baseline.text === undefined) {
        return false;
      }
      const keepHunks = review.hunks
        .filter((candidate, index) => index !== hunkIndex && candidate.kind === 'content')
        .map((candidate) => candidate.hunk);
      const newText = reconstructFile(
        review.relativePath,
        review.baseline.text,
        keepHunks
      );
      if (newText === false) {
        vscode.window.showErrorMessage(
          `Cherry Diff: Failed to reject the selected hunk for ${review.relativePath}.`
        );
        return false;
      }
      const exists = newText !== '' || review.baseline.exists;
      target = exists
        ? textFileSnapshot(
          newText,
          getTextEncoding(review.baseline, review.current)
        )
        : missingFileSnapshot();
    }

    await this.applySnapshot(review.uri, review.current, target);
    review.current = target;
    this.updateReviewHunks(review);
    await this.autoSave(review.uri);
    this._onDidChangeReview.fire();
    return true;
  }

  async resolveFile(
    resourceKey: string,
    resolution: Resolution,
    notify = true
  ): Promise<boolean> {
    const review = this.fileReviews.get(resourceKey);
    if (!review || !await this.ensureCurrent(review)) {
      return false;
    }

    if (resolution === 'accepted') {
      await this.baselineService.updateBaseline(review.uri, review.current);
    } else {
      await this.applySnapshot(review.uri, review.current, review.baseline);
    }

    this.fileReviews.delete(resourceKey);
    await this.autoSave(review.uri);
    if (notify) {
      this._onDidChangeReview.fire();
    }
    return true;
  }

  async resolveAll(resolution: Resolution): Promise<void> {
    let changed = false;
    for (const resourceKey of [...this.fileReviews.keys()]) {
      changed = await this.resolveFile(resourceKey, resolution, false) || changed;
    }
    if (changed) {
      this._onDidChangeReview.fire();
    }
  }

  getFileReview(resourceKey: string): FileReview | undefined {
    return this.fileReviews.get(resourceKey);
  }

  getAllFileReviews(): ReadonlyMap<string, FileReview> {
    return this.fileReviews;
  }

  getPendingHunks(): Array<{ resourceKey: string; hunk: HunkReview }> {
    const result: Array<{ resourceKey: string; hunk: HunkReview }> = [];
    for (const [resourceKey, review] of this.fileReviews) {
      for (const hunk of review.hunks) {
        result.push({ resourceKey, hunk });
      }
    }
    return result;
  }

  removeReviews(predicate: (review: FileReview) => boolean): void {
    let changed = false;
    for (const [key, review] of this.fileReviews) {
      if (predicate(review)) {
        this.fileReviews.delete(key);
        changed = true;
      }
    }
    if (changed) {
      this._onDidChangeReview.fire();
    }
  }

  clearReview(): void {
    if (this.fileReviews.size === 0) {
      return;
    }
    this.fileReviews.clear();
    this._onDidChangeReview.fire();
  }

  dispose(): void {
    this._onDidChangeReview.dispose();
  }

  private async getBaseline(uri: vscode.Uri): Promise<FileSnapshot> {
    const baseline = await this.baselineService.getSnapshot(uri);
    if (baseline) {
      return baseline;
    }
    if (!this.baselineService.isComplete()) {
      throw new Error(`No complete baseline is available for ${uri.toString()}`);
    }

    // Once the initial capture has completed without truncation or skipped
    // files, an absent path is known to have been created after the boundary.
    return missingFileSnapshot();
  }

  private async ensureCurrent(review: FileReview): Promise<boolean> {
    const currentResult = await readFileSnapshot(review.uri);
    if (currentResult.kind !== 'snapshot'
      || !snapshotsEqual(currentResult.snapshot, review.current)) {
      this.changeTracker.markChange(review.uri, 'changed');
      await this.refreshDirty();
      vscode.window.showInformationMessage(
        `Cherry Diff: ${review.relativePath} changed after this review was prepared. Review it again before resolving changes.`
      );
      return false;
    }
    return true;
  }

  private updateReviewHunks(review: FileReview): void {
    review.hunks = getReviewHunks(
      review.relativePath,
      review.baseline,
      review.current
    );
    if (review.hunks.length === 0) {
      this.fileReviews.delete(review.key);
    }
  }

  private async applySnapshot(
    uri: vscode.Uri,
    current: FileSnapshot,
    target: FileSnapshot
  ): Promise<void> {
    if (!target.exists) {
      if (!current.exists) {
        return;
      }
      const edit = new vscode.WorkspaceEdit();
      edit.deleteFile(uri, { ignoreIfNotExists: true });
      if (!await vscode.workspace.applyEdit(edit)) {
        throw new Error(`VS Code refused to delete ${uri.toString()}`);
      }
      try {
        await vscode.workspace.fs.stat(uri);
        throw new Error(`The file still exists after deletion: ${uri.toString()}`);
      } catch (error) {
        if (!isFileNotFound(error)) {
          throw error;
        }
      }
      return;
    }

    if (current.exists
      && current.text !== undefined
      && target.text !== undefined
      && current.encoding === target.encoding) {
      const document = await vscode.workspace.openTextDocument(uri);
      const edit = new vscode.WorkspaceEdit();
      const fullRange = new vscode.Range(
        document.lineAt(0).range.start,
        document.lineAt(document.lineCount - 1).range.end
      );
      edit.replace(uri, fullRange, target.text);
      if (!await vscode.workspace.applyEdit(edit)) {
        throw new Error(`VS Code refused to update ${uri.toString()}`);
      }
      if (document.getText() !== target.text) {
        throw new Error(`The edited content could not be verified for ${uri.toString()}`);
      }
      return;
    }

    const openDocument = vscode.workspace.textDocuments.find(
      (document) => document.uri.toString() === uri.toString()
    );
    if (openDocument?.isDirty) {
      throw new Error(
        `Cannot safely replace the byte content of dirty document ${uri.toString()}`
      );
    }
    if (!current.exists) {
      const parentPath = uri.path.slice(0, uri.path.lastIndexOf('/')) || '/';
      await vscode.workspace.fs.createDirectory(uri.with({
        path: parentPath,
        query: '',
        fragment: '',
      }));
    }
    await vscode.workspace.fs.writeFile(uri, target.bytes);
    const writtenBytes = await vscode.workspace.fs.readFile(uri);
    if (!byteArraysEqual(writtenBytes, target.bytes)) {
      throw new Error(`Written bytes could not be verified for ${uri.toString()}`);
    }
  }

  private async autoSave(uri: vscode.Uri): Promise<void> {
    if (!vscode.workspace.getConfiguration('cherryDiff').get<boolean>('autoSave', true)) {
      return;
    }

    const document = vscode.workspace.textDocuments.find(
      (candidate) => candidate.uri.toString() === uri.toString()
    );
    if (document?.isDirty && !await document.save()) {
      vscode.window.showWarningMessage(
        `Cherry Diff: ${vscode.workspace.asRelativePath(uri)} could not be saved automatically.`
      );
    }
  }
}

function getReviewHunks(
  relativePath: string,
  baseline: FileSnapshot,
  current: FileSnapshot
): HunkReview[] {
  if (snapshotsEqual(baseline, current)) {
    return [];
  }

  if (baseline.text !== undefined && current.text !== undefined) {
    if (baseline.bytes.length > MAX_TEXT_DIFF_BYTES
      || current.bytes.length > MAX_TEXT_DIFF_BYTES) {
      return [createSyntheticHunk('whole-file')];
    }
    const hunks = computeHunks(
      relativePath,
      baseline.text,
      current.text,
      baseline.exists,
      current.exists
    );
    if (hunks === undefined) {
      return [createSyntheticHunk('whole-file')];
    }
    if (hunks.length > 0) {
      return hunks;
    }
  }

  const kind = !baseline.exists
    ? 'file-created'
    : !current.exists
      ? 'file-deleted'
      : 'binary';
  return [createSyntheticHunk(kind)];
}

function getTextEncoding(
  baseline: FileSnapshot,
  current: FileSnapshot
): 'utf8' | 'utf8bom' {
  return baseline.exists
    ? baseline.encoding ?? 'utf8'
    : current.encoding ?? 'utf8';
}

function byteArraysEqual(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}
