import * as vscode from 'vscode';
import {
  BaselineCaptureService,
  CaptureCancelledError,
  CaptureProgress,
} from './baselineCaptureService';
import { Debouncer, SerialQueue } from './async';
import {
  FILTER_DEBOUNCE_MS,
  MAX_INITIALIZATION_CHANGE_ROUNDS,
  MAX_REVIEW_RETRIES,
  RECONCILE_INTERVAL_MS,
  REVIEW_DEBOUNCE_MS,
  REVIEW_RETRY_DELAY_MS,
} from './constants';
import { BaselineService } from './baselineService';
import { ChangeTracker, TrackedChange } from './changeTracker';
import { FilterService } from './filterService';
import { isFileNotFound } from './fileSnapshot';
import { FileReconciler } from './fileReconciler';
import { ReviewManager } from './reviewManager';
import type { Resolution } from './types';

/** Serializes all state-changing tracking, filtering, and review operations. */
export class TrackingController implements vscode.Disposable {
  private readonly operations = new SerialQueue();
  private generation = 0;
  private desiredTracking = false;
  private initializationPromise: Promise<boolean> | undefined;
  private readonly reviewDebounce = new Debouncer(REVIEW_DEBOUNCE_MS);
  private readonly filterDebounce = new Debouncer(FILTER_DEBOUNCE_MS);
  private readonly retryDebounce = new Debouncer(REVIEW_RETRY_DELAY_MS);
  private readonly reconcileDebounce = new Debouncer(RECONCILE_INTERVAL_MS);
  private readonly reconciler: FileReconciler;
  private reviewRetries = 0;
  private filtersDirty = false;
  private appliedInclusion: (uri: vscode.Uri) => boolean = () => false;
  private readonly disposables: vscode.Disposable[] = [];
  private readonly _onDidChangeState = new vscode.EventEmitter<void>();
  readonly onDidChangeState = this._onDidChangeState.event;

  constructor(
    private readonly baselines: BaselineService,
    private readonly captures: BaselineCaptureService,
    private readonly filters: FilterService,
    private readonly changes: ChangeTracker,
    private readonly reviews: ReviewManager
  ) {
    this.reconciler = new FileReconciler(baselines, captures, filters, changes, reviews);
    this.disposables.push(
      changes.onDidChangeTrackedFiles(() => {
        this.scheduleReview();
        this._onDidChangeState.fire();
      }),
      changes.onDidChangeState(() => this._onDidChangeState.fire()),
      filters.onDidChange(() => this.handleFilterChange()),
      vscode.workspace.onDidChangeWorkspaceFolders(() => this.handleFilterChange()),
      reviews.onDidChangeReview(() => this._onDidChangeState.fire())
    );
  }

  async startTracking(): Promise<boolean> {
    if (this.changes.isTracking()) {
      return true;
    }
    if (this.initializationPromise) {
      return this.initializationPromise;
    }

    this.desiredTracking = true;
    const generation = ++this.generation;
    this.changes.beginInitialization();
    this._onDidChangeState.fire();

    const initialization = this.operations.run(() => this.initialize(generation));
    this.initializationPromise = initialization;
    try {
      return await initialization;
    } finally {
      if (this.initializationPromise === initialization) {
        this.initializationPromise = undefined;
      }
    }
  }

  async stopTracking(): Promise<void> {
    this.desiredTracking = false;
    this.generation++;
    this.reviewDebounce.cancel();
    this.filterDebounce.cancel();
    this.retryDebounce.cancel();
    this.reconcileDebounce.cancel();
    this.changes.stopTracking();
    this._onDidChangeState.fire();

    await this.operations.run(async () => {
      this.reviews.clearReview();
      this.reconciler.clear();
      await this.baselines.deleteSessionStore();
      this._onDidChangeState.fire();
    });
  }

  refreshReview(rescan = true): Promise<number> {
    const generation = this.generation;
    return this.operations.run(async () => {
      if (!this.changes.isTracking() || this.isCancelled(generation)) {
        return this.reviews.getPendingHunks().length;
      }
      if (rescan) {
        this.reviewRetries = 0;
        await this.flushFilters(generation);
        if (this.isCancelled(generation)) {
          return this.reviews.getPendingHunks().length;
        }
        await this.reconciler.reconcile(true, () => this.isCancelled(generation));
      }
      return this.refreshPending(generation);
    });
  }

  acceptHunk(resourceKey: string, hunkId: string): Promise<boolean> {
    return this.enqueueResolution(() => this.reviews.acceptHunk(resourceKey, hunkId));
  }

  rejectHunk(resourceKey: string, hunkId: string): Promise<boolean> {
    return this.enqueueResolution(() => this.reviews.rejectHunk(resourceKey, hunkId));
  }

  resolveFile(resourceKey: string, resolution: Resolution): Promise<boolean> {
    return this.enqueueResolution(() => this.reviews.resolveFile(resourceKey, resolution));
  }

  resolveAll(resolution: Resolution): Promise<void> {
    this.reviewDebounce.cancel();
    const generation = this.generation;
    return this.operations.run(async () => {
      if (!this.changes.isTracking() || this.isCancelled(generation)) {
        return;
      }
      await this.flushFilters(generation);
      if (this.isCancelled(generation)) {
        return;
      }
      await this.reconciler.reconcile(true, () => this.isCancelled(generation));
      await this.refreshPending(generation);
      if (!this.isCancelled(generation)) {
        await this.reviews.resolveAll(resolution);
      }
    });
  }

  getChangedResourceCount(): number {
    const keys = new Set(this.changes.getChanges().map((change) => change.key));
    for (const key of this.reviews.getAllFileReviews().keys()) {
      keys.add(key);
    }
    return keys.size;
  }

  isTracking(): boolean {
    return this.changes.isTracking();
  }

  isInitializing(): boolean {
    return this.changes.isInitializing();
  }

  dispose(): void {
    this.desiredTracking = false;
    this.generation++;
    this.reviewDebounce.cancel();
    this.filterDebounce.cancel();
    this.retryDebounce.cancel();
    this.reconcileDebounce.cancel();
    this.reconciler.clear();
    for (const disposable of this.disposables) {
      disposable.dispose();
    }
    this._onDidChangeState.dispose();
  }

  private async initialize(generation: number): Promise<boolean> {
    const isCancelled = (): boolean => this.isCancelled(generation);

    try {
      this.reviews.clearReview();
      this.reconciler.clear();
      this.reviewRetries = 0;
      this.filtersDirty = false;
      this.appliedInclusion = this.filters.captureInclusion();
      await this.baselines.clearBaselines();

      await this.withCaptureProgress(
        'Cherry Diff: Preparing baselines',
        () => {
          this.desiredTracking = false;
          this.generation++;
          this.changes.stopTracking();
          this._onDidChangeState.fire();
        },
        async (progress, token) => {
          await this.captures.captureFilteredBaselines(progress, token, isCancelled);

          for (let round = 0; ; round++) {
            const pendingChanges = this.changes.takeInitializationChanges();
            if (pendingChanges.length === 0) {
              break;
            }
            if (round >= MAX_INITIALIZATION_CHANGE_ROUNDS) {
              throw new Error(
                'Workspace files did not become stable while baselines were being prepared.'
              );
            }
            const uris = await this.expandInitializationChanges(
              pendingChanges,
              progress,
              token,
              isCancelled
            );
            await this.captures.captureUntilStable(uris, progress, token, isCancelled);
          }
        }
      );

      if (isCancelled()) {
        throw new CaptureCancelledError();
      }
      this.baselines.markComplete();
      if (!this.changes.finishInitialization()) {
        throw new CaptureCancelledError();
      }
      this._onDidChangeState.fire();
      this.scheduleReconciliation(generation);
      console.log(
        `[Cherry Diff] ${this.baselines.getBaselineCount()} baselines ready.`
      );
      return true;
    } catch (error) {
      this.changes.stopTracking();
      await this.baselines.deleteSessionStore();
      if (!(error instanceof CaptureCancelledError) && !isCancelled()) {
        this.desiredTracking = false;
        console.error('[Cherry Diff] Failed to prepare baselines', error);
        vscode.window.showErrorMessage(
          `Cherry Diff: Tracking was not started. ${getErrorMessage(error)}`
        );
      }
      this._onDidChangeState.fire();
      return false;
    }
  }

  private async synchronizeFilters(generation: number): Promise<void> {
    if (!this.changes.isTracking() || this.isCancelled(generation)) {
      return;
    }

    const previousInclusion = this.appliedInclusion;
    const nextInclusion = this.filters.captureInclusion();
    const captured: vscode.Uri[] = [];
    this.filtersDirty = false;
    for (const uri of this.baselines.getBaselineUris()) {
      if (!this.filters.isIncluded(uri)) {
        this.baselines.removeBaseline(uri);
        this.changes.removeChange(uri);
      }
    }
    this.reviews.removeReviews((review) => !this.filters.isIncluded(review.uri));

    try {
      await this.withCaptureProgress(
        'Cherry Diff: Updating tracked files',
        () => {
          void this.stopTracking();
        },
        (progress, token) => this.captures.captureFilteredBaselines(
          progress,
          token,
          () => this.isCancelled(generation),
          (uri) => {
            if (this.baselines.hasBaseline(uri) || !nextInclusion(uri)) {
              return false;
            }
            if (previousInclusion(uri)) {
              this.changes.markChange(uri, 'created');
              return false;
            }
            captured.push(uri);
            return true;
          }
        )
      );
      if (!this.isCancelled(generation)) {
        this.appliedInclusion = nextInclusion;
        for (const uri of captured) {
          this.changes.markChange(uri);
        }
        await this.refreshPending(generation);
      }
    } catch (error) {
      if (!(error instanceof CaptureCancelledError) && !this.isCancelled(generation)) {
        console.error('[Cherry Diff] Failed to synchronize filters', error);
        vscode.window.showErrorMessage(
          `Cherry Diff: Updated filters could not be applied safely. Tracking was stopped. ${getErrorMessage(error)}`
        );
        void this.stopTracking();
      }
    }
  }

  private async withCaptureProgress(
    title: string,
    onCancel: () => void,
    body: (progress: CaptureProgress, token: vscode.CancellationToken) => Promise<void>
  ): Promise<void> {
    await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title,
        cancellable: true,
      },
      async (progress, token) => {
        const cancellationSubscription = token.onCancellationRequested(onCancel);
        try {
          await body(progress, token);
        } finally {
          cancellationSubscription.dispose();
        }
      }
    );
  }

  /** True for a directory, or a deleted path that had descendant baselines. */
  private async isDirectoryChange(uri: vscode.Uri): Promise<boolean> {
    try {
      const stat = await vscode.workspace.fs.stat(uri);
      return (stat.type & vscode.FileType.Directory) !== 0;
    } catch (error) {
      if (!isFileNotFound(error)) {
        throw error;
      }
      return !this.baselines.hasBaseline(uri)
        && this.baselines.getBaselineUrisUnder(uri).length > 0;
    }
  }

  private async expandInitializationChanges(
    pendingChanges: readonly TrackedChange[],
    progress: CaptureProgress,
    token: vscode.CancellationToken,
    isCancelled: () => boolean
  ): Promise<vscode.Uri[]> {
    const uris = new Map<string, vscode.Uri>();

    for (const change of pendingChanges) {
      if (!await this.isDirectoryChange(change.uri)) {
        if (this.filters.isIncluded(change.uri)) {
          uris.set(change.key, change.uri);
        }
        continue;
      }

      for (const uri of this.baselines.getBaselineUrisUnder(change.uri)) {
        uris.set(uri.toString(), uri);
      }
      const currentFiles = await this.captures.collectFilesRecursively(
        [change.uri],
        progress,
        token,
        isCancelled
      );
      for (const uri of currentFiles) {
        if (this.filters.isIncluded(uri)) {
          uris.set(uri.toString(), uri);
        }
      }
    }

    return [...uris.values()];
  }

  private async expandDirectoryChanges(generation: number): Promise<void> {
    for (const change of this.changes.getChanges()) {
      if (this.isCancelled(generation)) {
        return;
      }
      if (!await this.isDirectoryChange(change.uri)) {
        continue;
      }
      if (!change.structural) {
        // Ordinary directory updates accompany child events. Structural
        // events must still expand after a delete/create pair is coalesced.
        this.changes.acknowledge(change.key, change.revision);
        continue;
      }

      for (const uri of this.baselines.getBaselineUrisUnder(change.uri)) {
        if (this.filters.isIncluded(uri)) {
          this.changes.markChange(uri, change.kind);
        }
      }
      if (change.kind !== 'deleted') {
        const files = await this.captures.collectFilesRecursively(
          [change.uri],
          undefined,
          undefined,
          () => this.isCancelled(generation)
        );
        for (const uri of files) {
          if (this.filters.isIncluded(uri)) {
            this.changes.markChange(uri, change.kind);
          }
        }
      }
      this.changes.acknowledge(change.key, change.revision);
    }
  }

  private handleFilterChange(): void {
    if (this.changes.isInitializing()) {
      vscode.window.showInformationMessage(
        'Cherry Diff: Baseline preparation was cancelled because tracked-file filters changed. Start tracking again when selections are ready.'
      );
      void this.stopTracking();
      return;
    }
    if (!this.changes.isTracking()) {
      return;
    }

    this.filtersDirty = true;
    const generation = this.generation;
    this.filterDebounce.schedule(() => {
      void this.operations.run(() => this.flushFilters(generation)).catch((error) => {
        this.reportOperationError('apply tracked-file filters', error);
      });
    });
  }

  private async flushFilters(generation: number): Promise<void> {
    while (this.filtersDirty && !this.isCancelled(generation)) {
      this.filterDebounce.cancel();
      await this.synchronizeFilters(generation);
    }
  }

  private scheduleReview(): void {
    if (!this.changes.isTracking()) {
      return;
    }
    this.reviewRetries = 0;
    this.reviewDebounce.schedule(() => {
      void this.refreshReview(false).catch((error) => {
        this.reportOperationError('refresh the review', error);
      });
    });
  }

  private async refreshPending(generation: number): Promise<number> {
    try {
      await this.expandDirectoryChanges(generation);
      if (!this.isCancelled(generation)) {
        return await this.reviews.refreshDirty();
      }
      return this.reviews.getPendingHunks().length;
    } finally {
      if (!this.isCancelled(generation) && this.changes.getChanges().length > 0) {
        if (this.reviewRetries < MAX_REVIEW_RETRIES) {
          this.reviewRetries++;
          this.retryDebounce.schedule(() => {
            void this.refreshReview(false).catch((error) => this.reportOperationError('retry the review', error));
          });
        }
      } else {
        this.retryDebounce.cancel();
        this.reviewRetries = 0;
      }
    }
  }

  private scheduleReconciliation(generation: number): void {
    if (this.isCancelled(generation)) {
      return;
    }
    this.reconcileDebounce.schedule(() => {
      void this.operations.run(async () => {
        if (!this.isCancelled(generation)) {
          await this.flushFilters(generation);
          if (this.isCancelled(generation)) {
            return;
          }
          await this.reconciler.reconcile(false, () => this.isCancelled(generation));
          await this.refreshPending(generation);
        }
      }).catch((error) => {
        if (!this.isCancelled(generation)) {
          this.reportOperationError('check for missed file changes', error);
        }
      }).finally(() => this.scheduleReconciliation(generation));
    });
  }

  private isCancelled(generation: number): boolean {
    return generation !== this.generation || !this.desiredTracking;
  }

  private enqueueResolution(operation: () => Promise<boolean>): Promise<boolean> {
    const generation = this.generation;
    return this.operations.run(async () => {
      if (this.filtersDirty) {
        await this.flushFilters(generation);
      }
      return this.changes.isTracking() && generation === this.generation
        ? operation()
        : false;
    });
  }

  private reportOperationError(action: string, error: unknown): void {
    console.error(`[Cherry Diff] Failed to ${action}`, error);
    vscode.window.showErrorMessage(
      `Cherry Diff: Failed to ${action}. ${getErrorMessage(error)}`
    );
  }
}

export function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
