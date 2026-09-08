import * as vscode from 'vscode';
import { BaselineCaptureService, CaptureCancelledError, getCaptureConcurrency } from './baselineCaptureService';
import { BaselineService } from './baselineService';
import { ChangeTracker } from './changeTracker';
import { FilterService } from './filterService';
import { isFileNotFound } from './fileSnapshot';
import { ReviewManager } from './reviewManager';

/** Recovers missed watcher events using discovery and bounded metadata reads. */
export class FileReconciler {
  private readonly signatures = new Map<string, { uri: vscode.Uri; value: string }>();

  constructor(
    private readonly baselines: BaselineService,
    private readonly captures: BaselineCaptureService,
    private readonly filters: FilterService,
    private readonly changes: ChangeTracker,
    private readonly reviews: ReviewManager
  ) {}

  clear(): void {
    this.signatures.clear();
  }

  async reconcile(force: boolean, isCancelled: () => boolean): Promise<void> {
    const current = await this.captures.collectFilteredFiles(undefined, undefined, isCancelled);
    const candidates = new Map([
      ...this.baselines.getBaselineUris(),
      ...[...this.signatures.values()].map((entry) => entry.uri),
      ...[...this.reviews.getAllFileReviews().values()].map((review) => review.uri),
      ...current,
    ].map((uri) => [uri.toString(), uri]));
    const uris = [...candidates.values()];
    const errors: unknown[] = [];
    let nextIndex = 0;

    const worker = async (): Promise<void> => {
      while (!isCancelled()) {
        const uri = uris[nextIndex++];
        if (!uri) {
          return;
        }
        const key = uri.toString();
        if (!this.filters.isIncluded(uri)) {
          this.signatures.delete(key);
          continue;
        }

        try {
          let value: string;
          try {
            const stat = await vscode.workspace.fs.stat(uri);
            value = `${stat.type}:${stat.ctime}:${stat.mtime}:${stat.size}`;
          } catch (error) {
            if (!isFileNotFound(error)) {
              throw error;
            }
            value = 'missing';
          }
          if (isCancelled()) {
            return;
          }
          if (force || this.signatures.get(key)?.value !== value) {
            this.changes.markChange(uri, value === 'missing' ? 'deleted' : 'changed');
          }
          this.signatures.set(key, { uri, value });
        } catch (error) {
          this.changes.markChange(uri);
          errors.push(error);
        }
      }
    };

    await Promise.all(Array.from({ length: Math.min(getCaptureConcurrency(), uris.length) }, worker));
    if (isCancelled()) {
      throw new CaptureCancelledError();
    }
    if (errors.length > 0) {
      throw errors[0];
    }
  }
}
