# Cherry Diff

A VS Code extension for reviewing file edits one hunk at a time — accept the changes you want, reject the rest.

Cherry Diff captures a baseline snapshot of every tracked file when you press **Start Tracking**, then turns each subsequent edit into a reviewable diff. It was built for working with AI coding agents: any tool (or human) that edits files on disk produces reviews, without the agent knowing Cherry Diff exists.

## Highlights

- **Agent-agnostic** — observes normal editor and filesystem events; nothing needs to integrate with it
- **No Git required** — works in any folder; rejection restores from extension-owned baseline snapshots, not version control
- **Per-hunk control** — accept or reject individual hunks, whole files, or everything at once
- **Byte-safe** — binary and non-UTF-8 files are restored from exact bytes, and UTF-8 BOMs survive round trips
- **Explicit and unobtrusive** — tracking starts only when you ask, and background review updates never steal editor focus

## Usage

1. Open the **Cherry Diff** icon in the activity bar.
2. Press **Start Tracking**. Baselines are captured for every included file.
3. Edit files — yourself, or let your agent loose.
4. Changed files appear in the **Review** view, one entry per hunk. Clicking a hunk opens a native diff editor (baseline ↔ current).
5. Resolve each hunk:
   - **Accept** keeps the change and advances the baseline.
   - **Reject** rewrites the file without that change. Rejecting a new file deletes it; rejecting a deletion restores the file.

   File-level **Accept/Reject All Hunks** and global **Accept All / Reject All** actions are available from the tree and the Controls panel.
6. Press **Stop Tracking** to end the session and discard its baselines.

Keyboard: `Alt+]` / `Alt+[` jump to the next / previous pending hunk while a review is active.

## Choosing what is tracked

- `cherryDiff.includePaths` / `cherryDiff.excludePaths` hold glob patterns. The defaults include everything and exclude the usual noise (`node_modules`, build output, lockfiles, VCS metadata, minified assets, …).
- The **Tracked Files** view shows the workspace as a checkbox tree. Checking or unchecking a file or directory overrides the globs for that path, and the nearest override wins. Selections are stored in workspace state — not `settings.json` — so toggling them never creates a review of its own.

Precedence: visual selection → exclude globs → include globs.

## Settings

| Setting | Default | Description |
|---|---|---|
| `cherryDiff.autoSave` | `true` | Save files automatically after accepting or rejecting hunks |
| `cherryDiff.baselineCaptureConcurrency` | `12` | Concurrent file reads while baselines are prepared (1–64) |
| `cherryDiff.includePaths` | `["**/*"]` | Glob patterns for files to track |
| `cherryDiff.excludePaths` | 27 defaults | Glob patterns for files to exclude |

## Limitations

- Binary, non-UTF-8, very large, or pathologically different files are reviewed as a single whole-file change.
- Baselines live for the tracking session only; reloading the window requires starting tracking again.
- There is no extension-owned undo after accepting or rejecting.
- Directory renames appear as create + delete events, and symbolic-link directories are listed but not traversed.

## Installation

Cherry Diff is not published to the marketplace. Build and install it from source:

```bash
npm install
npx @vscode/vsce package
```

Then run **Extensions: Install from VSIX…** in VS Code and pick the generated `.vsix`.

## Development

```bash
npm install
npm run check   # compile + tests + lint
```

Press <kbd>F5</kbd> to launch an Extension Development Host. Architecture and invariants are documented in [AGENTS.md](./AGENTS.md).
