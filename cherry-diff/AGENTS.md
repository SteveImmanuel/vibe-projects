# Cherry Diff — Agent Handover Document

## What is this project?

**Cherry Diff** is a VS Code extension that provides **per-hunk accept/reject** for file edits — the same UX that exists in Cursor and GitHub Copilot's Agent mode, but as a standalone, agent-agnostic extension that works with any AI coding tool (Claude Code, Cline, Roo Code, Aider, etc.) or even manual edits.

The core idea: instead of accepting or rejecting an entire file's changes at once, the user can review each discrete "hunk" (section of change) individually, accepting some and rejecting others.

**Key design principles:**
- **Agent-agnostic** — doesn't hook into any specific AI agent; watches file changes at the workspace level
- **No Git dependency** — works with any project, Git or not. Uses in-memory baselines, not VCS history
- **Marketplace-publishable** — uses only stable, public VS Code APIs (no proposed APIs)
- **Non-invasive** — no inline editor UI (no CodeLens, no decorations). All review happens in a dedicated sidebar panel + VS Code's native diff editor

## Current state (v0.1.0)

Working MVP. Core features implemented:
- Tracks file changes (create, modify, delete) with configurable include/exclude glob filters
- Computes per-hunk diffs using the `diff` npm package
- Sidebar TreeView shows files and their hunks with inline Accept/Reject buttons
- Clicking a hunk opens VS Code's native diff editor (baseline vs current) scrolled to the relevant line
- Accept advances the baseline; Reject rewrites the file without that hunk
- Handles edge cases: new files, deleted files, empty files
- Badge on the activity bar icon shows pending hunk count
- Auto-refreshes when files change (800ms debounce)

## Project structure

```
cherry-diff/
├── package.json              — VS Code extension manifest (commands, menus, views, config)
├── tsconfig.json             — TypeScript config (target ES2022, commonjs modules)
├── .gitignore
├── .vscode/
│   ├── launch.json           — F5 launches Extension Development Host
│   └── tasks.json            — npm watch as build task
├── src/
│   ├── types.ts              — Shared type definitions
│   ├── extension.ts          — Entry point: activation, command registration, wiring
│   ├── baselineService.ts    — In-memory file snapshot storage
│   ├── changeTracker.ts      — Workspace file change watcher with glob filtering
│   ├── diffService.ts        — Diff computation and hunk manipulation (wraps `diff` npm)
│   ├── reviewManager.ts      — Orchestrates review: diff computation, accept/reject logic
│   ├── reviewTreeProvider.ts — Sidebar TreeView (files → hunks hierarchy)
│   └── baselineContentProvider.ts — Virtual document providers for diff editor
├── out/                      — Compiled JS (generated, gitignored)
└── node_modules/             — Dependencies (gitignored)
```

## Architecture and data flow

### Startup sequence

1. `activate()` in `extension.ts` runs on `onStartupFinished`
2. `BaselineService` is created (empty map)
3. `captureFilteredBaselines()` reads `cherryDiff.includePaths` / `cherryDiff.excludePaths` from settings, uses `vscode.workspace.findFiles()` to find matching files, and captures each file's current content as its baseline
4. `ChangeTracker.startTracking()` sets up watchers for file changes (text document changes + filesystem watcher for create/modify/delete)
5. Virtual document providers are registered for `cherry-diff-baseline:` and `cherry-diff-current:` URI schemes
6. TreeView, commands, and event listeners are wired up

### Change detection flow

```
File edit → ChangeTracker.shouldTrack(uri) → glob filter check
  → if passes: add to changedFiles set, fire onDidChangeTrackedFiles
    → debounced (800ms): ReviewManager.startReview()
      → for each changed file: get baseline, get current content, compute diff
      → populate fileReviews map with hunks
      → fire onDidChangeReview → TreeView updates, badge updates
```

### Accept flow

```
User clicks ✓ on hunk in sidebar
  → ReviewManager.acceptHunk(fsPath, hunkId)
    → Apply just this hunk to the baseline → new baseline includes this change
    → Re-diff current content against updated baseline
    → Remaining hunks (if any) get new IDs and positions
    → File on disk is NOT modified (change is already there)
```

### Reject flow

```
User clicks ✗ on hunk in sidebar
  → ReviewManager.rejectHunk(fsPath, hunkId)
    → Build keepHunks = all hunks except the rejected one
    → reconstructFile(baseline, keepHunks) → new file content
    → Write new content to disk (via writeFileContent helper)
    → Re-diff to get updated positions for remaining hunks
```

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
  baselineContent: string;   // What the file looked like when tracking started (or after accepts)
  currentContent: string;    // What the file looks like now on disk
  hunks: HunkReview[];       // Parsed diff hunks between baseline and current
}
```

## Module details

### `baselineService.ts`
Simple `Map<string, string>` (fsPath → content). Methods: `captureBaseline(uri)`, `getBaseline(fsPath)`, `updateBaseline(fsPath, content)`, `clearBaselines()`. No persistence — baselines live in memory only and are recaptured when tracking is re-enabled.

### `changeTracker.ts`
Watches for file changes using:
- `vscode.workspace.onDidChangeTextDocument` — for in-editor edits
- `vscode.workspace.createFileSystemWatcher('**/*')` — for external writes (agent CLI tools), file creation, and deletion

Each change goes through `shouldTrack(uri)` which checks the file's relative path against `cherryDiff.excludePaths` (checked first, any match → exclude) then `cherryDiff.includePaths` (any match → include, else exclude).

**Glob matching** is implemented manually (not using any library) with a character-by-character parser that converts glob patterns to regex. Supports `**` (any path segments), `*` (anything except `/`), `?` (single non-`/` char). This was necessary because the `shouldTrack` check runs synchronously per file change event and we didn't want to add a dependency just for glob matching.

### `diffService.ts`
Wraps the `diff` npm package. Key functions:

- `computeHunks(relativePath, baseline, current)` → `HunkReview[]` — uses `structuredPatch()` to get hunks
- `reconstructFile(relativePath, baseline, hunks)` → `string | false` — uses `formatPatch()` + `applyPatch()` to rebuild a file from baseline + selected hunks
- `getHunkCurrentRange(hunk)` → `{ startLine, endLine }` — 0-indexed line range in the current file
- `getFirstChangedLine(hunk)` → `number` — first `+` or `-` line (used for scroll-to-hunk)
- `classifyHunkLines(hunk)` → `{ added, removed, context }` — categorizes each line (currently unused but available)

**Important**: hunk IDs are generated with a global counter (`hunk_0`, `hunk_1`, ...) that never resets. After accept/reject, hunks are recomputed and get new IDs. This means hunk IDs are ephemeral — never persist them.

### `reviewManager.ts`
Central orchestrator. Key behaviors:

- **`startReview()`**: Clears existing reviews, iterates all changed files, computes diffs. New files get empty string as baseline. Deleted files get empty string as current content.
- **`acceptHunk()`**: Applies the accepted hunk to the baseline (advancing it forward), then re-diffs current vs new baseline. The file on disk is NOT modified.
- **`rejectHunk()`**: Reconstructs the file without the rejected hunk and writes it to disk. Then re-diffs.
- **`writeFileContent()`**: Private helper handling edge cases:
  - Normal file: opens document, creates WorkspaceEdit, replaces full range
  - Deleted file being restored: uses `vscode.workspace.fs.writeFile()` to recreate
  - New file being rejected (content becomes empty): uses `vscode.workspace.fs.delete()`
- **`applying` flag**: Set to `true` during file writes to prevent the auto-refresh debounce from triggering a re-review mid-write (which would cause infinite loops).

### `reviewTreeProvider.ts`
Two-level TreeView: files at the root, hunks as children.

- `FileTreeItem`: shows relative path, hunk count, click opens diff view. `contextValue = 'file'` enables file-level inline menu buttons.
- `HunkTreeItem`: shows "Hunk N: lines X-Y", click opens diff at that line. `contextValue = 'hunk'` enables hunk-level inline menu buttons. Carries `fsPath` and `hunkId` for command handlers.

### `baselineContentProvider.ts`
Two `TextDocumentContentProvider` implementations:

- `BaselineContentProvider` — serves baseline content for `cherry-diff-baseline:` URIs. Used as the left pane of the diff editor.
- `CurrentContentProvider` — serves current content for `cherry-diff-current:` URIs. Only used for deleted files where the right pane can't open the real file.

Both refresh when `onDidChangeReview` fires (so the diff editor updates after accept/reject).

`openDiffForFile(fsPath, line?)` is the shared function that opens `vscode.diff` with the correct URIs, handling the deleted-file case by switching the right-side URI to the virtual provider.

### `extension.ts`
Wiring and command registration. Notable details:

- Auto-refresh: `changeTracker.onDidChangeTrackedFiles` → debounced 800ms → `reviewManager.startReview()`
- Badge: `treeView.badge = { value: pendingCount, tooltip: "..." }` or `undefined` when 0
- Context keys: `cherryDiff.tracking` (controls play/stop button visibility), `cherryDiff.reviewActive`
- `captureFilteredBaselines()`: reads settings, calls `vscode.workspace.findFiles()` with include/exclude patterns, captures each file

## VS Code extension manifest (package.json)

### Commands
| Command ID | Title | Icon | Where it appears |
|---|---|---|---|
| `cherryDiff.startReview` | Start Review | `$(search)` | View title bar |
| `cherryDiff.enableTracking` | Enable Tracking | `$(play)` | View title bar (when not tracking) |
| `cherryDiff.disableTracking` | Disable Tracking | `$(debug-stop)` | View title bar (when tracking) |
| `cherryDiff.editFilters` | Edit Filters | `$(filter)` | View title bar |
| `cherryDiff.acceptHunk` | Accept Hunk | `$(check)` | Hunk item inline |
| `cherryDiff.rejectHunk` | Reject Hunk | `$(x)` | Hunk item inline |
| `cherryDiff.openDiff` | Open Diff View | `$(diff)` | Hunk + file item inline |
| `cherryDiff.acceptAllFile` | Accept All in File | `$(check-all)` | File item inline |
| `cherryDiff.rejectAllFile` | Reject All in File | `$(close-all)` | File item inline |
| `cherryDiff.acceptAll` | Accept All | — | Command palette only |
| `cherryDiff.rejectAll` | Reject All | — | Command palette only |
| `cherryDiff.nextHunk` | Next Hunk | — | `Alt+]` keybinding |
| `cherryDiff.prevHunk` | Previous Hunk | — | `Alt+[` keybinding |
| `cherryDiff.openDiffAtLine` | (internal) | — | Called by hunk tree item click |

### Configuration
| Setting | Type | Default | Description |
|---|---|---|---|
| `cherryDiff.includePaths` | `string[]` | `["**/*"]` | Glob patterns to include |
| `cherryDiff.excludePaths` | `string[]` | (27 patterns) | Glob patterns to exclude |

Default excludes cover: node_modules, .venv, __pycache__, .git, .hg, .svn, dist, build, out, .next, .nuxt, coverage, .cache, .tox, .mypy_cache, .pytest_cache, vendor, target, *.min.js, *.min.css, and common lock files.

### Views
- Activity bar container: `cherryDiff` with `$(diff)` icon
- TreeView: `cherryDiffReview` with welcome messages for empty states

## Baseline model

The baseline is **the file's content at the moment tracking was enabled** (extension startup by default). It lives in memory only.

- **Accept** advances the baseline forward (baseline now includes the accepted change)
- **Reject** does not change the baseline (the file is rewritten to remove the rejected change)
- **Disable tracking** clears all baselines
- **Enable tracking** recaptures all baselines from current file state
- Edits made while tracking is disabled are invisible (baked into the new baseline when re-enabled)

## Known limitations and potential improvements

1. **No persistence** — baselines are in memory. Reloading VS Code loses them. Could persist to extension storage.
2. **No undo** — once you accept or reject, there's no way to undo within the extension. The user would need to use VS Code's undo or git.
3. **Large files** — capturing baselines for 50,000 files at startup could be slow. Could lazy-capture (only capture when a file first changes).
4. **Hunk ID instability** — IDs are regenerated on every re-diff. This can cause the TreeView to flicker/collapse after accept/reject.
5. **Diff editor scroll** — the 200ms setTimeout for scrolling to a hunk line is fragile. Could use a more reliable approach.
6. **No rename detection** — file renames show up as a delete + create, not a rename.
7. **Global hunk counter** — `nextHunkId` never resets, could overflow in very long sessions (unlikely in practice).
8. **Single-repo assumption** — `ChangeTracker` doesn't scope to specific workspace folders.

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
```

## Dependencies

- **Runtime**: `diff` (v7) — the only runtime dependency. Provides `structuredPatch`, `applyPatch`, `formatPatch`.
- **Dev**: `@types/vscode`, `@types/diff`, `@types/node`, `typescript`, `eslint`
