import * as vscode from 'vscode';
import { Debouncer } from './async';
import { FILTER_TREE_REFRESH_DEBOUNCE_MS } from './constants';
import { FilterService } from './filterService';

interface FilterTreeItemOptions {
  isDirectory: boolean;
  isWorkspaceRoot?: boolean;
  isSymbolicLink?: boolean;
}

export class FilterTreeItem extends vscode.TreeItem {
  readonly isDirectory: boolean;
  readonly isSymbolicLink: boolean;

  constructor(
    filterService: FilterService,
    public readonly uri: vscode.Uri,
    label: string,
    options: FilterTreeItemOptions
  ) {
    super(
      label,
      options.isDirectory
        ? vscode.TreeItemCollapsibleState.Collapsed
        : vscode.TreeItemCollapsibleState.None
    );
    this.isDirectory = options.isDirectory;
    this.isSymbolicLink = options.isSymbolicLink ?? false;

    this.resourceUri = uri;
    this.id = `filter:${uri.toString()}`;
    const included = filterService.isIncluded(uri, this.isDirectory);
    this.checkboxState = included
      ? vscode.TreeItemCheckboxState.Checked
      : vscode.TreeItemCheckboxState.Unchecked;
    this.tooltip = `${filterService.getDisplayPath(uri)} — ${included ? 'included' : 'excluded'}`;

    if (options.isWorkspaceRoot) {
      this.iconPath = new vscode.ThemeIcon('root-folder');
      this.collapsibleState = vscode.TreeItemCollapsibleState.Expanded;
    } else if (this.isSymbolicLink) {
      this.description = 'symbolic link';
    }
  }
}

/** Explorer-style workspace tree for visual include/exclude selections. */
export class FilterTreeProvider implements vscode.TreeDataProvider<FilterTreeItem>, vscode.Disposable {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<FilterTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly disposables: vscode.Disposable[] = [];
  private readonly refreshDebounce = new Debouncer(FILTER_TREE_REFRESH_DEBOUNCE_MS);

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
    if (!element) {
      return (vscode.workspace.workspaceFolders ?? []).map((folder) => (
        new FilterTreeItem(this.filterService, folder.uri, folder.name, {
          isDirectory: true,
          isWorkspaceRoot: true,
        })
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
    this.refreshDebounce.cancel();
    this._onDidChangeTreeData.fire(undefined);
  }

  dispose(): void {
    this.refreshDebounce.cancel();
    for (const disposable of this.disposables) {
      disposable.dispose();
    }
    this._onDidChangeTreeData.dispose();
  }

  private scheduleRefresh(): void {
    this.refreshDebounce.schedule(() => this._onDidChangeTreeData.fire(undefined));
  }

  private async readDirectory(uri: vscode.Uri): Promise<FilterTreeItem[]> {
    try {
      const entries = await vscode.workspace.fs.readDirectory(uri);
      return entries
        .map(([name, type]) => ({
          name,
          item: new FilterTreeItem(this.filterService, vscode.Uri.joinPath(uri, name), name, {
            isDirectory: (type & vscode.FileType.Directory) !== 0,
            isSymbolicLink: (type & vscode.FileType.SymbolicLink) !== 0,
          }),
        }))
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
}
