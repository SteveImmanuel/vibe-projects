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
import { FilterTreeItem, FilterTreeProvider } from './filterTreeProvider';
import { clearPathOverrides, isUriIncluded, PathOverrides } from './filterService';
import { getFirstChangedLine } from './diffService';

const DEFAULT_BASELINE_CAPTURE_CONCURRENCY = 12;
const MAX_BASELINE_CAPTURE_CONCURRENCY = 64;

let baselineService: BaselineService;
let changeTracker: ChangeTracker;
let reviewManager: ReviewManager;
let treeView: vscode.TreeView<ReviewTreeItem>;
let reviewDebounceTimer: ReturnType<typeof setTimeout> | undefined;
let filterSyncTimer: ReturnType<typeof setTimeout> | undefined;
let trackingInitializationPromise: Promise<boolean> | undefined;
let initializationGeneration = 0;

export async function activate(context: vscode.ExtensionContext): Promise<void> {
  const baselineStorageUri = vscode.Uri.joinPath(
    context.storageUri ?? context.globalStorageUri,
    'baseline-session'
  );
  baselineService = new BaselineService(baselineStorageUri);
  changeTracker = new ChangeTracker();
  reviewManager = new ReviewManager(baselineService, changeTracker);

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

  // Explorer-style include/exclude tree at the bottom of the sidebar.
  const filterTreeProvider = new FilterTreeProvider();
  const filterTreeView = vscode.window.createTreeView('cherryDiffFilters', {
    treeDataProvider: filterTreeProvider,
    manageCheckboxStateManually: true,
    showCollapseAll: true,
  });
  const filterCheckboxSubscription = filterTreeView.onDidChangeCheckboxState(
    async (event) => {
      if (changeTracker.isInitializing()) {
        vscode.window.showInformationMessage(
          'Cherry Diff: Wait for baseline preparation to finish before changing file selections.'
        );
        filterTreeProvider.refresh();
        return;
      }
      await applyFilterCheckboxChanges(filterTreeProvider, event.items);
    }
  );
  const filterConfigurationSubscription = vscode.workspace.onDidChangeConfiguration(
    (event) => {
      const globFiltersChanged = event.affectsConfiguration('cherryDiff.includePaths')
        || event.affectsConfiguration('cherryDiff.excludePaths');
      if (!globFiltersChanged || !changeTracker.isTracking()) {
        return;
      }
      if (filterSyncTimer) {
        clearTimeout(filterSyncTimer);
      }
      filterSyncTimer = setTimeout(async () => {
        filterSyncTimer = undefined;
        try {
          await synchronizeBaselinesWithFilters();
          await reviewManager.startReview();
        } catch (error) {
          console.error('[Cherry Diff] Failed to apply glob filter changes', error);
          vscode.window.showErrorMessage(
            'Cherry Diff: Failed to apply the updated include/exclude filters.'
          );
        }
      }, 300);
    }
  );

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

    // Close diff tabs for resolved files without changing the user's active editor.
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
      if (!changeTracker.isTracking()) {
        await initializeTracking(controlsProvider);
      }
    }),

    // Legacy command ID retained for compatibility; this now accepts only
    // pending changes instead of rebuilding every workspace baseline.
    vscode.commands.registerCommand('cherryDiff.resetBaseline', async () => {
      await resolveAllPendingChanges('accepted');
    }),

    // Disable tracking
    vscode.commands.registerCommand('cherryDiff.disableTracking', async () => {
      if (reviewDebounceTimer) {
        clearTimeout(reviewDebounceTimer);
        reviewDebounceTimer = undefined;
      }
      initializationGeneration++;
      changeTracker.stopTracking();
      reviewManager.clearReview();
      if (trackingInitializationPromise) {
        await trackingInitializationPromise;
      }
      await baselineService.clearBaselines();
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
      await resolveAllPendingChanges('accepted');
    }),

    vscode.commands.registerCommand('cherryDiff.rejectAll', async () => {
      await resolveAllPendingChanges('rejected');
    }),

    // Open settings for include/exclude filters
    vscode.commands.registerCommand('cherryDiff.editFilters', () => {
      vscode.commands.executeCommand('cherryDiffFilters.focus');
    }),

    vscode.commands.registerCommand('cherryDiff.nextHunk', () => {
      navigateHunk('next');
    }),

    vscode.commands.registerCommand('cherryDiff.prevHunk', () => {
      navigateHunk('prev');
    }),

    vscode.commands.registerCommand('cherryDiff.clearPathOverrides', async () => {
      await clearPathOverrides();
      filterTreeProvider.refresh();
      if (changeTracker.isTracking()) {
        await synchronizeBaselinesWithFilters();
        await reviewManager.startReview();
      }
    })
  );

  context.subscriptions.push(
    baselineService,
    baselineContentProvider,
    currentContentProvider,
    controlsProvider,
    treeProvider,
    filterTreeProvider,
    filterTreeView,
    filterCheckboxSubscription,
    filterConfigurationSubscription,
    trackedFilesSubscription,
    reviewSubscription,
    changeTracker,
    reviewManager,
    treeView
  );

  // Tracking is opt-in. Discard any previous session data, but do not install
  // watchers or capture workspace files until the user explicitly starts it.
  await baselineService.clearBaselines();
  await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', false);
  await vscode.commands.executeCommand('setContext', 'cherryDiff.reviewActive', false);
  controlsProvider.updateView();
  updateBadge();
}

async function resolveAllPendingChanges(
  status: 'accepted' | 'rejected'
): Promise<void> {
  if (reviewDebounceTimer) {
    clearTimeout(reviewDebounceTimer);
    reviewDebounceTimer = undefined;
  }

  // Pull in filesystem events that arrived just before the button click so
  // bulk actions cannot miss files waiting for the debounce timer.
  await reviewManager.startReview();
  await reviewManager.setAllHunks(status);
  updateBadge();
}

async function synchronizeBaselinesWithFilters(): Promise<void> {
  for (const fsPath of baselineService.getBaselinePaths()) {
    if (!isUriIncluded(vscode.Uri.file(fsPath))) {
      await baselineService.removeBaseline(fsPath, false);
    }
  }

  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Cherry Diff: Updating tracked files',
      cancellable: false,
    },
    async (progress) => {
      let unstable = await captureFilteredBaselines(progress, () => false, true);
      while (unstable.size > 0) {
        unstable = await captureBaselinePaths(
          [...unstable].map((fsPath) => vscode.Uri.file(fsPath)),
          undefined,
          () => false
        );
      }
    }
  );
}

async function applyFilterCheckboxChanges(
  provider: FilterTreeProvider,
  changes: ReadonlyArray<[FilterTreeItem, vscode.TreeItemCheckboxState]>
): Promise<void> {
  try {
    await provider.applyCheckboxChanges(changes);
    if (!changeTracker.isTracking()) {
      return;
    }

    const includedItems = changes
      .filter(([, state]) => state === vscode.TreeItemCheckboxState.Checked)
      .map(([item]) => item);
    const excludedItems = changes
      .filter(([, state]) => state === vscode.TreeItemCheckboxState.Unchecked)
      .map(([item]) => item);

    for (const item of excludedItems) {
      await baselineService.removeBaseline(item.uri.fsPath, item.isDirectory);
    }

    if (includedItems.length > 0) {
      await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: 'Cherry Diff: Adding tracked files',
          cancellable: false,
        },
        async (progress) => {
          const uris = await collectFilesForFilterItems(includedItems, progress);
          let unstable = await captureBaselinePaths(uris, progress, () => false);
          while (unstable.size > 0) {
            unstable = await captureBaselinePaths(
              [...unstable].map((fsPath) => vscode.Uri.file(fsPath)),
              undefined,
              () => false
            );
          }
        }
      );
    }

    await reviewManager.startReview();
  } catch (error) {
    console.error('[Cherry Diff] Failed to update tracked file selections', error);
    vscode.window.showErrorMessage(
      'Cherry Diff: Failed to update the tracked file selections.'
    );
    provider.refresh();
  }
}

async function collectFilesForFilterItems(
  items: FilterTreeItem[],
  progress: vscode.Progress<{ message?: string; increment?: number }>
): Promise<vscode.Uri[]> {
  const files = new Map<string, vscode.Uri>();
  const directories = items.filter((item) => item.isDirectory).map((item) => item.uri);
  for (const item of items) {
    if (!item.isDirectory) {
      files.set(item.uri.fsPath, item.uri);
    }
  }

  let scannedDirectories = 0;
  while (directories.length > 0) {
    const directory = directories.shift();
    if (!directory) {
      break;
    }

    let entries: [string, vscode.FileType][];
    try {
      entries = await vscode.workspace.fs.readDirectory(directory);
    } catch {
      continue;
    }

    scannedDirectories++;
    progress.report({ message: `${files.size.toLocaleString()} files found` });
    for (const [name, type] of entries) {
      const uri = vscode.Uri.joinPath(directory, name);
      if ((type & vscode.FileType.Directory) !== 0
        && (type & vscode.FileType.SymbolicLink) === 0) {
        directories.push(uri);
      } else if ((type & vscode.FileType.Directory) === 0) {
        files.set(uri.fsPath, uri);
      }
    }
  }

  if (scannedDirectories > 0) {
    progress.report({ message: `Capturing ${files.size.toLocaleString()} files` });
  }
  return [...files.values()];
}

async function initializeTracking(
  controlsProvider?: ControlsViewProvider
): Promise<boolean> {
  if (trackingInitializationPromise) {
    return trackingInitializationPromise;
  }

  const generation = ++initializationGeneration;
  const promise = performTrackingInitialization(generation, controlsProvider);
  trackingInitializationPromise = promise;

  try {
    return await promise;
  } finally {
    if (trackingInitializationPromise === promise) {
      trackingInitializationPromise = undefined;
    }
  }
}

async function performTrackingInitialization(
  generation: number,
  controlsProvider?: ControlsViewProvider
): Promise<boolean> {
  changeTracker.beginInitialization();
  await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', false);
  await vscode.commands.executeCommand('setContext', 'cherryDiff.reviewActive', false);
  controlsProvider?.updateView();

  const isCancelled = (): boolean => (
    generation !== initializationGeneration || !changeTracker.isInitializing()
  );

  try {
    await baselineService.clearBaselines();

    const unstablePaths = await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: 'Cherry Diff: Preparing disk-backed baselines',
        cancellable: false,
      },
      async (progress) => captureFilteredBaselines(progress, isCancelled)
    );

    if (isCancelled()) {
      return false;
    }

    let pendingPaths = new Set<string>([
      ...unstablePaths,
      ...changeTracker.takeInitializationChanges(),
    ]);

    while (pendingPaths.size > 0 && !isCancelled()) {
      const paths = Array.from(pendingPaths);
      const unstable = await captureBaselinePaths(
        paths.map((fsPath) => vscode.Uri.file(fsPath)),
        undefined,
        isCancelled
      );
      pendingPaths = new Set<string>([
        ...unstable,
        ...changeTracker.takeInitializationChanges(),
      ]);
    }

    if (isCancelled() || !changeTracker.finishInitialization()) {
      return false;
    }

    await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', true);
    console.log(
      `[Cherry Diff] ${baselineService.getBaselineCount()} disk-backed baselines ready.`
    );
    return true;
  } catch (error) {
    if (generation === initializationGeneration) {
      changeTracker.stopTracking();
      await vscode.commands.executeCommand('setContext', 'cherryDiff.tracking', false);
      console.error('[Cherry Diff] Failed to prepare baselines', error);
      vscode.window.showErrorMessage(
        'Cherry Diff: Failed to prepare disk-backed baselines. Tracking was not started.'
      );
    }
    return false;
  } finally {
    controlsProvider?.updateView();
  }
}

async function captureFilteredBaselines(
  progress: vscode.Progress<{ message?: string; increment?: number }>,
  isCancelled: () => boolean,
  onlyMissing = false
): Promise<Set<string>> {
  const config = vscode.workspace.getConfiguration('cherryDiff');
  const includes: string[] = config.get('includePaths', ['**/*']);
  const excludes: string[] = config.get('excludePaths', []);
  const overrides = config.get<PathOverrides>('pathOverrides', {});
  const excludePattern = excludes.length > 0
    ? `{${excludes.join(',')}}`
    : undefined;

  progress.report({ message: 'Finding included files' });
  const allFiles: vscode.Uri[] = [];
  for (const includePattern of includes) {
    if (isCancelled()) {
      return new Set();
    }
    const files = await vscode.workspace.findFiles(includePattern, excludePattern, 50000);
    allFiles.push(...files);
  }

  // Explicit checked paths can override both include and exclude globs, so
  // discover them separately without the glob exclusion expression.
  for (const [overridePath, included] of Object.entries(overrides)) {
    if (!included || isCancelled()) {
      continue;
    }
    const exactPattern = overridePath || '**/*';
    allFiles.push(...await vscode.workspace.findFiles(exactPattern, null, 50000));
    if (overridePath) {
      allFiles.push(
        ...await vscode.workspace.findFiles(`${overridePath}/**`, null, 50000)
      );
    }
  }

  const seen = new Set<string>();
  const uniqueFiles = allFiles.filter((uri) => {
    if (seen.has(uri.fsPath)) {
      return false;
    }
    seen.add(uri.fsPath);
    return isUriIncluded(uri)
      && (!onlyMissing || !baselineService.hasBaseline(uri.fsPath));
  });

  // Capture visible/open files first so their pre-edit state is secured as
  // early as possible while the rest of a large workspace is scanned.
  const openPaths = new Set(
    vscode.workspace.textDocuments
      .filter((document) => document.uri.scheme === 'file')
      .map((document) => document.uri.fsPath)
  );
  uniqueFiles.sort((a, b) => Number(openPaths.has(b.fsPath)) - Number(openPaths.has(a.fsPath)));

  console.log(`[Cherry Diff] Snapshotting ${uniqueFiles.length} files to disk.`);
  return captureBaselinePaths(uniqueFiles, progress, isCancelled);
}

async function captureBaselinePaths(
  uris: vscode.Uri[],
  progress: vscode.Progress<{ message?: string; increment?: number }> | undefined,
  isCancelled: () => boolean
): Promise<Set<string>> {
  const unstablePaths = new Set<string>();
  let nextIndex = 0;
  let completed = 0;
  const configuredConcurrency = vscode.workspace
    .getConfiguration('cherryDiff')
    .get<number>(
      'baselineCaptureConcurrency',
      DEFAULT_BASELINE_CAPTURE_CONCURRENCY
    );
  const normalizedConcurrency = Number.isFinite(configuredConcurrency)
    ? Math.floor(configuredConcurrency)
    : DEFAULT_BASELINE_CAPTURE_CONCURRENCY;
  const captureConcurrency = Math.min(
    MAX_BASELINE_CAPTURE_CONCURRENCY,
    Math.max(1, normalizedConcurrency)
  );
  const workerCount = Math.min(captureConcurrency, uris.length);

  const worker = async (): Promise<void> => {
    while (!isCancelled()) {
      const index = nextIndex++;
      if (index >= uris.length) {
        return;
      }

      const uri = uris[index];
      const result = await baselineService.captureBaseline(uri);
      if (result === 'unstable') {
        unstablePaths.add(uri.fsPath);
      }

      completed++;
      progress?.report({
        message: `${completed.toLocaleString()} / ${uris.length.toLocaleString()} files`,
        increment: uris.length > 0 ? 100 / uris.length : 100,
      });
    }
  };

  await Promise.all(Array.from({ length: workerCount }, () => worker()));
  return unstablePaths;
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
  if (filterSyncTimer) {
    clearTimeout(filterSyncTimer);
  }
}
