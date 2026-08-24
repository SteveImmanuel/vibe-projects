# Changelog

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
