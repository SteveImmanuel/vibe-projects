import * as vscode from 'vscode';
import { createHash } from 'crypto';

export interface BaselineSnapshot {
  content: string;
  exists: boolean;
}

export type BaselineCaptureResult = 'captured' | 'missing' | 'unstable' | 'skipped';

interface BaselineEntry {
  exists: boolean;
  blobHash?: string;
  size: number;
  modifiedTime: number;
}

/**
 * Stores baseline contents in extension storage and keeps only a lightweight
 * path-to-blob index in extension-host memory. Blob contents are loaded only
 * when a changed file needs to be reviewed.
 */
export class BaselineService implements vscode.Disposable {
  private readonly baselines = new Map<string, BaselineEntry>();
  private readonly knownBlobs = new Set<string>();
  private readonly blobRefCounts = new Map<string, number>();
  private readonly blobsUri: vscode.Uri;
  private initialized = false;

  constructor(private readonly storageUri: vscode.Uri) {
    this.blobsUri = vscode.Uri.joinPath(storageUri, 'blobs');
  }

  /** Remove the previous session and prepare an empty baseline store. */
  async clearBaselines(): Promise<void> {
    this.baselines.clear();
    this.knownBlobs.clear();
    this.blobRefCounts.clear();

    try {
      await vscode.workspace.fs.delete(this.storageUri, { recursive: true });
    } catch {
      // The store does not exist on the first run.
    }

    await vscode.workspace.fs.createDirectory(this.blobsUri);
    this.initialized = true;
  }

  /** Capture a file directly as bytes without opening a VS Code document. */
  async captureBaseline(uri: vscode.Uri): Promise<BaselineCaptureResult> {
    await this.ensureInitialized();

    let statBefore: vscode.FileStat;
    try {
      statBefore = await vscode.workspace.fs.stat(uri);
    } catch {
      await this.captureMissingBaseline(uri.fsPath);
      return 'missing';
    }
    if ((statBefore.type & vscode.FileType.Directory) !== 0) {
      return 'skipped';
    }

    let bytes: Uint8Array;
    let statAfter: vscode.FileStat;
    const openDocument = vscode.workspace.textDocuments.find(
      (document) => document.uri.scheme === 'file' && document.uri.fsPath === uri.fsPath
    );
    const documentVersion = openDocument?.version;

    try {
      // Preserve unsaved editor state without opening every workspace file.
      bytes = openDocument
        ? new TextEncoder().encode(openDocument.getText())
        : await vscode.workspace.fs.readFile(uri);
      statAfter = await vscode.workspace.fs.stat(uri);
    } catch (error) {
      try {
        await vscode.workspace.fs.stat(uri);
      } catch {
        await this.captureMissingBaseline(uri.fsPath);
        return 'missing';
      }
      throw error;
    }

    // If a write overlapped the read, request another capture rather than
    // keeping a potentially torn copy.
    if (documentVersion !== undefined && openDocument?.version !== documentVersion) {
      return 'unstable';
    }
    if (!openDocument
      && (statBefore.mtime !== statAfter.mtime || statBefore.size !== statAfter.size)) {
      return 'unstable';
    }

    const blobHash = await this.storeBlob(bytes);
    await this.setBaselineEntry(uri.fsPath, {
      exists: true,
      blobHash,
      size: bytes.byteLength,
      modifiedTime: statAfter.mtime,
    });
    return 'captured';
  }

  /** Record that a path did not exist at the baseline boundary. */
  private async captureMissingBaseline(fsPath: string): Promise<void> {
    await this.ensureInitialized();
    await this.setBaselineEntry(fsPath, {
      exists: false,
      size: 0,
      modifiedTime: 0,
    });
  }

  /** Load baseline text only for a file that has entered review. */
  async getSnapshot(fsPath: string): Promise<BaselineSnapshot | undefined> {
    const entry = this.baselines.get(fsPath);
    if (!entry) {
      return undefined;
    }
    if (!entry.exists) {
      return { content: '', exists: false };
    }
    if (!entry.blobHash) {
      throw new Error(`Baseline blob is missing for ${fsPath}`);
    }

    const bytes = await vscode.workspace.fs.readFile(this.getBlobUri(entry.blobHash));
    return {
      content: new TextDecoder().decode(bytes),
      exists: true,
    };
  }

  /** Store an accepted state as the new baseline for one file. */
  async updateBaseline(
    fsPath: string,
    content: string,
    exists = true
  ): Promise<void> {
    await this.ensureInitialized();

    if (!exists) {
      await this.setBaselineEntry(fsPath, {
        exists: false,
        size: 0,
        modifiedTime: 0,
      });
      return;
    }

    const bytes = new TextEncoder().encode(content);
    const blobHash = await this.storeBlob(bytes);
    await this.setBaselineEntry(fsPath, {
      exists: true,
      blobHash,
      size: bytes.byteLength,
      modifiedTime: Date.now(),
    });
  }

  hasBaseline(fsPath: string): boolean {
    return this.baselines.has(fsPath);
  }

  getBaselinePaths(): string[] {
    return [...this.baselines.keys()];
  }

  getBaselineCount(): number {
    return this.baselines.size;
  }

  /** Remove one file or a directory subtree from the tracked baseline set. */
  async removeBaseline(fsPath: string, recursive: boolean): Promise<void> {
    const separator = fsPath.includes('\\') ? '\\' : '/';
    const prefix = fsPath.endsWith(separator) ? fsPath : `${fsPath}${separator}`;
    const paths = [...this.baselines.keys()].filter(
      (candidate) => candidate === fsPath || (recursive && candidate.startsWith(prefix))
    );

    for (const candidate of paths) {
      const blobHash = this.baselines.get(candidate)?.blobHash;
      this.baselines.delete(candidate);
      if (blobHash) {
        await this.releaseBlob(blobHash);
      }
    }
  }

  private async ensureInitialized(): Promise<void> {
    if (!this.initialized) {
      await vscode.workspace.fs.createDirectory(this.blobsUri);
      this.initialized = true;
    }
  }

  private async storeBlob(bytes: Uint8Array): Promise<string> {
    const hash = createHash('sha256').update(bytes).digest('hex');
    if (this.knownBlobs.has(hash)) {
      return hash;
    }

    const blobDirectory = vscode.Uri.joinPath(this.blobsUri, hash.slice(0, 2));
    await vscode.workspace.fs.createDirectory(blobDirectory);
    const blobUri = this.getBlobUri(hash);
    try {
      await vscode.workspace.fs.stat(blobUri);
    } catch {
      await vscode.workspace.fs.writeFile(blobUri, bytes);
    }
    this.knownBlobs.add(hash);
    return hash;
  }

  private getBlobUri(hash: string): vscode.Uri {
    return vscode.Uri.joinPath(this.blobsUri, hash.slice(0, 2), hash);
  }

  private async setBaselineEntry(fsPath: string, entry: BaselineEntry): Promise<void> {
    const previousHash = this.baselines.get(fsPath)?.blobHash;
    const nextHash = entry.blobHash;
    this.baselines.set(fsPath, entry);

    if (previousHash === nextHash) {
      return;
    }
    if (nextHash) {
      this.blobRefCounts.set(nextHash, (this.blobRefCounts.get(nextHash) ?? 0) + 1);
    }
    if (!previousHash) {
      return;
    }

    await this.releaseBlob(previousHash);
  }

  private async releaseBlob(hash: string): Promise<void> {
    const remainingReferences = (this.blobRefCounts.get(hash) ?? 1) - 1;
    if (remainingReferences > 0) {
      this.blobRefCounts.set(hash, remainingReferences);
      return;
    }

    this.blobRefCounts.delete(hash);
    this.knownBlobs.delete(hash);
    try {
      await vscode.workspace.fs.delete(this.getBlobUri(hash));
    } catch {
      // The next session reset removes any orphaned blob.
    }
  }

  dispose(): void {
    // The next activation clears the session store. Avoid asynchronous file
    // operations during extension-host shutdown.
    this.baselines.clear();
    this.knownBlobs.clear();
    this.blobRefCounts.clear();
  }
}
