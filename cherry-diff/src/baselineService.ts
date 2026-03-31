import * as vscode from 'vscode';

/**
 * Manages file baselines by capturing snapshots when tracking starts.
 * Works with any project (Git, non-Git, no VCS).
 */
export class BaselineService implements vscode.Disposable {
  private baselines = new Map<string, string>(); // fsPath -> baseline content

  /**
   * Capture the current content of a file as its baseline.
   */
  async captureBaseline(uri: vscode.Uri): Promise<void> {
    try {
      const doc = await vscode.workspace.openTextDocument(uri);
      this.baselines.set(uri.fsPath, doc.getText());
    } catch {
      // File might not exist or be readable
    }
  }

  /**
   * Get the baseline content for a file, or undefined if not captured.
   */
  getBaseline(fsPath: string): string | undefined {
    return this.baselines.get(fsPath);
  }

  /**
   * Update the baseline for a file (e.g. after all hunks are resolved).
   */
  updateBaseline(fsPath: string, content: string): void {
    this.baselines.set(fsPath, content);
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
