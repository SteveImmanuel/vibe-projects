import * as vscode from 'vscode';
import { ReviewManager } from './reviewManager';

export class BaselineContentProvider implements vscode.TextDocumentContentProvider {
  private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  readonly onDidChange = this._onDidChange.event;

  constructor(private reviewManager: ReviewManager) {
    reviewManager.onDidChangeReview(() => {
      for (const fsPath of reviewManager.getAllFileReviews().keys()) {
        this._onDidChange.fire(
          vscode.Uri.parse(`cherry-diff-baseline:${fsPath}`)
        );
      }
    });
  }

  provideTextDocumentContent(uri: vscode.Uri): string {
    const fsPath = uri.path;
    const review = this.reviewManager.getFileReview(fsPath);
    if (review) {
      return review.baselineContent;
    }
    return '';
  }

  dispose(): void {
    this._onDidChange.dispose();
  }
}

/**
 * Virtual doc provider for showing the "current" content of deleted files.
 */
export class CurrentContentProvider implements vscode.TextDocumentContentProvider {
  private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  readonly onDidChange = this._onDidChange.event;

  constructor(private reviewManager: ReviewManager) {
    reviewManager.onDidChangeReview(() => {
      for (const fsPath of reviewManager.getAllFileReviews().keys()) {
        this._onDidChange.fire(
          vscode.Uri.parse(`cherry-diff-current:${fsPath}`)
        );
      }
    });
  }

  provideTextDocumentContent(uri: vscode.Uri): string {
    const fsPath = uri.path;
    const review = this.reviewManager.getFileReview(fsPath);
    if (review) {
      return review.currentContent;
    }
    return '';
  }

  dispose(): void {
    this._onDidChange.dispose();
  }
}

/**
 * Open a diff editor showing baseline (left) vs current (right).
 * Handles deleted files (current is empty) and new files (baseline is empty)
 * by using virtual documents for sides that don't exist on disk.
 */
export async function openDiffForFile(
  fsPath: string,
  line?: number,
  reviewManager?: ReviewManager
): Promise<void> {
  const baselineUri = vscode.Uri.parse(`cherry-diff-baseline:${fsPath}`);
  const currentUri = vscode.Uri.file(fsPath);
  const relativePath = vscode.workspace.asRelativePath(currentUri);

  // Check if the file exists on disk
  let fileExists = true;
  try {
    await vscode.workspace.fs.stat(currentUri);
  } catch {
    fileExists = false;
  }

  let rightUri: vscode.Uri;
  if (fileExists) {
    rightUri = currentUri;
  } else {
    // Deleted file — use virtual document for the right side
    rightUri = vscode.Uri.parse(`cherry-diff-current:${fsPath}`);
  }

  await vscode.commands.executeCommand(
    'vscode.diff',
    baselineUri,
    rightUri,
    `${relativePath} (Baseline ↔ Current)`
  );

  if (line !== undefined) {
    setTimeout(() => {
      const editor = vscode.window.activeTextEditor;
      if (editor) {
        const pos = new vscode.Position(line, 0);
        editor.selection = new vscode.Selection(pos, pos);
        editor.revealRange(
          new vscode.Range(pos, pos),
          vscode.TextEditorRevealType.InCenter
        );
      }
    }, 200);
  }
}
