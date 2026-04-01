import * as vscode from 'vscode';
import { ReviewManager } from './reviewManager';
import { FileReview, HunkReview } from './types';
import { getChangedLineRange, getFirstChangedLine } from './diffService';

export type ReviewTreeItem = FileTreeItem | HunkTreeItem;

export class FileTreeItem extends vscode.TreeItem {
  readonly fsPath: string;

  constructor(public readonly fileReview: FileReview) {
    const totalCount = fileReview.hunks.length;
    const label = vscode.workspace.asRelativePath(fileReview.uri);

    super(label, vscode.TreeItemCollapsibleState.Expanded);

    this.fsPath = fileReview.uri.fsPath;
    this.description = `${totalCount} hunk${totalCount !== 1 ? 's' : ''}`;
    this.iconPath = new vscode.ThemeIcon('file');
    this.contextValue = 'file';
    this.resourceUri = fileReview.uri;

    this.command = {
      command: 'cherryDiff.openDiff',
      title: 'Open Diff',
      arguments: [fileReview.uri.fsPath],
    };
  }
}

export class HunkTreeItem extends vscode.TreeItem {
  readonly fsPath: string;
  readonly hunkId: string;
  readonly startLine: number;

  constructor(
    fsPath: string,
    public readonly hunkReview: HunkReview,
    public readonly index: number
  ) {
    const { startLine, endLine } = getChangedLineRange(hunkReview.hunk);
    const changedLine = getFirstChangedLine(hunkReview.hunk);
    const label = startLine + 1 === endLine
      ? `Hunk ${index + 1}: line ${startLine + 1}`
      : `Hunk ${index + 1}: lines ${startLine + 1}-${endLine}`;

    super(label, vscode.TreeItemCollapsibleState.None);

    this.fsPath = fsPath;
    this.hunkId = hunkReview.id;
    this.startLine = changedLine;
    this.iconPath = new vscode.ThemeIcon('circle-outline');
    this.contextValue = 'hunk';

    // Clicking a hunk opens diff AND scrolls to the changed line
    this.command = {
      command: 'cherryDiff.openDiffAtLine',
      title: 'Open Diff at Hunk',
      arguments: [fsPath, changedLine],
    };
  }
}

export class ReviewTreeProvider implements vscode.TreeDataProvider<ReviewTreeItem> {
  private _onDidChangeTreeData = new vscode.EventEmitter<ReviewTreeItem | undefined | null>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  constructor(private reviewManager: ReviewManager) {
    reviewManager.onDidChangeReview(() => {
      this._onDidChangeTreeData.fire(null);
    });
  }

  getTreeItem(element: ReviewTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: ReviewTreeItem): ReviewTreeItem[] {
    if (!element) {
      const items: FileTreeItem[] = [];
      for (const review of this.reviewManager.getAllFileReviews().values()) {
        items.push(new FileTreeItem(review));
      }
      return items;
    }

    if (element instanceof FileTreeItem) {
      return element.fileReview.hunks.map(
        (h, i) => new HunkTreeItem(element.fileReview.uri.fsPath, h, i)
      );
    }

    return [];
  }
}
