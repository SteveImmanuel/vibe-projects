import * as vscode from 'vscode';
import { BaselineService } from './baselineService';
import { ChangeTracker } from './changeTracker';
import { ReviewManager } from './reviewManager';
import {
  ReviewTreeProvider,
  HunkTreeItem,
  FileTreeItem,
  ReviewTreeItem,
} from './reviewTreeProvider';
import {
  BaselineContentProvider,
  CurrentContentProvider,
  getReviewDocumentFsPath,
  openDiffForFile,
} from './baselineContentProvider';
import { ControlsViewProvider } from './controlsViewProvider';
import { getFirstChangedLine } from './diffService';

let baselineService: BaselineService;
let changeTracker: ChangeTracker;
let reviewManager: ReviewManager;
let treeView: vscode.TreeView<ReviewTreeItem>;
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
  const trackedFilesSubscription = changeTracker.onDidChangeTrackedFiles(() => {
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

  // Track which files are under review so we can close resolved diff tabs
  let previousReviewFiles = new Set<string>();

  const reviewSubscription = reviewManager.onDidChangeReview(async () => {
    const currentReviewFiles = new Set(reviewManager.getAllFileReviews().keys());

    // Close diff tabs for resolved files, then open next file if any remain
    const resolvedFiles: string[] = [];
    for (const fsPath of previousReviewFiles) {
      if (!currentReviewFiles.has(fsPath)) {
        resolvedFiles.push(fsPath);
      }
    }
    previousReviewFiles = currentReviewFiles;

    for (const fsPath of resolvedFiles) {
      await closeDiffTab(fsPath);
    }
    if (resolvedFiles.length > 0 && currentReviewFiles.size > 0) {
      const nextFile = currentReviewFiles.values().next().value;
      if (nextFile) {
        await openDiffForFile(nextFile);
      }
    }

    // Sync changed files: remove files that no longer have pending hunks
    for (const fsPath of changeTracker.getChangedFiles()) {
      if (!currentReviewFiles.has(fsPath)) {
        changeTracker.removeChangedFile(fsPath);
      }
    }
    await vscode.commands.executeCommand(
      'setContext',
      'cherryDiff.reviewActive',
      currentReviewFiles.size > 0
    );
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
      baselineService.clearBaselines();
      await captureFilteredBaselines(baselineService);
      changeTracker.startTracking();
      await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', true);
      controlsProvider.updateView();
    }),

    // Reset baseline — capture current state as the new baseline
    vscode.commands.registerCommand('cherryDiff.resetBaseline', async () => {
      reviewManager.clearReview();
      changeTracker.clearChangedFiles();
      baselineService.clearBaselines();
      await captureFilteredBaselines(baselineService);
      updateBadge();
      controlsProvider.updateView();
    }),

    // Disable tracking
    vscode.commands.registerCommand('cherryDiff.disableTracking', async () => {
      if (reviewDebounceTimer) {
        clearTimeout(reviewDebounceTimer);
        reviewDebounceTimer = undefined;
      }
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
    controlsProvider,
    treeProvider,
    trackedFilesSubscription,
    reviewSubscription,
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

  const allFiles: vscode.Uri[] = [];
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
  let currentFile = editor?.document.uri.fsPath;
  if (editor?.document.uri.scheme === 'cherry-diff-baseline'
    || editor?.document.uri.scheme === 'cherry-diff-current') {
    currentFile = getReviewDocumentFsPath(editor.document.uri);
  }

  const indexesInCurrentFile = pending
    .map((entry, index) => ({ entry, index }))
    .filter(({ entry }) => entry.fsPath === currentFile);

  let targetIndex: number;
  if (indexesInCurrentFile.length === 0) {
    targetIndex = direction === 'next' ? 0 : pending.length - 1;
  } else if (direction === 'next') {
    const laterHunk = indexesInCurrentFile.find(
      ({ entry }) => getFirstChangedLine(entry.hunk.hunk) > currentLine
    );
    targetIndex = laterHunk?.index
      ?? (indexesInCurrentFile[indexesInCurrentFile.length - 1].index + 1) % pending.length;
  } else {
    const earlierHunk = [...indexesInCurrentFile].reverse().find(
      ({ entry }) => getFirstChangedLine(entry.hunk.hunk) < currentLine
    );
    targetIndex = earlierHunk?.index
      ?? (indexesInCurrentFile[0].index - 1 + pending.length) % pending.length;
  }

  const target = pending[targetIndex];
  await openDiffForFile(target.fsPath, getFirstChangedLine(target.hunk.hunk));
}

/**
 * Close the diff editor tab for a specific file by matching the tab label.
 */
async function closeDiffTab(fsPath: string): Promise<void> {
  const relativePath = vscode.workspace.asRelativePath(vscode.Uri.file(fsPath));
  const expectedLabel = `${relativePath} (Baseline ↔ Current)`;

  for (const group of vscode.window.tabGroups.all) {
    for (const tab of group.tabs) {
      if (tab.label === expectedLabel) {
        await vscode.window.tabGroups.close(tab);
        return;
      }
    }
  }
}

export function deactivate(): void {
  if (reviewDebounceTimer) {
    clearTimeout(reviewDebounceTimer);
  }
}
