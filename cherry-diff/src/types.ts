import type * as vscode from 'vscode';
import type { Hunk } from 'diff';

export type HunkStatus = 'pending' | 'accepted' | 'rejected';

export interface HunkReview {
  id: string;
  hunk: Hunk;
  status: HunkStatus;
}

export interface FileReview {
  uri: vscode.Uri;
  relativePath: string;
  baselineContent: string;
  currentContent: string;
  hunks: HunkReview[];
}
