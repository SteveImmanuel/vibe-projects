export const DEFAULT_BASELINE_CAPTURE_CONCURRENCY = 12;
export const MAX_BASELINE_CAPTURE_CONCURRENCY = 64;
export const MAX_BASELINE_STABILITY_ATTEMPTS = 3;
export const MAX_INITIALIZATION_CHANGE_ROUNDS = 10;
export const MAX_TEXT_DIFF_BYTES = 5 * 1024 * 1024;
export const MAX_DIFF_EDIT_LENGTH = 1_000;

export const REVIEW_DEBOUNCE_MS = 800;
export const FILTER_DEBOUNCE_MS = 300;
export const FILTER_TREE_REFRESH_DEBOUNCE_MS = 500;
export const DIFF_SCROLL_DELAY_MS = 200;

export const BASELINE_DOCUMENT_SCHEME = 'cherry-diff-baseline';
export const CURRENT_DOCUMENT_SCHEME = 'cherry-diff-current';
export const BASELINE_SESSIONS_DIRECTORY = 'baseline-sessions';
export const BLOB_SHARD_PREFIX_LENGTH = 2;

export const PATH_OVERRIDES_STATE_KEY = 'cherryDiff.pathOverrides.v2';
export const FILTER_MATCH_OPTIONS = {
  dot: true,
  nocase: process.platform === 'win32',
  nonegate: true,
} as const;

export const UTF8_BOM_BYTES = [0xef, 0xbb, 0xbf] as const;
