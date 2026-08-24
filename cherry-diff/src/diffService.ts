import { structuredPatch, applyPatch, formatPatch } from 'diff';
import type { Hunk, ParsedDiff } from 'diff';
import type { HunkReview } from './types';

let nextHunkId = 0;

function generateHunkId(): string {
  return `hunk_${nextHunkId++}`;
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
): HunkReview[] {
  const patch = structuredPatch(
    relativePath,
    relativePath,
    baselineContent,
    currentContent
  );

  const hunks: HunkReview[] = patch.hunks.map((hunk) => ({
    id: generateHunkId(),
    hunk,
    status: 'pending',
    kind: 'content',
  }));

  // An empty file creation/deletion has no textual diff. Represent the
  // existence change as a synthetic hunk so it can still be reviewed.
  if (hunks.length === 0 && baselineExists !== currentExists) {
    hunks.push({
      id: generateHunkId(),
      hunk: {
        oldStart: 1,
        oldLines: 0,
        newStart: 1,
        newLines: 0,
        lines: [],
      },
      status: 'pending',
      kind: currentExists ? 'file-created' : 'file-deleted',
    });
  }

  return hunks;
}

/**
 * Given a baseline and a set of accepted hunks, reconstruct the file content
 * by applying only the accepted hunks to the baseline.
 */
export function reconstructFile(
  relativePath: string,
  baselineContent: string,
  acceptedHunks: Hunk[]
): string | false {
  if (acceptedHunks.length === 0) {
    return baselineContent;
  }

  const patchObj: ParsedDiff = {
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
export function getFirstChangedLine(hunk: Hunk): number {
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
export function getChangedLineRange(hunk: Hunk): { startLine: number; endLine: number } {
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

