import * as vscode from 'vscode';
import {
  BASELINE_DOCUMENT_SCHEME,
  CURRENT_DOCUMENT_SCHEME,
  DIFF_SCROLL_DELAY_MS,
} from './constants';
import { ReviewManager } from './reviewManager';
import type { FileReview } from './types';

type ReviewDocumentScheme =
  | typeof BASELINE_DOCUMENT_SCHEME
  | typeof CURRENT_DOCUMENT_SCHEME;

export function createReviewDocumentUri(
  scheme: ReviewDocumentScheme,
  sourceUri: vscode.Uri
): vscode.Uri {
  return vscode.Uri.from({
    scheme,
    path: sourceUri.path,
    query: encodeURIComponent(sourceUri.toString()),
  });
}

export function getReviewResourceKey(uri: vscode.Uri): string | undefined {
  if (!uri.query) {
    return undefined;
  }
  try {
    return decodeURIComponent(uri.query);
  } catch {
    return undefined;
  }
}

/** Parameterized provider for baseline and deleted-current virtual documents. */
export class ReviewContentProvider implements vscode.TextDocumentContentProvider, vscode.Disposable {
  private readonly _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  readonly onDidChange = this._onDidChange.event;
  private readonly reviewSubscription: vscode.Disposable;

  constructor(
    private readonly reviews: ReviewManager,
    private readonly scheme: ReviewDocumentScheme,
    private readonly selectContent: (review: FileReview) => string | undefined
  ) {
    this.reviewSubscription = reviews.onDidChangeReview((event) => {
      for (const uri of [...event.changed, ...event.removed]) {
        this._onDidChange.fire(createReviewDocumentUri(this.scheme, uri));
      }
    });
  }

  provideTextDocumentContent(uri: vscode.Uri): string {
    const key = getReviewResourceKey(uri);
    const review = key ? this.reviews.getFileReview(key) : undefined;
    return review ? this.selectContent(review) ?? '' : '';
  }

  dispose(): void {
    this.reviewSubscription.dispose();
    this._onDidChange.dispose();
  }
}

export async function openDiffForReview(
  review: FileReview,
  line?: number
): Promise<void> {
  if (review.baseline.text === undefined || review.current.text === undefined) {
    vscode.window.showInformationMessage(
      `Cherry Diff: ${review.relativePath} is binary or not UTF-8. It can be accepted or rejected only as a whole.`
    );
    return;
  }
  if (review.hunks.some((hunk) => hunk.kind === 'whole-file')) {
    vscode.window.showInformationMessage(
      `Cherry Diff: ${review.relativePath} is too large or complex for a safe per-hunk diff. It can be accepted or rejected only as a whole.`
    );
    return;
  }

  const baselineUri = createReviewDocumentUri(BASELINE_DOCUMENT_SCHEME, review.uri);
  const rightUri = review.current.exists
    ? review.uri
    : createReviewDocumentUri(CURRENT_DOCUMENT_SCHEME, review.uri);

  await vscode.commands.executeCommand(
    'vscode.diff',
    baselineUri,
    rightUri,
    `${review.relativePath} (Baseline ↔ Current)`
  );

  if (line === undefined) {
    return;
  }

  setTimeout(() => {
    const editor = vscode.window.activeTextEditor;
    if (!editor || (editor.document.uri.toString() !== rightUri.toString()
      && editor.document.uri.toString() !== baselineUri.toString())) {
      return;
    }
    const position = new vscode.Position(Math.max(0, line), 0);
    editor.selection = new vscode.Selection(position, position);
    editor.revealRange(
      new vscode.Range(position, position),
      vscode.TextEditorRevealType.InCenter
    );
  }, DIFF_SCROLL_DELAY_MS);
}
