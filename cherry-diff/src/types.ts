import type * as vscode from 'vscode';
import type { StructuredPatchHunk } from 'diff';
import type { FileSnapshot } from './fileSnapshot';

export type Resolution = 'accepted' | 'rejected';
export type HunkKind =
  | 'content'
  | 'file-created'
  | 'file-deleted'
  | 'binary'
  | 'whole-file';

export interface HunkReview {
  id: string;
  hunk: StructuredPatchHunk;
  kind: HunkKind;
}

export interface FileReview {
  key: string;
  uri: vscode.Uri;
  relativePath: string;
  baseline: FileSnapshot;
  current: FileSnapshot;
  hunks: HunkReview[];
}
