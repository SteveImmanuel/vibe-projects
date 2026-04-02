import * as vscode from 'vscode';
import { BaselineService } from './baselineService';
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
    if (this.applying) {
      return 0;
    }

    this.fileReviews.clear();
    const changedFiles = this.changeTracker.getChangedFiles();
    let totalHunks = 0;

    for (const fsPath of changedFiles) {
      const uri = vscode.Uri.file(fsPath);
      const relativePath = vscode.workspace.asRelativePath(uri);

      // New files have no baseline — treat as empty (entire file is "added")
      const baselineContent = this.baselineService.getBaseline(fsPath) ?? '';

      let currentContent: string;
      try {
        await vscode.workspace.fs.stat(uri);
        const doc = await vscode.workspace.openTextDocument(uri);
        currentContent = doc.getText();
      } catch {
        // File was deleted — treat current content as empty
        currentContent = '';
      }

      if (baselineContent === currentContent) {
        continue;
      }

      const hunks = computeHunks(relativePath, baselineContent, currentContent);
      if (hunks.length === 0) {
        continue;
      }

      this.fileReviews.set(fsPath, {
        uri,
        relativePath,
        baselineContent,
        currentContent,
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

    const newBaseline = reconstructFile(
      review.relativePath,
      review.baselineContent,
      [hunk.hunk]
    );

    if (newBaseline === false) {
      vscode.window.showErrorMessage('Cherry Diff: Failed to accept hunk.');
      return;
    }

    review.baselineContent = newBaseline;
    this.baselineService.updateBaseline(fsPath, newBaseline);

    const remainingHunks = computeHunks(
      review.relativePath,
      review.baselineContent,
      review.currentContent
    );

    if (remainingHunks.length === 0) {
      this.fileReviews.delete(fsPath);
    } else {
      review.hunks = remainingHunks;
    }

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

    const keepHunks = review.hunks
      .filter((_, i) => i !== hunkIndex)
      .map((h) => h.hunk);

    const newContent = reconstructFile(
      review.relativePath,
      review.baselineContent,
      keepHunks
    );

    if (newContent === false) {
      vscode.window.showErrorMessage(
        `Cherry Diff: Failed to reject hunk for ${review.relativePath}`
      );
      return;
    }

    this.applying = true;
    try {
      await this.writeFileContent(review.uri, newContent);

      review.currentContent = newContent;
      const remainingHunks = computeHunks(
        review.relativePath,
        review.baselineContent,
        newContent
      );

      if (remainingHunks.length === 0) {
        this.fileReviews.delete(fsPath);
        this.baselineService.updateBaseline(fsPath, newContent);
      } else {
        review.hunks = remainingHunks;
      }
    } finally {
      this.applying = false;
    }

    await this.autoSave(review.uri);
    this._onDidChangeReview.fire();
  }

  async setAllHunksInFile(fsPath: string, status: HunkStatus): Promise<void> {
    const review = this.fileReviews.get(fsPath);
    if (!review) {
      return;
    }

    if (status === 'accepted') {
      // Accept all: advance baseline to current content
      // If file was deleted (currentContent === ''), accepting means confirming deletion
      this.baselineService.updateBaseline(fsPath, review.currentContent);
      this.fileReviews.delete(fsPath);
    } else if (status === 'rejected') {
      // Reject all: revert file to baseline
      this.applying = true;
      try {
        await this.writeFileContent(review.uri, review.baselineContent);
      } finally {
        this.applying = false;
      }
      this.fileReviews.delete(fsPath);
    }

    await this.autoSave(review.uri);
    this._onDidChangeReview.fire();
  }

  /**
   * Write content to a file, handling new/deleted file edge cases:
   * - If content is empty and baseline is empty: delete the file (was a new file, rejecting it)
   * - If content is non-empty but file doesn't exist: create the file (was deleted, rejecting restores it)
   * - Otherwise: replace file content normally
   */
  private async writeFileContent(uri: vscode.Uri, content: string): Promise<void> {
    if (content === '') {
      // Empty content means delete the file (rejected new file, or all content removed)
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
      await this.setAllHunksInFile(fsPath, status);
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
