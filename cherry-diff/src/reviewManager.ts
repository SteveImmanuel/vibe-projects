import * as vscode from 'vscode';
import { BaselineService } from './baselineService';
import type { BaselineSnapshot } from './baselineService';
import { ChangeTracker } from './changeTracker';
import { computeHunks, reconstructFile } from './diffService';
import { FileReview, HunkStatus } from './types';

export class ReviewManager implements vscode.Disposable {
  private fileReviews = new Map<string, FileReview>();
  private _onDidChangeReview = new vscode.EventEmitter<void>();
  readonly onDidChangeReview = this._onDidChangeReview.event;
  private applying = false;

  constructor(
    private baselineService: BaselineService,
    private changeTracker: ChangeTracker
  ) {}

  async startReview(): Promise<number> {
    if (this.applying || !this.changeTracker.isTracking()) {
      return 0;
    }

    this.fileReviews.clear();
    const changedFiles = this.changeTracker.getChangedFiles();
    let totalHunks = 0;

    for (const fsPath of changedFiles) {
      const uri = vscode.Uri.file(fsPath);
      if (!this.changeTracker.shouldTrack(uri)) {
        continue;
      }
      const relativePath = vscode.workspace.asRelativePath(uri);
      let baseline: BaselineSnapshot | undefined;
      try {
        baseline = await this.baselineService.getSnapshot(fsPath);
      } catch (error) {
        console.error(`[Cherry Diff] Failed to load baseline for ${fsPath}`, error);
        vscode.window.showErrorMessage(
          `Cherry Diff: Failed to load the baseline for ${relativePath}.`
        );
        continue;
      }
      const baselineContent = baseline?.content ?? '';
      const baselineExists = baseline?.exists ?? false;

      let currentContent = '';
      let currentExists = false;
      try {
        const stat = await vscode.workspace.fs.stat(uri);
        if ((stat.type & vscode.FileType.Directory) !== 0) {
          continue;
        }
        currentExists = true;
        const doc = await vscode.workspace.openTextDocument(uri);
        currentContent = doc.getText();
      } catch {
        if (currentExists) {
          // The file exists but is not a readable text document.
          continue;
        }
      }

      if (baselineContent === currentContent && baselineExists === currentExists) {
        continue;
      }

      const hunks = computeHunks(
        relativePath,
        baselineContent,
        currentContent,
        baselineExists,
        currentExists
      );
      if (hunks.length === 0) {
        continue;
      }

      this.fileReviews.set(fsPath, {
        uri,
        relativePath,
        baselineContent,
        baselineExists,
        currentContent,
        currentExists,
        hunks,
      });

      totalHunks += hunks.length;
    }

    this._onDidChangeReview.fire();
    return totalHunks;
  }

  async acceptHunk(fsPath: string, hunkId: string): Promise<void> {
    const review = this.fileReviews.get(fsPath);
    if (!review) {
      return;
    }
    const hunk = review.hunks.find((h) => h.id === hunkId);
    if (!hunk || hunk.status !== 'pending') {
      return;
    }

    if (hunk.kind !== 'content') {
      await this.baselineService.updateBaseline(
        fsPath,
        review.currentContent,
        review.currentExists
      );
      review.baselineContent = review.currentContent;
      review.baselineExists = review.currentExists;
      this.fileReviews.delete(fsPath);
      await this.autoSave(review.uri);
      this._onDidChangeReview.fire();
      return;
    }

    const newBaseline = reconstructFile(
      review.relativePath,
      review.baselineContent,
      [hunk.hunk]
    );

    if (newBaseline === false) {
      vscode.window.showErrorMessage('Cherry Diff: Failed to accept hunk.');
      return;
    }

    const newBaselineExists = newBaseline !== '' || review.currentExists;
    await this.baselineService.updateBaseline(
      fsPath,
      newBaseline,
      newBaselineExists
    );
    review.baselineContent = newBaseline;
    review.baselineExists = newBaselineExists;

    const remainingHunks = computeHunks(
      review.relativePath,
      review.baselineContent,
      review.currentContent,
      review.baselineExists,
      review.currentExists
    );

    if (remainingHunks.length === 0) {
      this.fileReviews.delete(fsPath);
    } else {
      review.hunks = remainingHunks;
    }

    await this.autoSave(review.uri);
    this._onDidChangeReview.fire();
  }

  async rejectHunk(fsPath: string, hunkId: string): Promise<void> {
    const review = this.fileReviews.get(fsPath);
    if (!review) {
      return;
    }
    const hunkIndex = review.hunks.findIndex((h) => h.id === hunkId);
    if (hunkIndex === -1 || review.hunks[hunkIndex].status !== 'pending') {
      return;
    }

    const rejectedHunk = review.hunks[hunkIndex];
    const keepHunks = review.hunks
      .filter((_, i) => i !== hunkIndex)
      .filter((h) => h.kind === 'content')
      .map((h) => h.hunk);

    const newContent = rejectedHunk.kind === 'content'
      ? reconstructFile(review.relativePath, review.baselineContent, keepHunks)
      : review.baselineContent;

    if (newContent === false) {
      vscode.window.showErrorMessage(
        `Cherry Diff: Failed to reject hunk for ${review.relativePath}`
      );
      return;
    }

    const newExists = rejectedHunk.kind === 'content'
      ? newContent !== '' || review.baselineExists
      : review.baselineExists;

    this.applying = true;
    try {
      await this.writeFileContent(review.uri, newContent, newExists);

      review.currentContent = newContent;
      review.currentExists = newExists;
      const remainingHunks = computeHunks(
        review.relativePath,
        review.baselineContent,
        newContent,
        review.baselineExists,
        newExists
      );

      if (remainingHunks.length === 0) {
        this.fileReviews.delete(fsPath);
        await this.baselineService.updateBaseline(fsPath, newContent, newExists);
      } else {
        review.hunks = remainingHunks;
      }
    } finally {
      this.applying = false;
    }

    await this.autoSave(review.uri);
    this._onDidChangeReview.fire();
  }

  async setAllHunksInFile(
    fsPath: string,
    status: HunkStatus,
    notify = true
  ): Promise<void> {
    const review = this.fileReviews.get(fsPath);
    if (!review) {
      return;
    }

    if (status === 'accepted') {
      // Accept all: advance baseline to current content
      // If file was deleted (currentContent === ''), accepting means confirming deletion
      await this.baselineService.updateBaseline(
        fsPath,
        review.currentContent,
        review.currentExists
      );
      this.fileReviews.delete(fsPath);
    } else if (status === 'rejected') {
      // Reject all: revert file to baseline
      this.applying = true;
      try {
        await this.writeFileContent(
          review.uri,
          review.baselineContent,
          review.baselineExists
        );
      } finally {
        this.applying = false;
      }
      this.fileReviews.delete(fsPath);
    }

    await this.autoSave(review.uri);
    if (notify) {
      this._onDidChangeReview.fire();
    }
  }

  /**
   * Write a complete file state, keeping existence separate from content so
   * an empty file is not confused with a missing file.
   */
  private async writeFileContent(
    uri: vscode.Uri,
    content: string,
    shouldExist: boolean
  ): Promise<void> {
    if (!shouldExist) {
      try {
        await vscode.workspace.fs.delete(uri);
      } catch {
        // Already gone
      }
      return;
    }

    // Check if file exists on disk
    let fileExists = true;
    try {
      await vscode.workspace.fs.stat(uri);
    } catch {
      fileExists = false;
    }

    if (!fileExists) {
      // File was deleted, need to recreate it
      const encoder = new TextEncoder();
      await vscode.workspace.fs.writeFile(uri, encoder.encode(content));
      return;
    }

    // Normal case: file exists, replace contents
    const doc = await vscode.workspace.openTextDocument(uri);
    const edit = new vscode.WorkspaceEdit();
    const fullRange = new vscode.Range(
      doc.lineAt(0).range.start,
      doc.lineAt(doc.lineCount - 1).range.end
    );
    edit.replace(uri, fullRange, content);
    await vscode.workspace.applyEdit(edit);
  }

  /**
   * Save the file if autoSave is enabled in settings.
   */
  private async autoSave(uri: vscode.Uri): Promise<void> {
    const autoSave = vscode.workspace.getConfiguration('cherryDiff').get<boolean>('autoSave', true);
    if (!autoSave) {
      return;
    }
    try {
      const doc = await vscode.workspace.openTextDocument(uri);
      if (doc.isDirty) {
        await doc.save();
      }
    } catch {
      // File might not exist (deleted)
    }
  }

  async setAllHunks(status: HunkStatus): Promise<void> {
    const fsPaths = Array.from(this.fileReviews.keys());
    for (const fsPath of fsPaths) {
      await this.setAllHunksInFile(fsPath, status, false);
    }
    if (fsPaths.length > 0) {
      this._onDidChangeReview.fire();
    }
  }

  isApplying(): boolean {
    return this.applying;
  }

  getFileReview(fsPath: string): FileReview | undefined {
    return this.fileReviews.get(fsPath);
  }

  getAllFileReviews(): Map<string, FileReview> {
    return this.fileReviews;
  }

  getAllPendingHunks(): Array<{ fsPath: string; hunk: import('./types').HunkReview }> {
    const result: Array<{ fsPath: string; hunk: import('./types').HunkReview }> = [];
    for (const [fsPath, review] of this.fileReviews) {
      for (const hunk of review.hunks) {
        if (hunk.status === 'pending') {
          result.push({ fsPath, hunk });
        }
      }
    }
    return result;
  }

  isReviewActive(): boolean {
    return this.fileReviews.size > 0;
  }

  clearReview(): void {
    this.fileReviews.clear();
    this._onDidChangeReview.fire();
  }

  dispose(): void {
    this._onDidChangeReview.dispose();
  }
}
