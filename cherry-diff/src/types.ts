import type * as vscode from 'vscode';
import type { Hunk } from 'diff';

export type HunkStatus = 'pending' | 'accepted' | 'rejected';
export type HunkKind = 'content' | 'file-created' | 'file-deleted';

export interface HunkReview {
  id: string;
  hunk: Hunk;
  status: HunkStatus;
  kind: HunkKind;
}

export interface FileReview {
  uri: vscode.Uri;
  relativePath: string;
  baselineContent: string;
  baselineExists: boolean;
  currentContent: string;
  currentExists: boolean;
  hunks: HunkReview[];
}
