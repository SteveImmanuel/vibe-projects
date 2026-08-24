import * as vscode from 'vscode';
import { FilterService } from './filterService';

export type ChangeKind = 'created' | 'changed' | 'deleted';

export interface TrackedChange {
  key: string;
  uri: vscode.Uri;
  kind: ChangeKind;
  revision: number;
}

/** Watches workspace resources and records revisioned dirty paths. */
export class ChangeTracker implements vscode.Disposable {
  private readonly changedFiles = new Map<string, TrackedChange>();
  private readonly initializationChanges = new Map<string, TrackedChange>();
  private disposables: vscode.Disposable[] = [];
  private tracking = false;
  private initializing = false;
  private nextRevision = 1;

  private readonly _onDidChangeTrackedFiles = new vscode.EventEmitter<TrackedChange>();
  readonly onDidChangeTrackedFiles = this._onDidChangeTrackedFiles.event;
  private readonly _onDidChangeState = new vscode.EventEmitter<void>();
  readonly onDidChangeState = this._onDidChangeState.event;

  constructor(private readonly filters: FilterService) {}

  beginInitialization(): void {
    this.stopTracking();
    this.initializing = true;
    this.changedFiles.clear();
    this.initializationChanges.clear();
    this.installWatchers();
    this._onDidChangeState.fire();
  }

  finishInitialization(): boolean {
    if (!this.initializing) {
      return false;
    }
    this.initializing = false;
    this.tracking = true;
    this._onDidChangeState.fire();
    return true;
  }

  stopTracking(): void {
    this.tracking = false;
    this.initializing = false;
    this.changedFiles.clear();
    this.initializationChanges.clear();
    for (const disposable of this.disposables) {
      disposable.dispose();
    }
    this.disposables = [];
    this._onDidChangeState.fire();
  }

  markChange(uri: vscode.Uri, kind: ChangeKind = 'changed'): TrackedChange | undefined {
    if (!this.initializing && !this.tracking) {
      return undefined;
    }
    if (!this.shouldTrack(uri)) {
      return undefined;
    }

    const target = this.initializing ? this.initializationChanges : this.changedFiles;
    const key = uri.toString();
    const previous = target.get(key);
    const change: TrackedChange = {
      key,
      uri,
      kind: mergeChangeKinds(previous?.kind, kind),
      revision: this.nextRevision++,
    };
    target.set(key, change);

    if (this.tracking) {
      this._onDidChangeTrackedFiles.fire(change);
    }
    return change;
  }

  takeInitializationChanges(): TrackedChange[] {
    const changes = [...this.initializationChanges.values()];
    this.initializationChanges.clear();
    return changes;
  }

  getChanges(): TrackedChange[] {
    return [...this.changedFiles.values()];
  }

  getChange(key: string): TrackedChange | undefined {
    return this.changedFiles.get(key);
  }

  acknowledge(key: string, revision: number): boolean {
    if (this.changedFiles.get(key)?.revision !== revision) {
      return false;
    }
    return this.changedFiles.delete(key);
  }

  removeChange(uri: vscode.Uri): void {
    const key = uri.toString();
    this.changedFiles.delete(key);
    this.initializationChanges.delete(key);
  }

  shouldTrack(uri: vscode.Uri): boolean {
    return this.filters.isIncluded(uri) || this.filters.isIncluded(uri, true);
  }

  isTracking(): boolean {
    return this.tracking;
  }

  isInitializing(): boolean {
    return this.initializing;
  }

  dispose(): void {
    this.stopTracking();
    this._onDidChangeTrackedFiles.dispose();
    this._onDidChangeState.dispose();
  }

  private installWatchers(): void {
    this.disposables.push(
      vscode.workspace.onDidChangeTextDocument((event) => {
        if (event.contentChanges.length > 0
          && vscode.workspace.getWorkspaceFolder(event.document.uri)) {
          this.markChange(event.document.uri, 'changed');
        }
      })
    );

    const watcher = vscode.workspace.createFileSystemWatcher('**/*');
    this.disposables.push(
      watcher.onDidChange((uri) => this.markChange(uri, 'changed')),
      watcher.onDidCreate((uri) => this.markChange(uri, 'created')),
      watcher.onDidDelete((uri) => this.markChange(uri, 'deleted')),
      watcher
    );
  }
}

function mergeChangeKinds(
  previous: ChangeKind | undefined,
  next: ChangeKind
): ChangeKind {
  if (previous === 'created' && next === 'changed') {
    return 'created';
  }
  if (previous === 'deleted' && next === 'created') {
    return 'changed';
  }
  return next;
}
