import { createHash } from 'crypto';
import { structuredPatch, applyPatch, formatPatch } from 'diff';
import { MAX_DIFF_EDIT_LENGTH } from './constants';
import type { StructuredPatch, StructuredPatchHunk } from 'diff';
import type { HunkKind, HunkReview } from './types';

function generateHunkId(
  kind: HunkKind,
  hunk: StructuredPatchHunk,
  index: number
): string {
  const hash = createHash('sha256')
    .update(kind)
    .update('\0')
    .update(String(index))
    .update('\0')
    .update(String(hunk.oldStart))
    .update('\0')
    .update(String(hunk.newStart))
    .update('\0')
    .update(hunk.lines.join('\n'))
    .digest('hex')
    .slice(0, 20);
  return `hunk_${hash}`;
}

/**
 * Compute a structured diff between baseline and current content.
 * Returns an array of HunkReview objects, one per hunk.
 */
export function computeHunks(
  relativePath: string,
  baselineContent: string,
  currentContent: string,
  baselineExists = true,
  currentExists = true
): HunkReview[] | undefined {
  const patch = structuredPatch(
    relativePath,
    relativePath,
    baselineContent,
    currentContent,
    undefined,
    undefined,
    { maxEditLength: MAX_DIFF_EDIT_LENGTH }
  );
  if (!patch) {
    return undefined;
  }

  const hunks: HunkReview[] = patch.hunks.map((hunk, index) => ({
    id: generateHunkId('content', hunk, index),
    hunk,
    kind: 'content',
  }));

  // An empty file creation/deletion has no textual diff. Represent the
  // existence change as a synthetic hunk so it can still be reviewed.
  if (hunks.length === 0 && baselineExists !== currentExists) {
    const kind = currentExists ? 'file-created' : 'file-deleted';
    const hunk: StructuredPatchHunk = {
      oldStart: 1,
      oldLines: 0,
      newStart: 1,
      newLines: 0,
      lines: [],
    };
    hunks.push({
      id: generateHunkId(kind, hunk, 0),
      hunk,
      kind,
    });
  }

  return hunks;
}

export function createSyntheticHunk(kind: Exclude<HunkKind, 'content'>): HunkReview {
  const hunk: StructuredPatchHunk = {
    oldStart: 1,
    oldLines: 0,
    newStart: 1,
    newLines: 0,
    lines: [],
  };
  return {
    id: generateHunkId(kind, hunk, 0),
    hunk,
    kind,
  };
}

/**
 * Given a baseline and a set of accepted hunks, reconstruct the file content
 * by applying only the accepted hunks to the baseline.
 */
export function reconstructFile(
  relativePath: string,
  baselineContent: string,
  acceptedHunks: StructuredPatchHunk[]
): string | false {
  if (acceptedHunks.length === 0) {
    return baselineContent;
  }

  const patchObj: StructuredPatch = {
    oldFileName: relativePath,
    newFileName: relativePath,
    oldHeader: '',
    newHeader: '',
    hunks: acceptedHunks,
  };

  const patchString = formatPatch(patchObj);
  return applyPatch(baselineContent, patchString);
}

/**
 * Find the first actually changed line (+ or -) in a hunk.
 * Returns a 0-indexed line number in the current file.
 * Falls back to hunk start if no changed lines found.
 */
export function getFirstChangedLine(hunk: StructuredPatchHunk): number {
  let currentLine = hunk.newStart - 1; // 0-indexed

  for (const line of hunk.lines) {
    const prefix = line[0];
    if (prefix === '+') {
      return currentLine;
    } else if (prefix === '-') {
      // Deleted line — this position is where the deletion happened
      return currentLine;
    } else {
      currentLine++;
    }
  }

  return hunk.newStart - 1;
}

/**
 * Get the range of only the actual changed lines (+ or -) in a hunk,
 * excluding context lines. Returns 0-indexed, endLine exclusive.
 */
export function getChangedLineRange(hunk: StructuredPatchHunk): { startLine: number; endLine: number } {
  let currentLine = hunk.newStart - 1;
  let firstChanged = -1;
  let lastChanged = -1;

  for (const line of hunk.lines) {
    const prefix = line[0];
    if (prefix === '+') {
      if (firstChanged === -1) {
        firstChanged = currentLine;
      }
      lastChanged = currentLine;
      currentLine++;
    } else if (prefix === '-') {
      if (firstChanged === -1) {
        firstChanged = currentLine;
      }
      lastChanged = currentLine;
      // Removed lines don't advance currentLine
    } else {
      currentLine++;
    }
  }

  if (firstChanged === -1) {
    return { startLine: hunk.newStart - 1, endLine: hunk.newStart - 1 + hunk.newLines };
  }

  return { startLine: firstChanged, endLine: lastChanged + 1 };
}

