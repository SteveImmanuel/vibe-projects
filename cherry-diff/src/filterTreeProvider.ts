import * as vscode from 'vscode';
import { FILTER_TREE_REFRESH_DEBOUNCE_MS } from './constants';
import { FilterService } from './filterService';

export class FilterTreeItem extends vscode.TreeItem {
  constructor(
    filterService: FilterService,
    public readonly uri: vscode.Uri,
    public readonly isDirectory: boolean,
    public readonly isWorkspaceRoot = false,
    public readonly isSymbolicLink = false,
    label?: string
  ) {
    super(
      label ?? uri.path.split('/').filter(Boolean).pop() ?? uri.toString(),
      isDirectory
        ? vscode.TreeItemCollapsibleState.Collapsed
        : vscode.TreeItemCollapsibleState.None
    );

    this.resourceUri = uri;
    this.id = `filter:${uri.toString()}`;
    const included = filterService.isIncluded(uri, isDirectory);
    this.checkboxState = included
      ? vscode.TreeItemCheckboxState.Checked
      : vscode.TreeItemCheckboxState.Unchecked;
    this.tooltip = `${filterService.getDisplayPath(uri)} — ${included ? 'included' : 'excluded'}`;

    if (isWorkspaceRoot) {
      this.iconPath = new vscode.ThemeIcon('root-folder');
      this.collapsibleState = vscode.TreeItemCollapsibleState.Expanded;
    } else if (isSymbolicLink) {
      this.description = 'symbolic link';
    }
  }
}

/** Explorer-style workspace tree for visual include/exclude selections. */
export class FilterTreeProvider implements vscode.TreeDataProvider<FilterTreeItem>, vscode.Disposable {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<FilterTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly disposables: vscode.Disposable[] = [];
  private refreshTimer: ReturnType<typeof setTimeout> | undefined;

  constructor(private readonly filterService: FilterService) {
    this.disposables.push(
      filterService.onDidChange(() => this.refresh()),
      vscode.workspace.onDidChangeWorkspaceFolders(() => this.refresh())
    );

    const watcher = vscode.workspace.createFileSystemWatcher('**/*');
    this.disposables.push(
      watcher.onDidCreate(() => this.scheduleRefresh()),
      watcher.onDidDelete(() => this.scheduleRefresh()),
      watcher,
    );
  }

  getTreeItem(element: FilterTreeItem): vscode.TreeItem {
    return element;
  }

  async getChildren(element?: FilterTreeItem): Promise<FilterTreeItem[]> {
    const workspaceFolders = vscode.workspace.workspaceFolders ?? [];
    if (!element) {
      return workspaceFolders.map((folder) => this.createItem(
        folder.uri,
        true,
        true,
        false,
        folder.name
      ));
    }

    if (!element.isDirectory || element.isSymbolicLink) {
      return [];
    }
    return this.readDirectory(element.uri);
  }

  async applyCheckboxChanges(
    changes: ReadonlyArray<[FilterTreeItem, vscode.TreeItemCheckboxState]>
  ): Promise<void> {
    await this.filterService.updateOverrides(
      changes.map(([item, state]) => ({
        uri: item.uri,
        included: state === vscode.TreeItemCheckboxState.Checked,
        recursive: item.isDirectory,
      }))
    );
  }

  refresh(): void {
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
      this.refreshTimer = undefined;
    }
    this._onDidChangeTreeData.fire(undefined);
  }

  dispose(): void {
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
    }
    for (const disposable of this.disposables) {
      disposable.dispose();
    }
    this._onDidChangeTreeData.dispose();
  }

  private scheduleRefresh(): void {
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
    }
    this.refreshTimer = setTimeout(() => {
      this.refreshTimer = undefined;
      this._onDidChangeTreeData.fire(undefined);
    }, FILTER_TREE_REFRESH_DEBOUNCE_MS);
  }

  private async readDirectory(uri: vscode.Uri): Promise<FilterTreeItem[]> {
    try {
      const entries = await vscode.workspace.fs.readDirectory(uri);
      return entries
        .map(([name, type]) => {
          const isSymbolicLink = (type & vscode.FileType.SymbolicLink) !== 0;
          const isDirectory = (type & vscode.FileType.Directory) !== 0;
          return {
            name,
            item: this.createItem(
              vscode.Uri.joinPath(uri, name),
              isDirectory,
              false,
              isSymbolicLink,
              name
            ),
          };
        })
        .sort((left, right) => {
          if (left.item.isDirectory !== right.item.isDirectory) {
            return left.item.isDirectory ? -1 : 1;
          }
          return left.name.localeCompare(right.name, undefined, { sensitivity: 'base' });
        })
        .map(({ item }) => item);
    } catch (error) {
      console.error(`[Cherry Diff] Failed to read ${uri.toString()}`, error);
      return [];
    }
  }

  private createItem(
    uri: vscode.Uri,
    isDirectory: boolean,
    isWorkspaceRoot: boolean,
    isSymbolicLink: boolean,
    label: string
  ): FilterTreeItem {
    return new FilterTreeItem(
      this.filterService,
      uri,
      isDirectory,
      isWorkspaceRoot,
      isSymbolicLink,
      label
    );
  }
}
