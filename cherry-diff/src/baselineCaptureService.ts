import * as vscode from 'vscode';
import {
  DEFAULT_BASELINE_CAPTURE_CONCURRENCY,
  MAX_BASELINE_CAPTURE_CONCURRENCY,
  MAX_BASELINE_STABILITY_ATTEMPTS,
} from './constants';
import { BaselineService } from './baselineService';
import { FilterService } from './filterService';
import { isFileNotFound } from './fileSnapshot';

type CaptureProgress = vscode.Progress<{ message?: string; increment?: number }>;

export class CaptureCancelledError extends Error {
  constructor() {
    super('Baseline capture was cancelled.');
  }
}

/** Finds and captures complete filtered baseline sets with bounded workers. */
export class BaselineCaptureService {
  constructor(
    private readonly baselines: BaselineService,
    private readonly filters: FilterService
  ) {}

  async captureFilteredBaselines(
    progress: CaptureProgress,
    token: vscode.CancellationToken,
    isCancelled: () => boolean,
    onlyMissing = false
  ): Promise<void> {
    progress.report({ message: 'Finding included files' });
    const files = new Map<string, vscode.Uri>();
    const excludePattern = buildExcludePattern(this.filters.getExcludePatterns());

    for (const includePattern of this.filters.getIncludePatterns()) {
      this.throwIfCancelled(token, isCancelled);
      const matches = await vscode.workspace.findFiles(
        includePattern,
        excludePattern,
        undefined,
        token
      );
      for (const uri of matches) {
        files.set(uri.toString(), uri);
      }
    }

    const overrideRoots = this.filters.getIncludedOverrideUris();
    if (overrideRoots.length > 0) {
      const overrideFiles = await this.collectFilesRecursively(
        overrideRoots,
        progress,
        token,
        isCancelled
      );
      for (const uri of overrideFiles) {
        files.set(uri.toString(), uri);
      }
    }

    const openKeys = new Set(
      vscode.workspace.textDocuments.map((document) => document.uri.toString())
    );
    const openFiles: vscode.Uri[] = [];
    const otherFiles: vscode.Uri[] = [];
    for (const uri of files.values()) {
      if (!this.filters.isIncluded(uri)
        || (onlyMissing && this.baselines.hasBaseline(uri))) {
        continue;
      }
      (openKeys.has(uri.toString()) ? openFiles : otherFiles).push(uri);
    }

    const candidates = [...openFiles, ...otherFiles];
    progress.report({ message: `Capturing ${candidates.length.toLocaleString()} files` });
    await this.captureUntilStable(candidates, progress, token, isCancelled);
  }

  async captureUntilStable(
    uris: readonly vscode.Uri[],
    progress: CaptureProgress | undefined,
    token: vscode.CancellationToken,
    isCancelled: () => boolean
  ): Promise<void> {
    let pending = deduplicateUris(uris);
    for (let attempt = 1; pending.length > 0; attempt++) {
      this.throwIfCancelled(token, isCancelled);
      const unstable = await this.captureBatch(
        pending,
        progress,
        token,
        isCancelled
      );
      if (unstable.length === 0) {
        return;
      }
      if (attempt >= MAX_BASELINE_STABILITY_ATTEMPTS) {
        const paths = unstable
          .slice(0, 5)
          .map((uri) => vscode.workspace.asRelativePath(uri))
          .join(', ');
        throw new Error(
          `Could not capture a stable baseline after ${MAX_BASELINE_STABILITY_ATTEMPTS} attempts: ${paths}`
        );
      }
      pending = unstable;
    }
  }

  async collectFilesRecursively(
    roots: readonly vscode.Uri[],
    progress: CaptureProgress | undefined,
    token: vscode.CancellationToken | undefined,
    isCancelled: () => boolean
  ): Promise<vscode.Uri[]> {
    const files = new Map<string, vscode.Uri>();
    const directories: vscode.Uri[] = [];
    const visitedDirectories = new Set<string>();

    for (const root of roots) {
      this.throwIfCancelled(token, isCancelled);
      try {
        const stat = await vscode.workspace.fs.stat(root);
        const isDirectory = (stat.type & vscode.FileType.Directory) !== 0;
        const isSymbolicLink = (stat.type & vscode.FileType.SymbolicLink) !== 0;
        if (isDirectory && !isSymbolicLink) {
          directories.push(root);
        } else if (!isDirectory) {
          files.set(root.toString(), root);
        }
      } catch (error) {
        if (!isFileNotFound(error)) {
          throw error;
        }
      }
    }

    for (let index = 0; index < directories.length; index++) {
      this.throwIfCancelled(token, isCancelled);
      const directory = directories[index];
      const directoryKey = directory.toString();
      if (visitedDirectories.has(directoryKey)) {
        continue;
      }
      visitedDirectories.add(directoryKey);

      const entries = await vscode.workspace.fs.readDirectory(directory);
      for (const [name, type] of entries) {
        const uri = vscode.Uri.joinPath(directory, name);
        const isDirectory = (type & vscode.FileType.Directory) !== 0;
        const isSymbolicLink = (type & vscode.FileType.SymbolicLink) !== 0;
        if (isDirectory && !isSymbolicLink) {
          directories.push(uri);
        } else if (!isDirectory) {
          files.set(uri.toString(), uri);
        }
      }
      progress?.report({ message: `${files.size.toLocaleString()} files found` });
    }

    return [...files.values()];
  }

  private async captureBatch(
    uris: readonly vscode.Uri[],
    progress: CaptureProgress | undefined,
    token: vscode.CancellationToken,
    isCancelled: () => boolean
  ): Promise<vscode.Uri[]> {
    const unstable: vscode.Uri[] = [];
    const errors: Array<{ uri: vscode.Uri; error: unknown }> = [];
    let nextIndex = 0;
    let completed = 0;
    const workerCount = Math.min(getCaptureConcurrency(), uris.length);

    const worker = async (): Promise<void> => {
      while (!token.isCancellationRequested && !isCancelled()) {
        const index = nextIndex++;
        if (index >= uris.length) {
          return;
        }

        const uri = uris[index];
        try {
          const result = await this.baselines.captureBaseline(uri);
          if (result === 'unstable') {
            unstable.push(uri);
          }
        } catch (error) {
          errors.push({ uri, error });
        } finally {
          completed++;
          progress?.report({
            message: `${completed.toLocaleString()} / ${uris.length.toLocaleString()} files`,
          });
        }
      }
    };

    // Workers collect failures instead of rejecting early, so no background
    // writes survive after this method returns.
    await Promise.all(Array.from({ length: workerCount }, () => worker()));
    this.throwIfCancelled(token, isCancelled);

    if (errors.length > 0) {
      const details = errors
        .slice(0, 5)
        .map(({ uri, error }) => `${vscode.workspace.asRelativePath(uri)}: ${String(error)}`)
        .join('\n');
      throw new Error(`Failed to capture ${errors.length} file(s).\n${details}`);
    }
    return unstable;
  }

  private throwIfCancelled(
    token: vscode.CancellationToken | undefined,
    isCancelled: () => boolean
  ): void {
    if (token?.isCancellationRequested || isCancelled()) {
      throw new CaptureCancelledError();
    }
  }
}

function deduplicateUris(uris: readonly vscode.Uri[]): vscode.Uri[] {
  return [...new Map(uris.map((uri) => [uri.toString(), uri])).values()];
}

function buildExcludePattern(
  patterns: readonly string[]
): vscode.GlobPattern | null {
  if (patterns.length === 0) {
    // null explicitly disables VS Code's files.exclude fallback.
    return null;
  }
  if (patterns.length === 1) {
    return patterns[0];
  }
  if (patterns.some((pattern) => /[{},]/.test(pattern))) {
    // Let the cached matcher apply complex exclusions accurately rather than
    // constructing an ambiguous brace expression.
    return null;
  }
  return `{${patterns.join(',')}}`;
}

function getCaptureConcurrency(): number {
  const configured = vscode.workspace
    .getConfiguration('cherryDiff')
    .get<number>(
      'baselineCaptureConcurrency',
      DEFAULT_BASELINE_CAPTURE_CONCURRENCY
    );
  const normalized = Number.isFinite(configured)
    ? Math.floor(configured)
    : DEFAULT_BASELINE_CAPTURE_CONCURRENCY;
  return Math.min(
    MAX_BASELINE_CAPTURE_CONCURRENCY,
    Math.max(1, normalized)
  );
}
