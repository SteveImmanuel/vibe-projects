import * as vscode from 'vscode';
import { globMatch } from './glob';

/**
 * Tracks files modified in the workspace, filtered by include/exclude globs.
 */
export class ChangeTracker implements vscode.Disposable {
  private changedFiles = new Set<string>();
  private disposables: vscode.Disposable[] = [];
  private tracking = false;

  private _onDidChangeTrackedFiles = new vscode.EventEmitter<Set<string>>();
  readonly onDidChangeTrackedFiles = this._onDidChangeTrackedFiles.event;

  startTracking(): void {
    if (this.tracking) {
      return;
    }
    this.tracking = true;
    this.changedFiles.clear();

    this.disposables.push(
      vscode.workspace.onDidChangeTextDocument((e) => {
        if (e.document.uri.scheme === 'file' && e.contentChanges.length > 0) {
          if (this.shouldTrack(e.document.uri)) {
            this.changedFiles.add(e.document.uri.fsPath);
            this._onDidChangeTrackedFiles.fire(this.changedFiles);
          }
        }
      })
    );

    const watcher = vscode.workspace.createFileSystemWatcher('**/*');
    this.disposables.push(
      watcher.onDidChange((uri) => {
        if (this.shouldTrack(uri)) {
          this.changedFiles.add(uri.fsPath);
          this._onDidChangeTrackedFiles.fire(this.changedFiles);
        }
      }),
      watcher.onDidCreate((uri) => {
        if (this.shouldTrack(uri)) {
          this.changedFiles.add(uri.fsPath);
          this._onDidChangeTrackedFiles.fire(this.changedFiles);
        }
      }),
      watcher.onDidDelete((uri) => {
        if (this.shouldTrack(uri)) {
          this.changedFiles.add(uri.fsPath);
          this._onDidChangeTrackedFiles.fire(this.changedFiles);
        }
      }),
      watcher
    );
  }

  stopTracking(): void {
    this.tracking = false;
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

  dispose(): void {
    this.stopTracking();
    this._onDidChangeTrackedFiles.dispose();
  }
}
