import * as vscode from 'vscode';
import { globMatch } from './glob';

/**
 * Tracks files modified in the workspace, filtered by include/exclude globs.
 */
export class ChangeTracker implements vscode.Disposable {
  private changedFiles = new Set<string>();
  private disposables: vscode.Disposable[] = [];
  private tracking = false;
  private initializing = false;
  private initializationChanges = new Set<string>();

  private _onDidChangeTrackedFiles = new vscode.EventEmitter<Set<string>>();
  readonly onDidChangeTrackedFiles = this._onDidChangeTrackedFiles.event;

  /** Start watching while the initial disk snapshot is being created. */
  beginInitialization(): void {
    this.stopTracking();
    this.initializing = true;
    this.changedFiles.clear();
    this.initializationChanges.clear();
    this.installWatchers();
  }

  /** Atomically switch already-installed watchers to normal tracking. */
  finishInitialization(): boolean {
    if (!this.initializing) {
      return false;
    }
    this.initializing = false;
    this.tracking = true;
    return true;
  }

  private installWatchers(): void {
    this.disposables.push(
      vscode.workspace.onDidChangeTextDocument((e) => {
        if (e.document.uri.scheme === 'file' && e.contentChanges.length > 0) {
          this.recordChange(e.document.uri);
        }
      })
    );

    const watcher = vscode.workspace.createFileSystemWatcher('**/*');
    this.disposables.push(
      watcher.onDidChange((uri) => this.recordChange(uri)),
      watcher.onDidCreate((uri) => this.recordChange(uri)),
      watcher.onDidDelete((uri) => this.recordChange(uri)),
      watcher
    );
  }

  private recordChange(uri: vscode.Uri): void {
    if (!this.shouldTrack(uri)) {
      return;
    }
    if (this.initializing) {
      this.initializationChanges.add(uri.fsPath);
      return;
    }
    if (this.tracking) {
      this.changedFiles.add(uri.fsPath);
      this._onDidChangeTrackedFiles.fire(this.changedFiles);
    }
  }

  takeInitializationChanges(): Set<string> {
    const changes = new Set(this.initializationChanges);
    this.initializationChanges.clear();
    return changes;
  }

  stopTracking(): void {
    this.tracking = false;
    this.initializing = false;
    this.initializationChanges.clear();
    for (const d of this.disposables) {
      d.dispose();
    }
    this.disposables = [];
  }

  /**
   * Check if a file URI matches the include/exclude filters from settings.
   */
  private shouldTrack(uri: vscode.Uri): boolean {
    const relativePath = vscode.workspace.asRelativePath(uri, false);
    const config = vscode.workspace.getConfiguration('cherryDiff');
    const excludes: string[] = config.get('excludePaths', []);

    for (const pattern of excludes) {
      if (globMatch(relativePath, pattern)) {
        return false;
      }
    }

    const includes: string[] = config.get('includePaths', ['**/*']);
    for (const pattern of includes) {
      if (globMatch(relativePath, pattern)) {
        return true;
      }
    }

    return false;
  }

  getChangedFiles(): Set<string> {
    return new Set(this.changedFiles);
  }

  removeChangedFile(fsPath: string): void {
    this.changedFiles.delete(fsPath);
  }

  clearChangedFiles(): void {
    this.changedFiles.clear();
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
  }
}
