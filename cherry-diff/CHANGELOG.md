# Changelog

## [Unreleased]

### Fixed
- Filter changes preserve pending new files and capture baselines only for newly included paths
- Folder create/delete events reach included children even when the folder itself does not match the filters
- Coalesced folder deletion and recreation still review replacement contents
- Periodic metadata checks recover missed filesystem events, including watcher-excluded paths
- Refresh Review and bulk resolution rescan included files instead of relying solely on recorded events
- Unstable review reads receive bounded automatic retries, cancelled when tracking stops

## [0.7.1]

### Added
- `cherryDiff.checkedDirectoriesOverrideExcludes` setting to control whether checking a directory in Tracked Files re-includes descendants matching `excludePaths`

### Changed
- Re-checking a directory now leaves `excludePaths` matches excluded by default; explicitly checked files are still always included

## [0.7.0]

### Changed
- Review change events carry the affected resource URIs, so diff tabs, virtual diff documents, badges, and counters update from one precise event
- One shared serial queue and debouncer implementation replaces per-module copies
- Directory change classification is shared and keeps baseline index scans off the common file-change path
- Baseline, change, and snapshot APIs accept URIs only

### Removed
- Test-only parallel filter implementation (`glob.ts`, `isPathIncluded`) in favor of the cached `FilterService` path
- Redundant empty-file existence hunk synthesis inside `computeHunks`
- Unused recursive and string-keyed baseline/change removal branches
- Legacy `pathOverrides` settings-to-workspace-state migration
- Hidden `cherryDiff.resetBaseline` compatibility alias
- Redundant `activationEvents` entries that VS Code generates automatically

### Fixed
- Controls panel no longer writes to a disposed webview during shutdown

## [0.6.0]

### Added
- Serialized tracking controller with session cancellation and bounded capture retries
- Revisioned dirty-resource tracking for race-safe incremental reviews
- Exact byte snapshots and whole-file review for binary, unsupported, large, or overly complex files
- Workspace-root-scoped visual file selections stored outside workspace settings
- Multi-root and non-file URI identity throughout baseline and review state

### Changed
- Baselines are path-addressed snapshots without content hashing, deduplication, or reference counting
- Baseline blobs are sharded into two-character prefix directories
- Review refreshes recompute only resources with new events
- Glob patterns use one cached `minimatch` implementation with brace and character-class support
- Tracking activates lazily when a Cherry Diff view or command is used
- Directory capture uses deduplicated linear traversal and never follows symbolic-link directories
- Shared operational constants live in `src/constants.ts`
- Updated `diff` and development dependencies; dependency audit is clean

### Fixed
- Prevented uncaptured resources from being treated as new files before baseline completion
- Removed silent 50,000-file discovery limits and unintended `files.exclude` fallback behavior
- Prevented stale hunk rejection from overwriting newer file edits
- Kept reviews pending when edits or deletions fail
- Preserved binary bytes and UTF-8 BOM state during whole-file restoration
- Serialized filter synchronization, review refresh, resolution, and Stop Tracking cleanup
- Expanded directory create/delete events to their affected files
- Made exact baseline removal constant-time
- Prevented Tracked Files selections from modifying and then reviewing `.vscode/settings.json`
- Closed resolved diff tabs by URI identity and guarded delayed hunk scrolling against editor switches
- Kept Controls panel buttons functional under its content security policy

## [0.5.3]

### Changed
- Tracking is disabled by default and starts only after explicit user action
- Extension activation clears stale session data without installing watchers or capturing workspace files

## [0.5.2]

### Added
- `cherryDiff.baselineCaptureConcurrency` setting, configurable from 1 to 64 with a default of 12

### Changed
- Removed redundant Refresh and Filters buttons from Controls
- Moved Refresh to the Review view title and disabled bulk actions when nothing is pending
- Removed ellipsis suffixes from baseline preparation status labels

## [0.5.1]

### Changed
- Glob setting changes synchronize only newly included or excluded baselines
- Bulk accept/reject emits a single review update after all changed files are resolved

### Fixed
- Accept All now updates only pending changed-file baselines instead of clearing and recapturing the entire workspace
- Accept All and Reject All refresh pending filesystem events before resolving changes
- Resetting visual file selections preserves unrelated pending reviews and existing baselines

## [0.5.0]

### Added
- Explorer-style **Tracked Files** tree at the bottom of the Cherry Diff sidebar
- File and directory checkboxes for visual include/exclude selection
- Per-path overrides where the nearest selected directory or file takes precedence over glob filters
- Reset File Selections action in the Tracked Files view title

### Changed
- Newly checked paths are baselined incrementally, while unchecked paths are removed from review and baseline storage
- Explicitly checked paths can override both include and exclude glob patterns
- The Filters control now focuses the Tracked Files tree instead of opening raw settings

## [0.4.0]

### Added
- Disk-backed, content-addressed baseline storage under the extension workspace storage directory
- Initialization status and progress reporting while baseline snapshots are prepared
- Race-aware initialization that watches and recaptures files changed during the initial snapshot
- Automated coverage for blob deduplication, lazy loading, missing files, and unsaved open documents

### Changed
- Baseline file contents are loaded into memory only after a file enters review
- Initial capture prioritizes open files and reads the workspace with bounded concurrency instead of opening every file as a VS Code document

## [0.3.2]

### Fixed
- Background review updates no longer auto-open another diff or steal editor focus

## [0.3.1]

### Added
- Automated tests for diff reconstruction, empty-file existence changes, and glob matching
- Working ESLint configuration for TypeScript sources

### Fixed
- Empty files are now tracked separately from missing files, so creation, deletion, and rejection preserve the correct file state
- Accepting a hunk now honors the `cherryDiff.autoSave` setting
- Resetting or re-enabling tracking clears stale baseline entries before recapturing files
- Next/previous hunk navigation now moves consistently within and across files
- Virtual diff document URIs now preserve file paths portably on Windows and Unix
- Event subscriptions owned by view and content providers are now disposed correctly
- The `cherryDiff.reviewActive` context key now updates when reviews change
- Package version now matches the changelog version

### Changed
- Removed dead code: `classifyHunkLines`, `getHunkCurrentRange` from diffService
- Simplified `writeFileContent` by merging duplicate empty-content branches and removing unused parameter
- Removed unused `reviewManager` parameter from `openDiffForFile`
- Changed `vscode` import to `import type` in types.ts
- Excluded CHANGELOG.md from VSIX package

## [0.3.0]

### Added
- Diff tabs auto-close when all hunks in a file are resolved
- Auto-navigate to next file's diff after finishing review of a file

## [0.2.6]

### Changed
- Extension Development Host now launches with `--disable-extensions` for clean testing

## [0.2.5]

### Added
- **Reject All** button in Controls panel

### Changed
- Redesigned Controls panel button layout:
  - Row 1: Stop Tracking (full width)
  - Row 2: Refresh + Filters
  - Row 3: Accept All (green) + Reject All (red)
- Unified button styling with white text across all colored buttons

## [0.2.4]

### Changed
- Renamed "Reset Baseline" button to "Accept All"
- Activity bar badge now shows number of changed files instead of pending hunk count

## [0.2.2]

### Added
- Button tooltips on hover in Controls panel describing what each button does

### Changed
- Hunk labels now show only actual changed lines, not context lines (e.g. "line 42" instead of "lines 38-50")
- Single-line changes display as "line N" instead of "lines N-N"

## [0.2.1]

### Added
- **Controls panel** (WebviewView) with dedicated buttons: Refresh, Start/Stop Tracking, Reset Baseline, Filters
- Status line showing tracking state, changed file count, and pending hunk count
- **Reset Baseline** command — recaptures current file state as the new baseline, clearing all pending reviews

### Changed
- Moved all control buttons from the view title bar into the new Controls webview panel
- Review panel now shows as a separate collapsible section below Controls

## [0.2.0]

### Added
- Extension icon (cherry-themed with +/- symbols)
- MIT license
- `.vscodeignore` for smaller VSIX packages
- Repository field in package.json

### Changed
- Updated refresh icon from `$(search)` to `$(refresh)`

## [0.1.5]

### Added
- `cherryDiff.autoSave` setting (default: `true`) — automatically saves files after accepting or rejecting hunks

### Removed
- Redundant "Open Diff" inline button on tree items (clicking the row already opens the diff)

## [0.1.4]

### Added
- File deletion tracking (`onDidDelete` watcher)
- Support for deleted files: diff view uses virtual document for the right pane, reject recreates the file
- Support for new files: empty baseline, reject deletes the file
- `CurrentContentProvider` for showing deleted file content in diff editor

## [0.1.3]

### Added
- Activity bar badge showing pending hunk count (replaces status bar item)
- Include/exclude path configuration (`cherryDiff.includePaths`, `cherryDiff.excludePaths`) with 27 sensible defaults
- Filter button in view title bar to open settings
- Enable/Disable tracking commands with play/stop icons
- Custom glob matching engine (supports `**`, `*`, `?` patterns)
- Clicking hunk items scrolls the diff editor to the corresponding line

### Changed
- Review only triggers when user explicitly clicks refresh or via auto-refresh, not on every keystroke
- Tree items now open the diff view (not the raw file) for consistent behavior

### Removed
- Status bar item (replaced by activity bar badge)
- Inline editor decorations (`HunkDecorationProvider` removed)
- CodeLens Accept/Reject buttons (all review moved to sidebar)

## [0.1.2]

### Fixed
- Accept hunk now works correctly — advances baseline forward instead of rewriting the file (which was a no-op)
- Reject hunk immediately rewrites the file without the rejected change

### Added
- `BaselineContentProvider` for showing baseline in VS Code's native diff editor
- Side-by-side diff view (baseline vs current) when clicking review items

## [0.1.1]

### Changed
- Removed Git dependency — extension now works with any project (Git, non-Git, no VCS)
- Baselines are captured as in-memory snapshots at extension startup
- `GitService` removed entirely

## [0.1.0]

### Added
- Initial release
- Per-hunk accept/reject UI for file edits
- `BaselineService` for in-memory file snapshots
- `ChangeTracker` for watching workspace file changes
- `ReviewManager` for orchestrating diff computation and accept/reject logic
- `DiffService` wrapping the `diff` npm package for structured patch computation
- `ReviewTreeProvider` — sidebar TreeView showing files and hunks
- `HunkCodeLensProvider` — inline Accept/Reject buttons above each hunk
- `HunkDecorationProvider` — line highlighting for pending/accepted/rejected hunks
- Status bar item showing tracking state and pending hunk count
- Keyboard navigation: `Alt+]` / `Alt+[` for next/prev hunk
- VS Code extension manifest with commands, keybindings, views
