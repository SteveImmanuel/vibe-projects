import * as vscode from 'vscode';
import { ChangeTracker } from './changeTracker';
import { ReviewManager } from './reviewManager';

export class ControlsViewProvider implements vscode.WebviewViewProvider {
  public static readonly viewType = 'cherryDiffControls';

  private _view?: vscode.WebviewView;

  constructor(
    private changeTracker: ChangeTracker,
    private reviewManager: ReviewManager
  ) {
    changeTracker.onDidChangeTrackedFiles(() => this.updateView());
    reviewManager.onDidChangeReview(() => this.updateView());
  }

  resolveWebviewView(webviewView: vscode.WebviewView): void {
    this._view = webviewView;

    webviewView.webview.options = {
      enableScripts: true,
    };

    webviewView.webview.onDidReceiveMessage((message) => {
      switch (message.command) {
        case 'startReview':
          vscode.commands.executeCommand('cherryDiff.startReview');
          break;
        case 'enableTracking':
          vscode.commands.executeCommand('cherryDiff.enableTracking');
          break;
        case 'disableTracking':
          vscode.commands.executeCommand('cherryDiff.disableTracking');
          break;
        case 'resetBaseline':
          vscode.commands.executeCommand('cherryDiff.resetBaseline');
          break;
        case 'editFilters':
          vscode.commands.executeCommand('cherryDiff.editFilters');
          break;
      }
    });

    this.updateView();
  }

  updateView(): void {
    if (!this._view) {
      return;
    }

    const isTracking = this.changeTracker.isTracking();
    const changedCount = this.changeTracker.getChangedFiles().size;
    const pendingHunks = this.reviewManager.getAllPendingHunks().length;

    this._view.webview.html = this.getHtml(isTracking, changedCount, pendingHunks);
  }

  private getHtml(isTracking: boolean, changedCount: number, pendingHunks: number): string {
    const trackingStatus = isTracking
      ? `Tracking active &middot; ${changedCount} file${changedCount !== 1 ? 's' : ''} changed`
      : 'Tracking disabled';

    const pendingStatus = pendingHunks > 0
      ? `${pendingHunks} hunk${pendingHunks !== 1 ? 's' : ''} pending`
      : '';

    return /* html */ `<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      padding: 8px 12px;
      font-family: var(--vscode-font-family);
      font-size: var(--vscode-font-size);
      color: var(--vscode-foreground);
    }
    .status {
      font-size: 11px;
      color: var(--vscode-descriptionForeground);
      margin-bottom: 10px;
    }
    .status .highlight {
      color: var(--vscode-foreground);
    }
    .btn-row {
      display: flex;
      gap: 6px;
      margin-bottom: 6px;
    }
    button {
      flex: 1;
      padding: 6px 10px;
      border: 1px solid var(--vscode-button-border, transparent);
      border-radius: 3px;
      font-family: var(--vscode-font-family);
      font-size: 12px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 5px;
    }
    .btn-primary {
      background: var(--vscode-button-background);
      color: var(--vscode-button-foreground);
    }
    .btn-primary:hover {
      background: var(--vscode-button-hoverBackground);
    }
    .btn-secondary {
      background: var(--vscode-button-secondaryBackground);
      color: var(--vscode-button-secondaryForeground);
    }
    .btn-secondary:hover {
      background: var(--vscode-button-secondaryHoverBackground);
    }
    .btn-danger {
      background: var(--vscode-inputValidation-errorBackground, #5a1d1d);
      color: var(--vscode-errorForeground, #f48771);
      border: 1px solid var(--vscode-inputValidation-errorBorder, #be1100);
    }
    .btn-danger:hover {
      opacity: 0.9;
    }
  </style>
</head>
<body>
  <div class="status">
    ${trackingStatus}${pendingStatus ? ` &middot; <span class="highlight">${pendingStatus}</span>` : ''}
  </div>

  <div class="btn-row">
    ${isTracking
      ? `<button class="btn-primary" onclick="send('startReview')" title="Check for new file changes and update the review list">Refresh</button>
         <button class="btn-danger" onclick="send('disableTracking')" title="Stop watching for file changes and clear all baselines">Stop Tracking</button>`
      : `<button class="btn-primary" onclick="send('enableTracking')" title="Start watching for file changes and capture current file states as baselines">Start Tracking</button>`
    }
  </div>

  ${isTracking ? `
  <div class="btn-row">
    <button class="btn-secondary" onclick="send('resetBaseline')" title="Accept all pending changes and set the current file states as the new baseline">Accept All</button>
    <button class="btn-secondary" onclick="send('editFilters')" title="Configure which files and directories to include or exclude from tracking">Filters</button>
  </div>
  ` : ''}

  <script>
    const vscode = acquireVsCodeApi();
    function send(command) {
      vscode.postMessage({ command });
    }
  </script>
</body>
</html>`;
  }
}
