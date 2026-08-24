import * as vscode from 'vscode';
import { getFilterPath, isUriIncluded, updatePathOverrides } from './filterService';

export class FilterTreeItem extends vscode.TreeItem {
  constructor(
    public readonly uri: vscode.Uri,
    public readonly isDirectory: boolean,
    public readonly isWorkspaceRoot = false
  ) {
    super(
      isWorkspaceRoot
        ? vscode.workspace.getWorkspaceFolder(uri)?.name ?? uri.fsPath
        : uri.path.split('/').filter(Boolean).pop() ?? uri.fsPath,
      isDirectory
        ? vscode.TreeItemCollapsibleState.Collapsed
        : vscode.TreeItemCollapsibleState.None
    );

    this.resourceUri = uri;
    if (isWorkspaceRoot) {
      this.iconPath = new vscode.ThemeIcon('root-folder');
    } else {
      const included = isUriIncluded(uri, isDirectory);
      this.checkboxState = included
        ? vscode.TreeItemCheckboxState.Checked
        : vscode.TreeItemCheckboxState.Unchecked;
      this.tooltip = `${getFilterPath(uri)} — ${included ? 'included' : 'excluded'}`;
    }
  }
}

/** Explorer-style workspace tree for visual include/exclude selections. */
export class FilterTreeProvider implements vscode.TreeDataProvider<FilterTreeItem>, vscode.Disposable {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<FilterTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly configurationSubscription: vscode.Disposable;

  constructor() {
    this.configurationSubscription = vscode.workspace.onDidChangeConfiguration((event) => {
      if (event.affectsConfiguration('cherryDiff')) {
        this.refresh();
      }
    });
  }

  getTreeItem(element: FilterTreeItem): vscode.TreeItem {
    return element;
  }

  async getChildren(element?: FilterTreeItem): Promise<FilterTreeItem[]> {
    const workspaceFolders = vscode.workspace.workspaceFolders ?? [];
    if (!element) {
      if (workspaceFolders.length === 1) {
        return this.readDirectory(workspaceFolders[0].uri);
      }
      return workspaceFolders.map(
        (folder) => new FilterTreeItem(folder.uri, true, true)
      );
    }

    if (!element.isDirectory) {
      return [];
    }
    return this.readDirectory(element.uri);
  }

  async applyCheckboxChanges(
    changes: ReadonlyArray<[FilterTreeItem, vscode.TreeItemCheckboxState]>
  ): Promise<void> {
    await updatePathOverrides(
      changes
        .filter(([item]) => !item.isWorkspaceRoot)
        .map(([item, state]) => ({
          path: getFilterPath(item.uri),
          included: state === vscode.TreeItemCheckboxState.Checked,
          recursive: item.isDirectory,
        }))
    );
    this.refresh();
  }

  refresh(): void {
    this._onDidChangeTreeData.fire(undefined);
  }

  dispose(): void {
    this.configurationSubscription.dispose();
    this._onDidChangeTreeData.dispose();
  }

  private async readDirectory(uri: vscode.Uri): Promise<FilterTreeItem[]> {
    try {
      const entries = await vscode.workspace.fs.readDirectory(uri);
      return entries
        .map(([name, type]) => ({
          name,
          item: new FilterTreeItem(
            vscode.Uri.joinPath(uri, name),
            (type & vscode.FileType.Directory) !== 0
          ),
        }))
        .sort((a, b) => {
          if (a.item.isDirectory !== b.item.isDirectory) {
            return a.item.isDirectory ? -1 : 1;
          }
          return a.name.localeCompare(b.name, undefined, { sensitivity: 'base' });
        })
        .map(({ item }) => item);
    } catch {
      return [];
    }
  }
}
