import * as vscode from 'vscode';
import { BaselineCaptureService, CaptureCancelledError } from './baselineCaptureService';
import {
  FILTER_DEBOUNCE_MS,
  MAX_INITIALIZATION_CHANGE_ROUNDS,
  REVIEW_DEBOUNCE_MS,
} from './constants';
import { BaselineService } from './baselineService';
import { ChangeTracker, TrackedChange } from './changeTracker';
import { FilterService } from './filterService';
import { isFileNotFound } from './fileSnapshot';
import { ReviewManager } from './reviewManager';
import type { Resolution } from './types';

/** Serializes all state-changing tracking, filtering, and review operations. */
export class TrackingController implements vscode.Disposable {
  private operationTail: Promise<void> = Promise.resolve();
  private generation = 0;
  private desiredTracking = false;
  private initializationPromise: Promise<boolean> | undefined;
  private reviewTimer: ReturnType<typeof setTimeout> | undefined;
  private filterTimer: ReturnType<typeof setTimeout> | undefined;
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

    const initialization = this.enqueue(() => this.initialize(generation));
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
    this.clearTimers();
    this.changes.stopTracking();
    this._onDidChangeState.fire();

    await this.enqueue(async () => {
      this.reviews.clearReview();
      await this.baselines.deleteSessionStore();
      this._onDidChangeState.fire();
    });
  }

  refreshReview(): Promise<number> {
    return this.enqueue(async () => {
      if (!this.changes.isTracking()) {
        return this.reviews.getPendingHunks().length;
      }
      await this.expandDirectoryChanges(this.generation);
      return this.reviews.refreshDirty();
    });
  }

  acceptHunk(resourceKey: string, hunkId: string): Promise<boolean> {
    const generation = this.generation;
    return this.enqueue(() => this.changes.isTracking() && generation === this.generation
      ? this.reviews.acceptHunk(resourceKey, hunkId)
      : Promise.resolve(false));
  }

  rejectHunk(resourceKey: string, hunkId: string): Promise<boolean> {
    const generation = this.generation;
    return this.enqueue(() => this.changes.isTracking() && generation === this.generation
      ? this.reviews.rejectHunk(resourceKey, hunkId)
      : Promise.resolve(false));
  }

  resolveFile(resourceKey: string, resolution: Resolution): Promise<boolean> {
    const generation = this.generation;
    return this.enqueue(() => this.changes.isTracking() && generation === this.generation
      ? this.reviews.resolveFile(resourceKey, resolution)
      : Promise.resolve(false));
  }

  resolveAll(resolution: Resolution): Promise<void> {
    this.clearReviewTimer();
    return this.enqueue(async () => {
      if (!this.changes.isTracking()) {
        return;
      }
      await this.expandDirectoryChanges(this.generation);
      await this.reviews.refreshDirty();
      await this.reviews.resolveAll(resolution);
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

  async shutdown(): Promise<void> {
    this.desiredTracking = false;
    this.generation++;
    this.clearTimers();
    this.changes.stopTracking();
    await this.enqueue(async () => {
      this.reviews.clearReview();
      await this.baselines.deleteSessionStore();
    });
  }

  dispose(): void {
    this.desiredTracking = false;
    this.generation++;
    this.clearTimers();
    for (const disposable of this.disposables) {
      disposable.dispose();
    }
    this._onDidChangeState.dispose();
  }

  private async initialize(generation: number): Promise<boolean> {
    const cancellationSource = new vscode.CancellationTokenSource();
    const isCancelled = (): boolean => this.isCancelled(generation);

    try {
      this.reviews.clearReview();
      await this.baselines.clearBaselines();

      await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: 'Cherry Diff: Preparing baselines',
          cancellable: true,
        },
        async (progress, token) => {
          const cancellationSubscription = token.onCancellationRequested(() => {
            this.desiredTracking = false;
            this.generation++;
            this.changes.stopTracking();
            cancellationSource.cancel();
            this._onDidChangeState.fire();
          });
          try {
            await this.captures.captureFilteredBaselines(
              progress,
              cancellationSource.token,
              isCancelled
            );

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
                cancellationSource.token,
                isCancelled
              );
              await this.captures.captureUntilStable(
                uris,
                progress,
                cancellationSource.token,
                isCancelled
              );
            }
          } finally {
            cancellationSubscription.dispose();
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
    } finally {
      cancellationSource.dispose();
    }
  }

  private async synchronizeFilters(generation: number): Promise<void> {
    if (!this.changes.isTracking() || this.isCancelled(generation)) {
      return;
    }

    for (const uri of this.baselines.getBaselineUris()) {
      if (!this.filters.isIncluded(uri)) {
        this.baselines.removeBaseline(uri, false);
        this.changes.removeChange(uri);
      }
    }
    this.reviews.removeReviews((review) => !this.filters.isIncluded(review.uri));

    try {
      await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: 'Cherry Diff: Updating tracked files',
          cancellable: true,
        },
        async (progress, token) => {
          const cancellationSubscription = token.onCancellationRequested(() => {
            void this.stopTracking();
          });
          try {
            await this.captures.captureFilteredBaselines(
              progress,
              token,
              () => this.isCancelled(generation),
              true
            );
          } finally {
            cancellationSubscription.dispose();
          }
        }
      );
      await this.expandDirectoryChanges(generation);
      await this.reviews.refreshDirty();
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

  private async expandInitializationChanges(
    pendingChanges: readonly TrackedChange[],
    progress: vscode.Progress<{ message?: string; increment?: number }>,
    token: vscode.CancellationToken,
    isCancelled: () => boolean
  ): Promise<vscode.Uri[]> {
    const uris = new Map<string, vscode.Uri>();

    for (const change of pendingChanges) {
      const baselineUris = this.baselines.getBaselineUrisUnder(change.uri);
      let isDirectory = false;
      try {
        const stat = await vscode.workspace.fs.stat(change.uri);
        isDirectory = (stat.type & vscode.FileType.Directory) !== 0;
      } catch (error) {
        if (!isFileNotFound(error)) {
          throw error;
        }
        isDirectory = !this.baselines.hasBaseline(change.uri) && baselineUris.length > 0;
      }

      if (isDirectory) {
        for (const uri of baselineUris) {
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
      } else {
        uris.set(change.key, change.uri);
      }
    }

    return [...uris.values()];
  }

  private async expandDirectoryChanges(generation: number): Promise<void> {
    for (const change of this.changes.getChanges()) {
      if (this.isCancelled(generation)) {
        return;
      }

      const baselineUris = this.baselines.getBaselineUrisUnder(change.uri);
      const hasExactBaseline = this.baselines.hasBaseline(change.uri);
      let isDirectory = false;
      try {
        const stat = await vscode.workspace.fs.stat(change.uri);
        isDirectory = (stat.type & vscode.FileType.Directory) !== 0;
      } catch (error) {
        if (!isFileNotFound(error)) {
          throw error;
        }
        isDirectory = !hasExactBaseline && baselineUris.length > 0;
      }

      if (!isDirectory) {
        continue;
      }
      if (change.kind === 'changed') {
        // Child file events carry the actionable path. Some providers also
        // emit a parent-directory change; rescanning its whole subtree would
        // turn one edit into an O(workspace) review.
        this.changes.acknowledge(change.key, change.revision);
        continue;
      }

      for (const uri of baselineUris) {
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

    if (this.filterTimer) {
      clearTimeout(this.filterTimer);
    }
    const generation = this.generation;
    this.filterTimer = setTimeout(() => {
      this.filterTimer = undefined;
      void this.enqueue(() => this.synchronizeFilters(generation)).catch((error) => {
        this.reportOperationError('apply tracked-file filters', error);
      });
    }, FILTER_DEBOUNCE_MS);
  }

  private scheduleReview(): void {
    if (!this.changes.isTracking()) {
      return;
    }
    this.clearReviewTimer();
    this.reviewTimer = setTimeout(() => {
      this.reviewTimer = undefined;
      void this.refreshReview().catch((error) => {
        this.reportOperationError('refresh the review', error);
      });
    }, REVIEW_DEBOUNCE_MS);
  }

  private clearTimers(): void {
    this.clearReviewTimer();
    if (this.filterTimer) {
      clearTimeout(this.filterTimer);
      this.filterTimer = undefined;
    }
  }

  private clearReviewTimer(): void {
    if (this.reviewTimer) {
      clearTimeout(this.reviewTimer);
      this.reviewTimer = undefined;
    }
  }

  private isCancelled(generation: number): boolean {
    return generation !== this.generation || !this.desiredTracking;
  }

  private enqueue<T>(operation: () => Promise<T>): Promise<T> {
    const result = this.operationTail.then(operation, operation);
    this.operationTail = result.then(() => undefined, () => undefined);
    return result;
  }

  private reportOperationError(action: string, error: unknown): void {
    console.error(`[Cherry Diff] Failed to ${action}`, error);
    vscode.window.showErrorMessage(
      `Cherry Diff: Failed to ${action}. ${getErrorMessage(error)}`
    );
  }
}

function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
