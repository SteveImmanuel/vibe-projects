import * as vscode from 'vscode';
import { createHash } from 'crypto';
import { BLOB_SHARD_PREFIX_LENGTH } from './constants';
import {
  FileSnapshot,
  isFileNotFound,
  missingFileSnapshot,
  readFileSnapshot,
  snapshotFromBytes,
} from './fileSnapshot';
import { isSameOrDescendant } from './resourceUri';

type BaselineCaptureResult = 'captured' | 'missing' | 'unstable' | 'skipped';

interface BaselineEntry {
  uri: vscode.Uri;
  exists: boolean;
  blobKey?: string;
}

/**
 * Stores one path-addressed byte snapshot per tracked resource. Only the URI
 * index stays in extension-host memory; bytes are loaded for active reviews.
 */
export class BaselineService implements vscode.Disposable {
  private readonly baselines = new Map<string, BaselineEntry>();
  private readonly blobsUri: vscode.Uri;
  private readonly preparedBlobDirectories = new Set<string>();
  private initialized = false;
  private complete = false;

  constructor(private readonly storageUri: vscode.Uri) {
    this.blobsUri = vscode.Uri.joinPath(storageUri, 'blobs');
  }

  async clearBaselines(): Promise<void> {
    this.baselines.clear();
    this.preparedBlobDirectories.clear();
    this.complete = false;

    try {
      await vscode.workspace.fs.delete(this.storageUri, { recursive: true });
    } catch (error) {
      if (!isFileNotFound(error)) {
        throw error;
      }
    }

    await vscode.workspace.fs.createDirectory(this.blobsUri);
    this.initialized = true;
  }

  async captureBaseline(uri: vscode.Uri): Promise<BaselineCaptureResult> {
    await this.ensureInitialized();
    const result = await readFileSnapshot(uri);

    if (result.kind === 'unstable') {
      return 'unstable';
    }
    if (result.kind === 'directory') {
      return 'skipped';
    }

    await this.updateBaseline(uri, result.snapshot);
    return result.snapshot.exists ? 'captured' : 'missing';
  }

  async getSnapshot(uri: vscode.Uri): Promise<FileSnapshot | undefined> {
    const entry = this.baselines.get(uri.toString());
    if (!entry) {
      return undefined;
    }
    if (!entry.exists) {
      return missingFileSnapshot();
    }
    if (!entry.blobKey) {
      throw new Error(`Baseline blob is missing for ${entry.uri.toString()}`);
    }

    const bytes = await vscode.workspace.fs.readFile(this.getBlobUri(entry.blobKey));
    return snapshotFromBytes(bytes);
  }

  async updateBaseline(uri: vscode.Uri, snapshot: FileSnapshot): Promise<void> {
    await this.ensureInitialized();
    const key = uri.toString();

    if (!snapshot.exists) {
      this.baselines.set(key, { uri, exists: false });
      return;
    }

    const blobKey = this.getBlobKey(key);
    await this.prepareBlobDirectory(blobKey);
    await vscode.workspace.fs.writeFile(this.getBlobUri(blobKey), snapshot.bytes);
    this.baselines.set(key, { uri, exists: true, blobKey });
  }

  hasBaseline(uri: vscode.Uri): boolean {
    return this.baselines.has(uri.toString());
  }

  getBaselineUris(): vscode.Uri[] {
    return [...this.baselines.values()].map((entry) => entry.uri);
  }

  getBaselineUrisUnder(uri: vscode.Uri): vscode.Uri[] {
    return [...this.baselines.values()]
      .map((entry) => entry.uri)
      .filter((candidate) => isSameOrDescendant(candidate, uri));
  }

  getBaselineCount(): number {
    return this.baselines.size;
  }

  removeBaseline(uri: vscode.Uri): void {
    this.baselines.delete(uri.toString());
  }

  markComplete(): void {
    this.complete = true;
  }

  isComplete(): boolean {
    return this.complete;
  }

  async deleteSessionStore(): Promise<void> {
    this.baselines.clear();
    this.preparedBlobDirectories.clear();
    this.complete = false;
    this.initialized = false;
    try {
      await vscode.workspace.fs.delete(this.storageUri, { recursive: true });
    } catch (error) {
      if (!isFileNotFound(error)) {
        throw error;
      }
    }
  }

  dispose(): void {
    this.baselines.clear();
    this.preparedBlobDirectories.clear();
    this.complete = false;
  }

  private async ensureInitialized(): Promise<void> {
    if (!this.initialized) {
      await vscode.workspace.fs.createDirectory(this.blobsUri);
      this.initialized = true;
    }
  }

  private getBlobKey(resourceKey: string): string {
    return createHash('sha256').update(resourceKey).digest('hex');
  }

  private async prepareBlobDirectory(blobKey: string): Promise<void> {
    const prefix = blobKey.slice(0, BLOB_SHARD_PREFIX_LENGTH);
    if (this.preparedBlobDirectories.has(prefix)) {
      return;
    }
    await vscode.workspace.fs.createDirectory(vscode.Uri.joinPath(this.blobsUri, prefix));
    this.preparedBlobDirectories.add(prefix);
  }

  private getBlobUri(blobKey: string): vscode.Uri {
    return vscode.Uri.joinPath(
      this.blobsUri,
      blobKey.slice(0, BLOB_SHARD_PREFIX_LENGTH),
      blobKey
    );
  }
}
