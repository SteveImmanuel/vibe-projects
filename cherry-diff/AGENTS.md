# Cherry Diff — Agent Handover Document

## What is this project?

**Cherry Diff** is a VS Code extension that provides **per-hunk accept/reject** for file edits — the same UX that exists in Cursor and GitHub Copilot's Agent mode, but as a standalone, agent-agnostic extension that works with any AI coding tool (Claude Code, Cline, Roo Code, Aider, etc.) or even manual edits.

The core idea: instead of accepting or rejecting an entire file's changes at once, the user can review each discrete "hunk" (section of change) individually, accepting some and rejecting others.

**Key design principles:**
- **Agent-agnostic** — doesn't hook into any specific AI agent; watches file changes at the workspace level
- **No Git dependency** — works with any project, Git or not. Uses extension-owned disk snapshots, not VCS history
- **Marketplace-publishable** — uses only stable, public VS Code APIs (no proposed APIs)
- **Non-invasive** — no inline editor UI (no CodeLens, no decorations). All review happens in a dedicated sidebar panel + VS Code's native diff editor

## Current state (v0.5.0)

Working MVP. Core features implemented:
- Tracks file changes (create, modify, delete) with configurable include/exclude glob filters
- Computes per-hunk diffs using the `diff` npm package
- **Controls panel** (WebviewView) with buttons: Refresh, Stop Tracking, Accept All (green), Reject All (red), Filters
- **Review panel** (TreeView) shows files and their hunks with inline Accept/Reject buttons
- **Tracked Files panel** provides an Explorer-style workspace tree with include/exclude checkboxes
- Clicking a hunk opens VS Code's native diff editor (baseline vs current) scrolled to the relevant line
- Accept advances the baseline; Reject rewrites the file without that hunk
- Auto-save after accept/reject (configurable via `cherryDiff.autoSave`)
- Handles edge cases: new files (reject deletes), deleted files (reject recreates), empty files
- Badge on the activity bar icon shows number of changed files
- Auto-refreshes sidebar when files change (800ms debounce)
- Hunk labels show only actual changed lines, not context (e.g. "line 42" for single-line, "lines 42-50" for multi-line)
- Diff tabs auto-close when a file's review is complete without auto-opening another file or stealing editor focus
- Baseline contents are stored as content-addressed blobs in extension storage and loaded into memory only for changed files
- File watchers run during baseline initialization; files changed during capture are recaptured before tracking becomes active

## Project structure

```
cherry-diff/
├── package.json              — VS Code extension manifest (commands, menus, views, config)
├── tsconfig.json             — TypeScript config (target ES2022, commonjs modules)
├── LICENSE                   — MIT license
├── .gitignore
├── .vscodeignore             — Excludes src/, .vscode/, tsconfig from VSIX package
├── assets/
│   ├── icon.png              — Extension icon (PNG for Marketplace)
│   └── icon.svg              — Extension icon (SVG source)
├── .vscode/
│   ├── launch.json           — F5 launches Extension Development Host
│   └── tasks.json            — npm watch as build task
├── src/
│   ├── types.ts              — Shared type definitions
│   ├── extension.ts          — Entry point: activation, command registration, wiring
│   ├── baselineService.ts    — Disk-backed, content-addressed baseline storage
│   ├── changeTracker.ts      — Workspace file change watcher with path filtering
│   ├── filterService.ts      — Glob evaluation and nearest-path checkbox overrides
│   ├── filterTreeProvider.ts — Explorer-style include/exclude checkbox tree
│   ├── diffService.ts        — Diff computation and hunk manipulation (wraps `diff` npm)
│   ├── reviewManager.ts      — Orchestrates review: diff computation, accept/reject logic
│   ├── controlsViewProvider.ts — WebviewView for Controls panel (buttons + status)
│   ├── reviewTreeProvider.ts — TreeView for Review panel (files → hunks hierarchy)
│   └── baselineContentProvider.ts — Virtual document providers for diff editor
├── out/                      — Compiled JS (generated, gitignored)
└── node_modules/             — Dependencies (gitignored)
```

## Architecture and data flow

### Startup sequence

1. `activate()` in `extension.ts` runs on `onStartupFinished`
2. `BaselineService` is created with a session directory under `ExtensionContext.storageUri`
3. `ChangeTracker.beginInitialization()` installs text-document and filesystem watchers before capture starts
4. `captureFilteredBaselines()` finds included files and snapshots up to 12 concurrently as SHA-256-addressed blobs
5. Changes observed during capture are drained and recaptured; `finishInitialization()` then switches the existing watchers to normal tracking
6. Virtual document providers, the Controls WebviewView, and Review TreeView are registered
7. Commands and event listeners are wired up

### Change detection flow

```
File edit → ChangeTracker.shouldTrack(uri) → glob filter check
  → if passes: add to changedFiles set, fire onDidChangeTrackedFiles
    → debounced (800ms): ReviewManager.startReview()
      → for each changed file: load its baseline blob, get current content, compute diff
      → populate fileReviews map with hunks
      → fire onDidChangeReview → TreeView updates, badge updates, Controls panel updates
```

### Accept flow

```
User clicks ✓ on hunk in sidebar
  → ReviewManager.acceptHunk(fsPath, hunkId)
    → Apply just this hunk to the baseline → new baseline includes this change
    → Re-diff current content against updated baseline
    → Remaining hunks (if any) get new IDs and positions
    → File on disk is NOT modified (change is already there)
    → Auto-save if enabled (cherryDiff.autoSave setting)
    → If all hunks resolved: remove file from changed files set
```

### Reject flow

```
User clicks ✗ on hunk in sidebar
  → ReviewManager.rejectHunk(fsPath, hunkId)
    → Build keepHunks = all hunks except the rejected one
    → reconstructFile(baseline, keepHunks) → new file content
    → Write new content to disk (via writeFileContent helper)
    → Re-diff to get updated positions for remaining hunks
    → Auto-save if enabled
    → If all hunks resolved: remove file from changed files set
```

### Reject/accept edge cases

| Scenario | Accept | Reject |
|---|---|---|
| **Modified file** | Advances baseline, file unchanged | Rewrites file without the hunk |
| **New file** (no baseline) | Confirms new file, sets baseline | Deletes the file |
| **Deleted file** (no current) | Confirms deletion | Recreates file from baseline |

### Diff view

When the user clicks a file or hunk in the sidebar, the extension opens VS Code's native diff editor:
- **Left pane**: baseline content, served by `BaselineContentProvider` via `cherry-diff-baseline:` URI scheme
- **Right pane**: current file on disk (or `CurrentContentProvider` via `cherry-diff-current:` for deleted files)
- For hunk clicks, the editor scrolls to the hunk's first changed line (200ms delay to let the diff editor render)

## Key types

### `HunkReview` (types.ts)
```typescript
interface HunkReview {
  id: string;           // Unique ID like "hunk_42", generated sequentially
  hunk: Hunk;           // From `diff` npm package — contains lines, oldStart, newStart, etc.
  status: HunkStatus;   // 'pending' | 'accepted' | 'rejected'
}
```

### `FileReview` (types.ts)
```typescript
interface FileReview {
  uri: vscode.Uri;
  relativePath: string;
  baselineContent: string;   // Loaded only after the file enters review
  baselineExists: boolean;   // Distinguishes an empty file from a missing file
  currentContent: string;    // What the file looks like now on disk
  currentExists: boolean;    // Distinguishes an empty file from a missing file
  hunks: HunkReview[];       // Parsed diff hunks between baseline and current
}
```

## Module details

### `baselineService.ts`
Stores baseline bytes as SHA-256-addressed blobs under `ExtensionContext.storageUri/baseline-session/blobs`. Memory holds only a path index containing existence, blob hash, size, and modification time. `captureBaseline()` reads through `workspace.fs` without opening every file as a VS Code document, while already-open documents are captured from their current text so unsaved state is preserved. `getSnapshot()` loads and decodes one blob only when its file enters review. The store is session-scoped and cleared when tracking is reset, disabled, or started in a new extension-host session.

### `changeTracker.ts`
Watches for file changes using:
- `vscode.workspace.onDidChangeTextDocument` — for in-editor edits
- `vscode.workspace.createFileSystemWatcher('**/*')` — for external writes (agent CLI tools), file creation, and deletion (`onDidDelete`)

Each change goes through `shouldTrack(uri)`, which first applies the nearest ancestor or exact entry from `cherryDiff.pathOverrides`. If there is no explicit selection, it checks `cherryDiff.excludePaths` first and then `cherryDiff.includePaths`.

**Glob matching** is implemented manually with a character-by-character parser that converts glob patterns to regex. Supports `**` (any path segments), `*` (anything except `/`), `?` (single non-`/` char). Automated tests cover root, nested, excluded, wildcard, and Windows-style paths.

During startup or baseline reset, changes go into a separate initialization set. The capture pipeline drains this set before atomically switching the already-installed watchers to normal tracking. Also provides `removeChangedFile(fsPath)` to clean up files that no longer have pending hunks after accept/reject.

### `filterService.ts` and `filterTreeProvider.ts`
`FilterTreeProvider` lazily reads workspace directories and renders an Explorer-style tree in the `cherryDiffFilters` view. Checked entries are included and unchecked entries are excluded. Directory selections apply recursively by storing a path override and removing redundant descendant overrides. `filterService.ts` resolves the nearest override before falling back to include/exclude globs. Newly included paths are captured into the existing baseline store without resetting unrelated reviews; excluded paths are removed from baseline storage and the review is recomputed.

### `diffService.ts`
Wraps the `diff` npm package. Key functions:

- `computeHunks(relativePath, baseline, current)` → `HunkReview[]` — uses `structuredPatch()` to get hunks
- `reconstructFile(relativePath, baseline, hunks)` → `string | false` — uses `formatPatch()` + `applyPatch()` to rebuild a file from baseline + selected hunks
- `getFirstChangedLine(hunk)` → `number` — first `+` or `-` line (used for scroll-to-hunk)
- `getChangedLineRange(hunk)` → `{ startLine, endLine }` — range of only actual changed lines, excluding context (used for hunk labels in TreeView)

**Important**: hunk IDs are generated with a global counter (`hunk_0`, `hunk_1`, ...) that never resets. After accept/reject, hunks are recomputed and get new IDs. This means hunk IDs are ephemeral — never persist them.

### `reviewManager.ts`
Central orchestrator. Key behaviors:

- **`startReview()`**: Clears existing reviews, iterates all changed files, lazily loads each changed file's baseline blob, and computes diffs. Explicit existence flags distinguish missing files from empty files.
- **`acceptHunk()`**: Applies the accepted hunk to the baseline (advancing it forward), then re-diffs current vs new baseline. The file on disk is NOT modified. Auto-saves if enabled.
- **`rejectHunk()`**: Reconstructs the file without the rejected hunk and writes it to disk. Then re-diffs. Auto-saves if enabled.
- **`setAllHunksInFile()`**: Accept all = advance baseline to current content. Reject all = rewrite file to baseline. Auto-saves if enabled.
- **`writeFileContent(uri, content, shouldExist)`**: Private helper that keeps file existence separate from content, deletes rejected new files, recreates rejected deletions, and preserves legitimate empty files.
- **`autoSave()`**: Private helper that saves the file if `cherryDiff.autoSave` is true and the document is dirty.
- **`applying` flag**: Set to `true` during file writes to prevent the auto-refresh debounce from triggering a re-review mid-write (which would cause infinite loops).

### `controlsViewProvider.ts`
WebviewView that renders the **Controls** section at the top of the Cherry Diff sidebar. Uses HTML/CSS with VS Code theme variables for native look. Shows:
- **Status line**: "Tracking active · N files changed · M hunks pending"
- **Row 1**: Stop Tracking (full width, dark red) — or Start Tracking when disabled
- **Row 2**: Refresh (primary) + Filters (secondary)
- **Row 3**: Accept All (green) + Reject All (red)

All buttons have tooltip text on hover. Communicates with extension.ts via `webviewView.webview.onDidReceiveMessage()`. The view updates when tracking state, changed files, or review state changes.

### `reviewTreeProvider.ts`
Two-level TreeView: files at the root, hunks as children.

- `FileTreeItem`: shows relative path, hunk count, click opens diff view. `contextValue = 'file'` enables file-level inline menu buttons (Accept All, Reject All).
- `HunkTreeItem`: shows "Hunk N: line X" (single line) or "Hunk N: lines X-Y" (range), using `getChangedLineRange()` to show only actual changed lines (not context). Click opens diff at that line. `contextValue = 'hunk'` enables hunk-level inline buttons (Accept, Reject). Carries `fsPath` and `hunkId` for command handlers.

### `baselineContentProvider.ts`
Two `TextDocumentContentProvider` implementations:

- `BaselineContentProvider` — serves baseline content for `cherry-diff-baseline:` URIs. Used as the left pane of the diff editor.
- `CurrentContentProvider` — serves current content for `cherry-diff-current:` URIs. Only used for deleted files where the right pane can't open the real file.

Both refresh when `onDidChangeReview` fires (so the diff editor updates after accept/reject).

`openDiffForFile(fsPath, line?)` is the shared function that opens `vscode.diff` with the correct URIs, handling the deleted-file case by switching the right-side URI to the virtual provider. Optionally scrolls to a specific line (200ms delay).

### `extension.ts`
Wiring and command registration. Notable details:

- **Auto-refresh**: `changeTracker.onDidChangeTrackedFiles` → debounced 800ms → `reviewManager.startReview()` (skipped if `applying` flag is set)
- **Badge**: `treeView.badge = { value: fileCount, tooltip: "..." }` or `undefined` when 0. Shows number of changed files (not hunks).
- **Changed files sync**: On `onDidChangeReview`, files no longer in the review are removed from the changed files set (so the Controls panel count stays accurate)
- **Diff tab lifecycle**: Tracks `previousReviewFiles` set. When a file is resolved (removed from review), its diff tab is closed via `closeDiffTab()`. Other files are never auto-opened, so background review updates do not steal editor focus.
- **`closeDiffTab(fsPath)`**: Finds the diff tab by matching the label pattern `"relativePath (Baseline ↔ Current)"` and closes it via `vscode.window.tabGroups.close()`.
- **Context keys**: `cherryDiff.tracking` (controls play/stop button visibility), `cherryDiff.reviewActive`
- **Initialization pipeline**: installs watchers first, clears the session blob store, finds and captures filtered files with bounded concurrency, drains paths changed during capture, then enables normal tracking
- **`cherryDiff.resetBaseline`** command (labeled "Accept All" in UI): clears review, clears changed files, and recaptures baselines from current state

## VS Code extension manifest (package.json)

### Commands
| Command ID | Title | Icon | Where it appears |
|---|---|---|---|
| `cherryDiff.startReview` | Start Review | `$(refresh)` | Controls webview |
| `cherryDiff.enableTracking` | Enable Tracking | `$(play)` | Controls webview |
| `cherryDiff.disableTracking` | Disable Tracking | `$(debug-stop)` | Controls webview |
| `cherryDiff.resetBaseline` | Accept All | `$(discard)` | Controls webview |
| `cherryDiff.editFilters` | Show Tracked Files | `$(filter)` | Controls webview |
| `cherryDiff.acceptHunk` | Accept Hunk | `$(check)` | Hunk item inline |
| `cherryDiff.rejectHunk` | Reject Hunk | `$(x)` | Hunk item inline |
| `cherryDiff.acceptAllFile` | Accept All in File | `$(check-all)` | File item inline |
| `cherryDiff.rejectAllFile` | Reject All in File | `$(close-all)` | File item inline |
| `cherryDiff.acceptAll` | Accept All | — | Command palette only |
| `cherryDiff.rejectAll` | Reject All | — | Command palette only |
| `cherryDiff.openDiff` | Open Diff View | `$(diff)` | Tree item click |
| `cherryDiff.openDiffAtLine` | (internal) | — | Hunk tree item click |
| `cherryDiff.nextHunk` | Next Hunk | — | `Alt+]` keybinding |
| `cherryDiff.prevHunk` | Previous Hunk | — | `Alt+[` keybinding |

### Configuration
| Setting | Type | Default | Description |
|---|---|---|---|
| `cherryDiff.autoSave` | `boolean` | `true` | Auto-save files after accept/reject |
| `cherryDiff.includePaths` | `string[]` | `["**/*"]` | Glob patterns to include |
| `cherryDiff.excludePaths` | `string[]` | (27 patterns) | Glob patterns to exclude |
| `cherryDiff.pathOverrides` | `object` | `{}` | Per-path checkbox selections managed by the Tracked Files tree |

Default excludes cover: node_modules, .venv, __pycache__, .git, .hg, .svn, dist, build, out, .next, .nuxt, coverage, .cache, .tox, .mypy_cache, .pytest_cache, vendor, target, *.min.js, *.min.css, and common lock files (package-lock.json, yarn.lock, pnpm-lock.yaml, Cargo.lock, poetry.lock, Pipfile.lock, go.sum).

### Views
- Activity bar container: `cherryDiff` with `$(diff)` icon
- **Controls** (`cherryDiffControls`): WebviewView with buttons and status — appears at the top
- **Review** (`cherryDiffReview`): TreeView with file/hunk hierarchy — appears below Controls
- **Tracked Files** (`cherryDiffFilters`): Explorer-style file hierarchy with include/exclude checkboxes — appears at the bottom
- Welcome messages for empty Review states (tracking on: "No changes to review", tracking off: "Tracking is disabled")

## Baseline model

The baseline is **the file's content at the moment tracking was enabled** (extension startup by default). Contents live in extension storage as session-scoped blobs; only the lightweight index and baselines for files currently under review live in memory.

- **Accept** advances the baseline forward (baseline now includes the accepted change)
- **Reject** does not change the baseline (the file is rewritten to remove the rejected change)
- **Accept All** recaptures all file contents as-is, clearing all pending reviews
- **Disable tracking** clears all baselines
- **Enable tracking** recaptures all baselines from current file state
- Edits made while tracking is disabled are invisible (baked into the new baseline when re-enabled)
- New files (no baseline captured at startup) are treated as having an empty baseline — the entire file shows as "added"
- Deleted files (file removed after baseline capture) are treated as having empty current content — the entire file shows as "removed"

## Known limitations and potential improvements

1. **Session-only index** — blobs use `context.storageUri`, but the path index is intentionally not restored after reload; current state is recaptured for a new tracking session.
2. **No undo** — once you accept or reject, there's no way to undo within the extension. The user would need to use VS Code's undo or git.
3. **Startup I/O** — agent-agnostic rejection requires original bytes to be captured before arbitrary external writes. Disk-backed blobs remove workspace-sized memory usage, but the initial snapshot still reads all included files.
4. **Hunk ID instability** — IDs are regenerated on every re-diff. This can cause the TreeView to flicker/collapse after accept/reject.
5. **Diff editor scroll** — the 200ms setTimeout for scrolling to a hunk line is fragile. Could use a more reliable approach.
6. **No rename detection** — file renames show up as a delete + create, not a rename.
7. **Global hunk counter** — `nextHunkId` never resets, could overflow in very long sessions (unlikely in practice).
8. **Single-repo assumption** — `ChangeTracker` doesn't scope to specific workspace folders.
9. **Controls panel size** — the WebviewView `initialSize` is set to 1, but VS Code may not always respect this; the user might need to resize manually.

## Development

```bash
# Install dependencies
npm install

# Compile
npm run compile

# Watch mode (auto-recompile on save)
npm run watch

# Run in VS Code
# Press F5 to launch Extension Development Host

# Package as .vsix
npx @vscode/vsce package
```

## Dependencies

- **Runtime**: `diff` (v7) — the only runtime dependency. Provides `structuredPatch`, `applyPatch`, `formatPatch`.
- **Dev**: `@types/vscode`, `@types/diff`, `@types/node`, `typescript`, `eslint`
