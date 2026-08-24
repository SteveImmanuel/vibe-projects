import * as vscode from 'vscode';

/**
 * Manages file baselines by capturing snapshots when tracking starts.
 * Works with any project (Git, non-Git, no VCS).
 */
export interface BaselineSnapshot {
  content: string;
  exists: boolean;
}

export class BaselineService implements vscode.Disposable {
  private baselines = new Map<string, BaselineSnapshot>(); // fsPath -> baseline state

  /**
   * Capture the current content of a file as its baseline.
   */
  async captureBaseline(uri: vscode.Uri): Promise<void> {
    try {
      const doc = await vscode.workspace.openTextDocument(uri);
      this.baselines.set(uri.fsPath, { content: doc.getText(), exists: true });
    } catch {
      // File might not exist or be readable
    }
  }

  /**
   * Get the baseline content for a file, or undefined if not captured.
   */
  getBaseline(fsPath: string): string | undefined {
    return this.baselines.get(fsPath)?.content;
  }

  /**
   * Get the complete baseline state, including whether the file existed.
   */
  getSnapshot(fsPath: string): BaselineSnapshot | undefined {
    const snapshot = this.baselines.get(fsPath);
    return snapshot ? { ...snapshot } : undefined;
  }

  /**
   * Update the baseline for a file (e.g. after accepting a change).
   */
  updateBaseline(fsPath: string, content: string, exists = true): void {
    this.baselines.set(fsPath, { content, exists });
  }

  /**
   * Check if we have a baseline for this file.
   */
  hasBaseline(fsPath: string): boolean {
    return this.baselines.has(fsPath);
  }

  /**
   * Clear all captured baselines.
   */
  clearBaselines(): void {
    this.baselines.clear();
  }

  dispose(): void {
    this.clearBaselines();
  }
}
