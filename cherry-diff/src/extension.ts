import * as vscode from 'vscode';
import { BaselineService } from './baselineService';
import { ChangeTracker } from './changeTracker';
import { ReviewManager } from './reviewManager';
import { ReviewTreeProvider, HunkTreeItem, FileTreeItem } from './reviewTreeProvider';
import { BaselineContentProvider, CurrentContentProvider, openDiffForFile } from './baselineContentProvider';
import { ControlsViewProvider } from './controlsViewProvider';

let baselineService: BaselineService;
let changeTracker: ChangeTracker;
let reviewManager: ReviewManager;
let treeView: vscode.TreeView<any>;
let reviewDebounceTimer: ReturnType<typeof setTimeout> | undefined;

export async function activate(context: vscode.ExtensionContext): Promise<void> {
  baselineService = new BaselineService();
  changeTracker = new ChangeTracker();
  reviewManager = new ReviewManager(baselineService, changeTracker);

  // Capture baselines at startup using include/exclude filters
  await captureFilteredBaselines(baselineService);
  changeTracker.startTracking();
  await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', true);

  // Virtual document providers for diff view
  const baselineContentProvider = new BaselineContentProvider(reviewManager);
  const currentContentProvider = new CurrentContentProvider(reviewManager);
  context.subscriptions.push(
    vscode.workspace.registerTextDocumentContentProvider(
      'cherry-diff-baseline',
      baselineContentProvider
    ),
    vscode.workspace.registerTextDocumentContentProvider(
      'cherry-diff-current',
      currentContentProvider
    )
  );

  // Controls webview panel
  const controlsProvider = new ControlsViewProvider(changeTracker, reviewManager);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      ControlsViewProvider.viewType,
      controlsProvider
    )
  );

  // TreeView sidebar
  const treeProvider = new ReviewTreeProvider(reviewManager);
  treeView = vscode.window.createTreeView('cherryDiffReview', {
    treeDataProvider: treeProvider,
  });

  // Auto-refresh: recompute diffs when files change (debounced, sidebar only)
  changeTracker.onDidChangeTrackedFiles(() => {
    if (reviewManager.isApplying()) {
      return;
    }
    if (reviewDebounceTimer) {
      clearTimeout(reviewDebounceTimer);
    }
    reviewDebounceTimer = setTimeout(async () => {
      await reviewManager.startReview();
      updateBadge();
    }, 800);
  });

  reviewManager.onDidChangeReview(() => {
    // Sync changed files: remove files that no longer have pending hunks
    const activeFiles = new Set(reviewManager.getAllFileReviews().keys());
    for (const fsPath of changeTracker.getChangedFiles()) {
      if (!activeFiles.has(fsPath)) {
        changeTracker.removeChangedFile(fsPath);
      }
    }
    updateBadge();
    controlsProvider.updateView();
  });

  // --- Commands ---

  context.subscriptions.push(
    // Manual refresh
    vscode.commands.registerCommand('cherryDiff.startReview', async () => {
      await reviewManager.startReview();
      updateBadge();
    }),

    // Enable tracking
    vscode.commands.registerCommand('cherryDiff.enableTracking', async () => {
      await captureFilteredBaselines(baselineService);
      changeTracker.startTracking();
      await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', true);
      controlsProvider.updateView();
    }),

    // Reset baseline — capture current state as the new baseline
    vscode.commands.registerCommand('cherryDiff.resetBaseline', async () => {
      reviewManager.clearReview();
      changeTracker.clearChangedFiles();
      await captureFilteredBaselines(baselineService);
      updateBadge();
      controlsProvider.updateView();
    }),

    // Disable tracking
    vscode.commands.registerCommand('cherryDiff.disableTracking', async () => {
      changeTracker.stopTracking();
      reviewManager.clearReview();
      baselineService.clearBaselines();
      await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', false);
      await vscode.commands.executeCommand('setContext', 'cherryDiff.reviewActive', false);
      updateBadge();
      controlsProvider.updateView();
    }),

    // Open diff — from tree item or fsPath
    vscode.commands.registerCommand(
      'cherryDiff.openDiff',
      async (itemOrFsPath: FileTreeItem | HunkTreeItem | string) => {
        const fsPath =
          typeof itemOrFsPath === 'string' ? itemOrFsPath : itemOrFsPath.fsPath;
        await openDiffForFile(fsPath);
      }
    ),

    // Open diff at a specific line (from hunk tree item click)
    vscode.commands.registerCommand(
      'cherryDiff.openDiffAtLine',
      async (fsPath: string, line: number) => {
        await openDiffForFile(fsPath, line);
      }
    ),

    // Accept hunk — from tree inline button
    vscode.commands.registerCommand(
      'cherryDiff.acceptHunk',
      async (item: HunkTreeItem) => {
        if (item instanceof HunkTreeItem) {
          await reviewManager.acceptHunk(item.fsPath, item.hunkId);
        }
      }
    ),

    // Reject hunk
    vscode.commands.registerCommand(
      'cherryDiff.rejectHunk',
      async (item: HunkTreeItem) => {
        if (item instanceof HunkTreeItem) {
          await reviewManager.rejectHunk(item.fsPath, item.hunkId);
        }
      }
    ),

    // Accept all hunks in file
    vscode.commands.registerCommand(
      'cherryDiff.acceptAllFile',
      async (item?: FileTreeItem) => {
        const fsPath = item instanceof FileTreeItem
          ? item.fsPath
          : vscode.window.activeTextEditor?.document.uri.fsPath;
        if (fsPath) {
          await reviewManager.setAllHunksInFile(fsPath, 'accepted');
        }
      }
    ),

    // Reject all hunks in file
    vscode.commands.registerCommand(
      'cherryDiff.rejectAllFile',
      async (item?: FileTreeItem) => {
        const fsPath = item instanceof FileTreeItem
          ? item.fsPath
          : vscode.window.activeTextEditor?.document.uri.fsPath;
        if (fsPath) {
          await reviewManager.setAllHunksInFile(fsPath, 'rejected');
        }
      }
    ),

    vscode.commands.registerCommand('cherryDiff.acceptAll', async () => {
      await reviewManager.setAllHunks('accepted');
    }),

    vscode.commands.registerCommand('cherryDiff.rejectAll', async () => {
      await reviewManager.setAllHunks('rejected');
    }),

    // Open settings for include/exclude filters
    vscode.commands.registerCommand('cherryDiff.editFilters', () => {
      vscode.commands.executeCommand(
        'workbench.action.openSettings',
        'cherryDiff'
      );
    }),

    vscode.commands.registerCommand('cherryDiff.nextHunk', () => {
      navigateHunk('next');
    }),

    vscode.commands.registerCommand('cherryDiff.prevHunk', () => {
      navigateHunk('prev');
    })
  );

  context.subscriptions.push(
    baselineService,
    baselineContentProvider,
    currentContentProvider,
    changeTracker,
    reviewManager,
    treeView
  );

  updateBadge();
}

async function captureFilteredBaselines(baselineService: BaselineService): Promise<void> {
  const config = vscode.workspace.getConfiguration('cherryDiff');
  const includes: string[] = config.get('includePaths', ['**/*']);
  const excludes: string[] = config.get('excludePaths', []);

  const excludePattern = excludes.length > 0
    ? `{${excludes.join(',')}}`
    : undefined;

  let allFiles: vscode.Uri[] = [];
  for (const includePattern of includes) {
    const files = await vscode.workspace.findFiles(includePattern, excludePattern, 50000);
    allFiles.push(...files);
  }

  const seen = new Set<string>();
  const uniqueFiles = allFiles.filter((uri) => {
    if (seen.has(uri.fsPath)) {
      return false;
    }
    seen.add(uri.fsPath);
    return true;
  });

  console.log(`[Cherry Diff] Capturing baselines for ${uniqueFiles.length} files`);

  for (const uri of uniqueFiles) {
    try {
      const stat = await vscode.workspace.fs.stat(uri);
      if ((stat.type & vscode.FileType.Directory) === 0) {
        await baselineService.captureBaseline(uri);
      }
    } catch {
      // skip
    }
  }

  console.log('[Cherry Diff] Baselines captured.');
}

function updateBadge(): void {
  if (!treeView) {
    return;
  }

  const fileCount = reviewManager?.getAllFileReviews().size ?? 0;
  if (fileCount > 0) {
    treeView.badge = { value: fileCount, tooltip: `${fileCount} file${fileCount !== 1 ? 's' : ''} changed` };
  } else {
    treeView.badge = undefined;
  }
}

async function navigateHunk(direction: 'next' | 'prev'): Promise<void> {
  const pending = reviewManager.getAllPendingHunks();
  if (pending.length === 0) {
    return;
  }

  const editor = vscode.window.activeTextEditor;
  const currentLine = editor?.selection.active.line ?? 0;
  const currentFile = editor?.document.uri.fsPath;

  let target = direction === 'next' ? pending[0] : pending[pending.length - 1];

  for (let i = 0; i < pending.length; i++) {
    const h = pending[i];
    const hunkLine = h.hunk.hunk.newStart - 1;

    if (direction === 'next') {
      if (h.fsPath === currentFile && hunkLine > currentLine) {
        target = h;
        break;
      }
      if (h.fsPath !== currentFile && target.fsPath === currentFile) {
        target = h;
        break;
      }
    } else {
      if (h.fsPath === currentFile && hunkLine < currentLine) {
        target = h;
      }
    }
  }

  await openDiffForFile(target.fsPath, target.hunk.hunk.newStart - 1);
}

export function deactivate(): void {
  if (reviewDebounceTimer) {
    clearTimeout(reviewDebounceTimer);
  }
}
