# Cherry Diff — Agent Handover

## Purpose

Cherry Diff is a VS Code extension for reviewing file edits one hunk at a time. It is deliberately agent-agnostic: it watches workspace file changes and never requires an AI tool to integrate with, call, or know about the extension.

Core principles:

- **Agent-agnostic** — observes normal editor and filesystem events
- **No Git dependency** — rejection uses extension-owned baseline snapshots
- **Explicit activation** — tracking starts only after the user presses Start Tracking
- **No background focus changes** — reviews update the sidebar but never auto-open an editor
- **Byte-safe restoration** — binary and unsupported text files are restored from exact bytes

## Current development state

The package version is `0.7.1`. Unreleased fixes handle folder events before filtering their children.

Implemented behavior:

- Explicit Start/Stop Tracking controls
- Disk-backed, path-addressed baseline snapshots
- Configurable bounded baseline capture concurrency
- Revisioned filesystem change tracking
- Incremental review refresh for dirty resources only
- Per-hunk accept/reject for UTF-8 text
- Whole-file accept/reject for binary, unsupported, very large, or overly complex diffs
- Explorer-style Tracked Files tree with recursive checkboxes
- Workspace-root-scoped visual selections for multi-root workspaces
- Native VS Code diff editors for safe text reviews
- Automatic review refresh with an 800 ms debounce
- Cancellation and bounded retries during baseline preparation

## Project structure

```text
src/
├── extension.ts                Activation, views, commands, context keys
├── constants.ts                Shared operational constants
├── async.ts                    Shared SerialQueue and Debouncer primitives
├── trackingController.ts       Serialized tracking-session lifecycle
├── baselineCaptureService.ts   Discovery, traversal, capture workers, retries
├── baselineService.ts          Disk-backed snapshot index and blob storage
├── fileSnapshot.ts             Stable byte reads and UTF-8/BOM classification
├── changeTracker.ts            Revisioned editor/filesystem events
├── filterService.ts            Cached glob matching and workspace-scoped overrides
├── filterTreeProvider.ts       Tracked Files checkbox tree
├── reviewManager.ts            Incremental review and accept/reject operations
├── diffService.ts              Structured diff and patch helpers
├── reviewTreeProvider.ts       Review TreeView items
├── baselineContentProvider.ts  Virtual diff documents and diff opening
├── controlsViewProvider.ts     Controls WebviewView
└── types.ts                    Review domain types

test/
├── baselineCaptureService.test.js
├── baselineService.test.js
├── changeTracker.test.js
├── diffService.test.js
├── filterService.test.js
└── reviewManager.test.js
```

`trackingController.test.js` covers operation ordering. `trackingRecovery.test.js` uses the shared in-memory workspace in `test/helpers/workspace.js` to cover directory events and filtered descendants.

## Core invariants

### Tracking session

1. Extension activation does not capture files or install tracking watchers.
2. Start Tracking installs watchers before baseline discovery begins.
3. Changes observed during capture are drained and recaptured before tracking becomes active.
4. Capture has bounded retries; an incomplete or unstable baseline set never becomes active.
5. Stop Tracking invalidates the session immediately, waits behind any active serialized operation, clears reviews, and deletes that session's snapshot store.
6. Each extension host uses a unique baseline-session directory so concurrent windows do not clear one another's data.

### Baseline identity and safety

- Resources are keyed by full URI strings, not `fsPath`.
- Existing files are captured as exact bytes.
- A missing baseline entry is interpreted as a newly created file only after the initial baseline set is marked complete.
- No `findFiles()` result cap is used; silent truncation is forbidden.
- Empty Cherry Diff excludes pass `null` to `findFiles()` so VS Code's unrelated `files.exclude` setting is not applied implicitly.
- Snapshot writes are path-addressed by a SHA-256 hash of the resource URI. Content deduplication and reference counting are intentionally not used.

### Text and binary handling

`fileSnapshot.ts` classifies bytes as:

- UTF-8
- UTF-8 with BOM
- Binary or unsupported encoding

Open UTF-8 documents are captured from their in-memory text so unsaved edits are preserved. Baseline bytes retain BOM information.

Binary and unsupported files receive one whole-file review hunk. They are never decoded and rewritten as UTF-8. Large text files and diffs that exceed the configured edit bound also fall back to a whole-file review.

### Review consistency

- `ChangeTracker` gives every event a monotonically increasing revision.
- `ReviewManager.refreshDirty()` processes only dirty resources.
- A review acknowledges an event only if its revision is still current after asynchronous reads.
- Unrelated existing reviews retain their hunk IDs and tree state.
- Before accepting or rejecting, the current file is reread and compared with the reviewed snapshot.
- If the file changed after review preparation, the operation is refused and the review is refreshed.
- Failed edits or deletions leave the review pending.
- Create/delete events retain their structural origin when coalesced and reach directory expansion before file inclusion checks.

### Operation serialization

`TrackingController` owns one promise queue for all state-changing work:

- Initialization
- Filter synchronization
- Review refresh
- Accept/reject operations
- Stop and cleanup

Session generations provide cancellation. Timers only enqueue work and always handle failures.

## Filtering model

Filter precedence is:

1. Nearest visual file/directory override
2. `cherryDiff.excludePaths`
3. `cherryDiff.includePaths`

An unchecked override always excludes its subtree. A checked override includes it, with one refinement: by default (`cherryDiff.checkedDirectoriesOverrideExcludes` = `false`) a checked ancestor directory does not re-include descendants matching `cherryDiff.excludePaths`, so re-checking a directory cannot drag in `node_modules`-style noise. An override on the exact file being tested is always a deliberate inclusion and beats excludes. Enabling the setting restores unconditional subtree inclusion.

Glob patterns are compiled once with `minimatch`; brace expansion, character classes, `**`, `*`, and `?` share one matcher implementation.

Visual selections are stored in `ExtensionContext.workspaceState`, not `.vscode/settings.json`. This prevents checkbox use from modifying the repository or creating a Cherry Diff review for its own setting change.

Override keys include the workspace-root URI, so equal relative paths in separate workspace roots remain independent. Directory selections remove redundant descendant overrides. Symbolic-link directories are shown but never recursively traversed.

Changing include/exclude settings while tracking performs serialized incremental baseline synchronization. Changing filters during initial preparation cancels the incomplete session and requires tracking to be started again.

## Main flows

### Startup

```text
Open Cherry Diff view or invoke command
  → activate extension lazily
  → register views, commands, providers
  → set tracking contexts false
  → wait for explicit Start Tracking
```

### Start Tracking

```text
Start Tracking
  → begin initialization and install watchers
  → clear this session's snapshot directory
  → discover every included file without a result cap
  → capture stable byte snapshots with bounded workers
  → drain changes observed during capture
  → mark baseline set complete
  → switch existing watchers to normal tracking
```

### Change review

```text
Editor/filesystem event
  → FilterService inclusion check
  → record URI + kind + revision
  → debounce
  → serialized directory-event expansion
  → ReviewManager.refreshDirty()
  → load one baseline and current snapshot
  → commit only if revision is still current
  → update Review tree, badge, context keys, Controls
```

### Accept

- Text hunk: apply only that hunk to the baseline text and persist the new baseline bytes.
- Whole file: set the baseline to the current exact snapshot.
- The current workspace file is not rewritten.

### Reject

- Reread and verify the current file first.
- Text hunk: reconstruct the file from the baseline plus all other pending hunks.
- Whole file: restore exact baseline bytes or baseline nonexistence.
- Check `WorkspaceEdit.applyEdit()` results and retain the review on failure.

## Diff documents

`ReviewContentProvider` is parameterized for baseline and deleted-current content. Virtual URI queries retain the complete source URI string.

Diff tabs are closed by matching `TabInputTextDiff.original` URIs rather than display labels. Hunk scrolling still uses a short render delay, but the callback verifies that the active editor belongs to the requested diff before moving selection.

Binary and whole-file fallback reviews do not open a potentially expensive or lossy text diff.

## Configuration

| Setting | Type | Default | Purpose |
|---|---|---:|---|
| `cherryDiff.autoSave` | boolean | `true` | Save dirty text documents after resolution |
| `cherryDiff.baselineCaptureConcurrency` | integer | `12` | Concurrent captures, clamped to 1–64 |
| `cherryDiff.includePaths` | string[] | `["**/*"]` | Default included paths |
| `cherryDiff.excludePaths` | string[] | 27 defaults | Default excluded paths |
| `cherryDiff.checkedDirectoriesOverrideExcludes` | boolean | `false` | Checked directories re-include even `excludePaths` matches |

Visual path selections are internal workspace state, not a public configuration setting.

## Commands and views

Views:

- `cherryDiffControls` — tracking and bulk actions
- `cherryDiffReview` — reviewed files and hunks
- `cherryDiffFilters` — workspace-root-aware checkbox tree

Important commands:

- `cherryDiff.enableTracking`
- `cherryDiff.disableTracking`
- `cherryDiff.startReview` — retained ID; displayed as Refresh Review
- `cherryDiff.acceptHunk` / `cherryDiff.rejectHunk`
- `cherryDiff.acceptAllFile` / `cherryDiff.rejectAllFile`
- `cherryDiff.acceptAll` / `cherryDiff.rejectAll`
- `cherryDiff.clearPathOverrides`
- `cherryDiff.nextHunk` / `cherryDiff.prevHunk`

## Remaining limitations

1. Baseline indexes are session-only and intentionally not restored after reload.
2. A process crash can leave an orphaned unique session directory in extension storage.
3. There is no extension-owned undo history after accepting or rejecting.
4. Directory renames are represented through create/delete events rather than rename identity.
5. Symbolic-link directories are not traversed recursively.
6. Initial tracking must still read and snapshot every included file.
7. Binary and unsupported encodings support whole-file resolution only.
8. Very large or pathologically different text files support whole-file resolution only.

## Development

```bash
npm install
npm run compile
npm run lint
npm test
npm run check
```

`npm run compile` cleans `out/` before compiling so stale generated files cannot survive source removal.

Runtime dependencies:

- `diff` — structured text patches
- `minimatch` — cached glob semantics

Shared operational constants belong in `src/constants.ts`; do not introduce module-local configuration constants.
