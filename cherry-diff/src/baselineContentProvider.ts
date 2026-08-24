import * as vscode from 'vscode';
import { ReviewManager } from './reviewManager';

export type ReviewDocumentScheme = 'cherry-diff-baseline' | 'cherry-diff-current';

/** Build a portable virtual-document URI while retaining the source path. */
export function createReviewDocumentUri(
  scheme: ReviewDocumentScheme,
  fsPath: string
): vscode.Uri {
  const fileUri = vscode.Uri.file(fsPath);
  return vscode.Uri.from({
    scheme,
    path: fileUri.path,
    query: encodeURIComponent(fsPath),
  });
}

/** Recover the exact platform path embedded by createReviewDocumentUri. */
export function getReviewDocumentFsPath(uri: vscode.Uri): string {
  if (uri.query) {
    try {
      return decodeURIComponent(uri.query);
    } catch {
      // Fall through for malformed or legacy URIs.
    }
  }
  return vscode.Uri.file(uri.path).fsPath;
}

export class BaselineContentProvider implements vscode.TextDocumentContentProvider, vscode.Disposable {
  private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  readonly onDidChange = this._onDidChange.event;
  private readonly reviewSubscription: vscode.Disposable;

  constructor(private reviewManager: ReviewManager) {
    this.reviewSubscription = reviewManager.onDidChangeReview(() => {
      for (const fsPath of reviewManager.getAllFileReviews().keys()) {
        this._onDidChange.fire(
          createReviewDocumentUri('cherry-diff-baseline', fsPath)
        );
      }
    });
  }

  provideTextDocumentContent(uri: vscode.Uri): string {
    const review = this.reviewManager.getFileReview(getReviewDocumentFsPath(uri));
    return review?.baselineContent ?? '';
  }

  dispose(): void {
    this.reviewSubscription.dispose();
    this._onDidChange.dispose();
  }
}

/** Virtual document provider for the current content of deleted files. */
export class CurrentContentProvider implements vscode.TextDocumentContentProvider, vscode.Disposable {
  private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  readonly onDidChange = this._onDidChange.event;
  private readonly reviewSubscription: vscode.Disposable;

  constructor(private reviewManager: ReviewManager) {
    this.reviewSubscription = reviewManager.onDidChangeReview(() => {
      for (const fsPath of reviewManager.getAllFileReviews().keys()) {
        this._onDidChange.fire(
          createReviewDocumentUri('cherry-diff-current', fsPath)
        );
      }
    });
  }

  provideTextDocumentContent(uri: vscode.Uri): string {
    const review = this.reviewManager.getFileReview(getReviewDocumentFsPath(uri));
    return review?.currentContent ?? '';
  }

  dispose(): void {
    this.reviewSubscription.dispose();
    this._onDidChange.dispose();
  }
}

/**
 * Open a diff editor showing baseline (left) vs current (right).
 * Handles deleted files by using a virtual document on the right.
 */
export async function openDiffForFile(
  fsPath: string,
  line?: number
): Promise<void> {
  const baselineUri = createReviewDocumentUri('cherry-diff-baseline', fsPath);
  const currentUri = vscode.Uri.file(fsPath);
  const relativePath = vscode.workspace.asRelativePath(currentUri);

  let fileExists = true;
  try {
    await vscode.workspace.fs.stat(currentUri);
  } catch {
    fileExists = false;
  }

  const rightUri = fileExists
    ? currentUri
    : createReviewDocumentUri('cherry-diff-current', fsPath);

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
        const pos = new vscode.Position(Math.max(0, line), 0);
        editor.selection = new vscode.Selection(pos, pos);
        editor.revealRange(
          new vscode.Range(pos, pos),
          vscode.TextEditorRevealType.InCenter
        );
      }
    }, 200);
  }
}
