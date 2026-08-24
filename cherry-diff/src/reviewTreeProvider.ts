import * as vscode from 'vscode';
import { getChangedLineRange, getFirstChangedLine } from './diffService';
import { ReviewManager } from './reviewManager';
import type { FileReview, HunkReview } from './types';

export type ReviewTreeItem = FileTreeItem | HunkTreeItem;

export class FileTreeItem extends vscode.TreeItem {
  readonly resourceKey: string;

  constructor(public readonly fileReview: FileReview) {
    const totalCount = fileReview.hunks.length;
    super(fileReview.relativePath, vscode.TreeItemCollapsibleState.Expanded);

    this.resourceKey = fileReview.key;
    this.id = `file:${fileReview.key}`;
    this.description = `${totalCount} hunk${totalCount !== 1 ? 's' : ''}`;
    this.iconPath = new vscode.ThemeIcon('file');
    this.contextValue = 'file';
    this.resourceUri = fileReview.uri;
    this.command = {
      command: 'cherryDiff.openDiff',
      title: 'Open Diff',
      arguments: [fileReview.key],
    };
  }
}

export class HunkTreeItem extends vscode.TreeItem {
  readonly resourceKey: string;
  readonly hunkId: string;

  constructor(resourceKey: string, hunkReview: HunkReview, index: number) {
    const { startLine, endLine } = getChangedLineRange(hunkReview.hunk);
    const changedLine = getFirstChangedLine(hunkReview.hunk);
    const label = hunkReview.kind === 'file-created'
      ? `Hunk ${index + 1}: file created`
      : hunkReview.kind === 'file-deleted'
        ? `Hunk ${index + 1}: file deleted`
        : hunkReview.kind === 'binary'
          ? `Hunk ${index + 1}: binary or encoding change`
          : hunkReview.kind === 'whole-file'
            ? `Hunk ${index + 1}: large or complex file change`
            : startLine + 1 === endLine
            ? `Hunk ${index + 1}: line ${startLine + 1}`
            : `Hunk ${index + 1}: lines ${startLine + 1}-${endLine}`;

    super(label, vscode.TreeItemCollapsibleState.None);
    this.resourceKey = resourceKey;
    this.hunkId = hunkReview.id;
    this.id = `${resourceKey}:${hunkReview.id}`;
    this.iconPath = new vscode.ThemeIcon('circle-outline');
    this.contextValue = 'hunk';
    this.command = {
      command: 'cherryDiff.openDiffAtLine',
      title: 'Open Diff at Hunk',
      arguments: [resourceKey, changedLine],
    };
  }
}

export class ReviewTreeProvider implements vscode.TreeDataProvider<ReviewTreeItem>, vscode.Disposable {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<ReviewTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly reviewSubscription: vscode.Disposable;

  constructor(private readonly reviews: ReviewManager) {
    this.reviewSubscription = reviews.onDidChangeReview(() => {
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  getTreeItem(element: ReviewTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: ReviewTreeItem): ReviewTreeItem[] {
    if (!element) {
      return [...this.reviews.getAllFileReviews().values()]
        .sort((left, right) => left.relativePath.localeCompare(
          right.relativePath,
          undefined,
          { sensitivity: 'base' }
        ))
        .map((review) => new FileTreeItem(review));
    }

    if (element instanceof FileTreeItem) {
      return element.fileReview.hunks.map(
        (hunk, index) => new HunkTreeItem(element.fileReview.key, hunk, index)
      );
    }
    return [];
  }

  dispose(): void {
    this.reviewSubscription.dispose();
    this._onDidChangeTreeData.dispose();
  }
}
