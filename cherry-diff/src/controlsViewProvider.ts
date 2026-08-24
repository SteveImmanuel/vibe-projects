import { randomUUID } from 'crypto';
import * as vscode from 'vscode';
import { ReviewManager } from './reviewManager';
import { TrackingController } from './trackingController';

interface ControlsState {
  tracking: boolean;
  initializing: boolean;
  changedResources: number;
  pendingHunks: number;
}

export class ControlsViewProvider implements vscode.WebviewViewProvider, vscode.Disposable {
  static readonly viewType = 'cherryDiffControls';

  private view?: vscode.WebviewView;
  private lastStateKey: string | undefined;
  private readonly disposables: vscode.Disposable[];

  constructor(
    private readonly controller: TrackingController,
    private readonly reviews: ReviewManager
  ) {
    this.disposables = [
      controller.onDidChangeState(() => this.updateView()),
    ];
  }

  resolveWebviewView(webviewView: vscode.WebviewView): void {
    this.view = webviewView;
    this.lastStateKey = undefined;
    webviewView.webview.options = { enableScripts: true };

    this.disposables.push(webviewView.webview.onDidReceiveMessage(
      (message: { command?: unknown }) => {
        if (typeof message.command !== 'string') {
          return;
        }
        const command = {
          enableTracking: 'cherryDiff.enableTracking',
          disableTracking: 'cherryDiff.disableTracking',
          acceptAll: 'cherryDiff.acceptAll',
          rejectAll: 'cherryDiff.rejectAll',
        }[message.command];
        if (command) {
          void vscode.commands.executeCommand(command).then(undefined, (error) => {
            console.error(`[Cherry Diff] Failed to execute ${command}`, error);
          });
        }
      }
    ));

    this.updateView();
  }

  updateView(): void {
    if (!this.view) {
      return;
    }

    const state: ControlsState = {
      tracking: this.controller.isTracking(),
      initializing: this.controller.isInitializing(),
      changedResources: this.controller.getChangedResourceCount(),
      pendingHunks: this.reviews.getPendingHunks().length,
    };
    const stateKey = JSON.stringify(state);
    if (stateKey === this.lastStateKey) {
      return;
    }
    this.lastStateKey = stateKey;
    this.view.webview.html = this.getHtml(this.view.webview, state);
  }

  dispose(): void {
    for (const disposable of this.disposables) {
      disposable.dispose();
    }
    this.view = undefined;
  }

  private getHtml(webview: vscode.Webview, state: ControlsState): string {
    const nonce = randomUUID().replace(/-/g, '');
    const trackingStatus = state.initializing
      ? 'Preparing disk-backed baselines'
      : state.tracking
        ? `Tracking active &middot; ${state.changedResources} file${state.changedResources !== 1 ? 's' : ''} changed`
        : 'Tracking disabled';
    const pendingStatus = state.pendingHunks > 0
      ? `${state.pendingHunks} hunk${state.pendingHunks !== 1 ? 's' : ''} pending`
      : '';
    const bulkActionsDisabled = state.changedResources === 0 && state.pendingHunks === 0
      ? ' disabled'
      : '';

    return /* html */ `<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}';">
  <style>
    body {
      padding: 8px 12px;
      font-family: var(--vscode-font-family);
      font-size: var(--vscode-font-size);
      color: var(--vscode-foreground);
    }
    .status {
      margin-bottom: 10px;
      color: var(--vscode-descriptionForeground);
      font-size: 11px;
    }
    .status .highlight { color: var(--vscode-foreground); }
    .btn-row {
      display: flex;
      gap: 6px;
      margin-bottom: 6px;
    }
    button {
      display: flex;
      flex: 1;
      align-items: center;
      justify-content: center;
      padding: 6px 10px;
      border: 1px solid var(--vscode-button-border, transparent);
      border-radius: 3px;
      font-family: var(--vscode-font-family);
      font-size: 12px;
      cursor: pointer;
    }
    button:disabled { cursor: default; opacity: 0.7; }
    .btn-primary {
      background: var(--vscode-button-background);
      color: var(--vscode-button-foreground);
    }
    .btn-primary:hover { background: var(--vscode-button-hoverBackground); }
    .btn-danger, .btn-reject {
      background: #8b2a2a;
      color: #fff;
    }
    .btn-danger:hover, .btn-reject:hover { background: #a33232; }
    .btn-accept {
      border-color: #238636;
      background: #1a7f37;
      color: #fff;
    }
    .btn-accept:hover { background: #238636; }
  </style>
</head>
<body>
  <div class="status">
    ${trackingStatus}${pendingStatus ? ` &middot; <span class="highlight">${pendingStatus}</span>` : ''}
  </div>

  ${state.initializing
    ? `
  <div class="btn-row">
    <button class="btn-danger" data-command="disableTracking" title="Cancel baseline preparation">Stop Tracking</button>
  </div>`
    : state.tracking
      ? `
  <div class="btn-row">
    <button class="btn-danger" data-command="disableTracking" title="Stop watching for changes and clear this session's baselines">Stop Tracking</button>
  </div>
  <div class="btn-row">
    <button class="btn-accept" data-command="acceptAll" title="Accept every pending change"${bulkActionsDisabled}>Accept All</button>
    <button class="btn-reject" data-command="rejectAll" title="Revert every pending change to its baseline"${bulkActionsDisabled}>Reject All</button>
  </div>`
      : `
  <div class="btn-row">
    <button class="btn-primary" data-command="enableTracking" title="Capture baselines and start watching for changes">Start Tracking</button>
  </div>`}

  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    document.addEventListener('click', (event) => {
      const command = event.target.dataset.command;
      if (command) { vscode.postMessage({ command }); }
    });
  </script>
</body>
</html>`;
  }
}
