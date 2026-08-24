import { randomUUID } from 'crypto';
import * as vscode from 'vscode';
import {
  createReviewDocumentUri,
  getReviewResourceKey,
  openDiffForReview,
  ReviewContentProvider,
} from './baselineContentProvider';
import { BaselineCaptureService } from './baselineCaptureService';
import { BaselineService } from './baselineService';
import { ChangeTracker } from './changeTracker';
import {
  BASELINE_DOCUMENT_SCHEME,
  BASELINE_SESSIONS_DIRECTORY,
  CURRENT_DOCUMENT_SCHEME,
} from './constants';
import { ControlsViewProvider } from './controlsViewProvider';
import { getFirstChangedLine } from './diffService';
import { FilterService } from './filterService';
import { FilterTreeProvider } from './filterTreeProvider';
import { ReviewManager } from './reviewManager';
import {
  FileTreeItem,
  HunkTreeItem,
  ReviewTreeItem,
  ReviewTreeProvider,
} from './reviewTreeProvider';
import { getErrorMessage, TrackingController } from './trackingController';

let activeController: TrackingController | undefined;
let reviewTreeView: vscode.TreeView<ReviewTreeItem> | undefined;

export function activate(context: vscode.ExtensionContext): void {
  const filters = new FilterService(context.workspaceState);

  const storageRoot = context.storageUri ?? context.globalStorageUri;
  const sessionStorageUri = vscode.Uri.joinPath(
    storageRoot,
    BASELINE_SESSIONS_DIRECTORY,
    randomUUID()
  );
  const baselines = new BaselineService(sessionStorageUri);
  const changes = new ChangeTracker(filters);
  const reviews = new ReviewManager(baselines, changes);
  const captures = new BaselineCaptureService(baselines, filters);
  const controller = new TrackingController(
    baselines,
    captures,
    filters,
    changes,
    reviews
  );
  activeController = controller;

  const baselineProvider = new ReviewContentProvider(
    reviews,
    BASELINE_DOCUMENT_SCHEME,
    (review) => review.baseline.text
  );
  const currentProvider = new ReviewContentProvider(
    reviews,
    CURRENT_DOCUMENT_SCHEME,
    (review) => review.current.text
  );
  const controlsProvider = new ControlsViewProvider(controller, reviews);
  const reviewTreeProvider = new ReviewTreeProvider(reviews);
  const filterTreeProvider = new FilterTreeProvider(filters);

  reviewTreeView = vscode.window.createTreeView('cherryDiffReview', {
    treeDataProvider: reviewTreeProvider,
  });
  const filterTreeView = vscode.window.createTreeView('cherryDiffFilters', {
    treeDataProvider: filterTreeProvider,
    manageCheckboxStateManually: true,
    showCollapseAll: true,
  });

  context.subscriptions.push(
    vscode.workspace.registerTextDocumentContentProvider(
      BASELINE_DOCUMENT_SCHEME,
      baselineProvider
    ),
    vscode.workspace.registerTextDocumentContentProvider(
      CURRENT_DOCUMENT_SCHEME,
      currentProvider
    ),
    vscode.window.registerWebviewViewProvider(
      ControlsViewProvider.viewType,
      controlsProvider
    ),
    reviewTreeView,
    filterTreeView,
    filterTreeView.onDidChangeCheckboxState(async (event) => {
      if (controller.isInitializing()) {
        vscode.window.showInformationMessage(
          'Cherry Diff: Wait for baseline preparation to finish before changing file selections.'
        );
        filterTreeProvider.refresh();
        return;
      }
      await safely('update tracked-file selections', () => (
        filterTreeProvider.applyCheckboxChanges(event.items)
      ));
    })
  );

  const reviewSubscription = reviews.onDidChangeReview((event) => {
    void closeResolvedDiffTabs(event.removed).catch((error) => {
      console.error('[Cherry Diff] Failed to close resolved diff tabs', error);
    });
    updateContextKeys(controller, reviews);
    updateBadge(reviews);
  });
  const stateSubscription = controller.onDidChangeState(() => {
    updateContextKeys(controller, reviews);
    updateBadge(reviews);
  });

  context.subscriptions.push(
    registerCommands(controller, reviews, filters),
    reviewSubscription,
    stateSubscription,
    baselineProvider,
    currentProvider,
    controlsProvider,
    reviewTreeProvider,
    filterTreeProvider,
    controller,
    reviews,
    changes,
    filters,
    baselines
  );

  updateContextKeys(controller, reviews);
  updateBadge(reviews);
}

function registerCommands(
  controller: TrackingController,
  reviews: ReviewManager,
  filters: FilterService
): vscode.Disposable {
  const disposables: vscode.Disposable[] = [
    vscode.commands.registerCommand('cherryDiff.startReview', () => (
      safely('refresh the review', () => controller.refreshReview())
    )),
    vscode.commands.registerCommand('cherryDiff.enableTracking', () => (
      safely('start tracking', () => controller.startTracking())
    )),
    vscode.commands.registerCommand('cherryDiff.disableTracking', () => (
      safely('stop tracking', () => controller.stopTracking())
    )),
    vscode.commands.registerCommand(
      'cherryDiff.openDiff',
      (input?: FileTreeItem | HunkTreeItem | string) => safely(
        'open the diff',
        async () => {
          const review = resolveReview(input, reviews);
          if (!review) {
            vscode.window.showInformationMessage(
              'Cherry Diff: Select a reviewed file before opening a diff.'
            );
            return;
          }
          await openDiffForReview(review);
        }
      )
    ),
    vscode.commands.registerCommand(
      'cherryDiff.openDiffAtLine',
      (resourceKey: string, line: number) => safely('open the diff', async () => {
        const review = reviews.getFileReview(resourceKey);
        if (review) {
          await openDiffForReview(review, line);
        }
      })
    ),
    vscode.commands.registerCommand(
      'cherryDiff.acceptHunk',
      (item?: HunkTreeItem) => safely('accept the hunk', async () => {
        if (item instanceof HunkTreeItem) {
          await controller.acceptHunk(item.resourceKey, item.hunkId);
        }
      })
    ),
    vscode.commands.registerCommand(
      'cherryDiff.rejectHunk',
      (item?: HunkTreeItem) => safely('reject the hunk', async () => {
        if (item instanceof HunkTreeItem) {
          await controller.rejectHunk(item.resourceKey, item.hunkId);
        }
      })
    ),
    vscode.commands.registerCommand(
      'cherryDiff.acceptAllFile',
      (item?: FileTreeItem) => resolveActiveFile(
        item,
        'accepted',
        controller,
        reviews
      )
    ),
    vscode.commands.registerCommand(
      'cherryDiff.rejectAllFile',
      (item?: FileTreeItem) => resolveActiveFile(
        item,
        'rejected',
        controller,
        reviews
      )
    ),
    vscode.commands.registerCommand('cherryDiff.acceptAll', () => (
      safely('accept all changes', () => controller.resolveAll('accepted'))
    )),
    vscode.commands.registerCommand('cherryDiff.rejectAll', () => (
      safely('reject all changes', () => controller.resolveAll('rejected'))
    )),
    vscode.commands.registerCommand('cherryDiff.editFilters', () => (
      safely('show tracked files', () => (
        vscode.commands.executeCommand('cherryDiffFilters.focus')
      ))
    )),
    vscode.commands.registerCommand('cherryDiff.nextHunk', () => (
      safely('open the next hunk', () => navigateHunk('next', reviews))
    )),
    vscode.commands.registerCommand('cherryDiff.prevHunk', () => (
      safely('open the previous hunk', () => navigateHunk('prev', reviews))
    )),
    vscode.commands.registerCommand('cherryDiff.clearPathOverrides', () => safely(
      'reset file selections',
      async () => {
        if (controller.isInitializing()) {
          vscode.window.showInformationMessage(
            'Cherry Diff: Wait for baseline preparation to finish before resetting file selections.'
          );
          return;
        }
        await filters.clearOverrides();
      }
    )),
  ];

  return vscode.Disposable.from(...disposables);
}

async function resolveActiveFile(
  item: FileTreeItem | undefined,
  resolution: 'accepted' | 'rejected',
  controller: TrackingController,
  reviews: ReviewManager
): Promise<void> {
  await safely(`${resolution === 'accepted' ? 'accept' : 'reject'} the file`, async () => {
    const review = resolveReview(item, reviews);
    if (review) {
      await controller.resolveFile(review.key, resolution);
    }
  });
}

function resolveReview(
  input: FileTreeItem | HunkTreeItem | string | undefined,
  reviews: ReviewManager
) {
  if (input instanceof FileTreeItem || input instanceof HunkTreeItem) {
    return reviews.getFileReview(input.resourceKey);
  }
  if (typeof input === 'string') {
    return reviews.getFileReview(input);
  }

  const editorUri = vscode.window.activeTextEditor?.document.uri;
  if (!editorUri) {
    return undefined;
  }
  const virtualKey = getReviewResourceKey(editorUri);
  return reviews.getFileReview(virtualKey ?? editorUri.toString());
}

async function navigateHunk(
  direction: 'next' | 'prev',
  reviews: ReviewManager
): Promise<void> {
  const pending = reviews.getPendingHunks();
  if (pending.length === 0) {
    return;
  }

  const editor = vscode.window.activeTextEditor;
  const currentLine = editor?.selection.active.line ?? 0;
  const currentKey = editor
    ? getReviewResourceKey(editor.document.uri) ?? editor.document.uri.toString()
    : undefined;
  const indexesInCurrentFile = pending
    .map((entry, index) => ({ entry, index }))
    .filter(({ entry }) => entry.resourceKey === currentKey);

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
  const review = reviews.getFileReview(target.resourceKey);
  if (review) {
    await openDiffForReview(review, getFirstChangedLine(target.hunk.hunk));
  }
}

async function closeResolvedDiffTabs(uris: readonly vscode.Uri[]): Promise<void> {
  if (uris.length === 0) {
    return;
  }
  const expectedOriginals = new Set(
    uris.map((uri) => createReviewDocumentUri(
      BASELINE_DOCUMENT_SCHEME,
      uri
    ).toString())
  );

  const tabs: vscode.Tab[] = [];
  for (const group of vscode.window.tabGroups.all) {
    for (const tab of group.tabs) {
      if (tab.input instanceof vscode.TabInputTextDiff
        && expectedOriginals.has(tab.input.original.toString())) {
        tabs.push(tab);
      }
    }
  }
  if (tabs.length > 0) {
    await vscode.window.tabGroups.close(tabs, true);
  }
}

function updateContextKeys(
  controller: TrackingController,
  reviews: ReviewManager
): void {
  void Promise.all([
    vscode.commands.executeCommand(
      'setContext',
      'cherryDiff.tracking',
      controller.isTracking()
    ),
    vscode.commands.executeCommand(
      'setContext',
      'cherryDiff.initializing',
      controller.isInitializing()
    ),
    vscode.commands.executeCommand(
      'setContext',
      'cherryDiff.reviewActive',
      reviews.getAllFileReviews().size > 0
    ),
  ]).catch((error) => {
    console.error('[Cherry Diff] Failed to update context keys', error);
  });
}

function updateBadge(reviews: ReviewManager): void {
  if (!reviewTreeView) {
    return;
  }
  const count = reviews.getAllFileReviews().size;
  reviewTreeView.badge = count > 0
    ? {
      value: count,
      tooltip: `${count} file${count !== 1 ? 's' : ''} changed`,
    }
    : undefined;
}

async function safely<T>(
  action: string,
  operation: () => PromiseLike<T> | T
): Promise<T | undefined> {
  try {
    return await operation();
  } catch (error) {
    console.error(`[Cherry Diff] Failed to ${action}`, error);
    vscode.window.showErrorMessage(
      `Cherry Diff: Failed to ${action}. ${getErrorMessage(error)}`
    );
    return undefined;
  }
}

export async function deactivate(): Promise<void> {
  const controller = activeController;
  activeController = undefined;
  reviewTreeView = undefined;
  if (controller) {
    try {
      await controller.stopTracking();
    } catch (error) {
      console.error('[Cherry Diff] Failed to remove session baselines', error);
    }
  }
}
