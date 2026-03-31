import { structuredPatch, applyPatch, formatPatch } from 'diff';
import type { Hunk, ParsedDiff } from 'diff';
import { HunkReview } from './types';

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
  currentContent: string
): HunkReview[] {
  const patch = structuredPatch(
    relativePath,
    relativePath,
    baselineContent,
    currentContent
  );

  return patch.hunks.map((hunk) => ({
    id: generateHunkId(),
    hunk,
    status: 'pending' as const,
  }));
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
 * Compute the line range in the *current* file that a hunk covers.
 * Returns 0-indexed start line and end line (exclusive).
 */
export function getHunkCurrentRange(hunk: Hunk): { startLine: number; endLine: number } {
  const startLine = hunk.newStart - 1; // convert to 0-indexed
  const endLine = startLine + hunk.newLines;
  return { startLine, endLine };
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
 * Classify each line in a hunk as added, removed, or context.
 * Returns arrays of 0-indexed line numbers in the current file.
 */
export function classifyHunkLines(hunk: Hunk): {
  added: number[];
  removed: number[];
  context: number[];
} {
  const added: number[] = [];
  const removed: number[] = [];
  const context: number[] = [];

  let currentLine = hunk.newStart - 1; // 0-indexed

  for (const line of hunk.lines) {
    const prefix = line[0];
    if (prefix === '+') {
      added.push(currentLine);
      currentLine++;
    } else if (prefix === '-') {
      removed.push(currentLine);
      // Removed lines don't advance the current-file line counter
    } else {
      context.push(currentLine);
      currentLine++;
    }
  }

  return { added, removed, context };
}
