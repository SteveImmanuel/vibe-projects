import * as vscode from 'vscode';
import { Minimatch } from 'minimatch';
import { FILTER_MATCH_OPTIONS, PATH_OVERRIDES_STATE_KEY } from './constants';
import { globMatch } from './glob';

type PathOverrides = Record<string, boolean>;

interface FilterLocation {
  root: string;
  path: string;
}

interface StoredPathOverride extends FilterLocation {
  included: boolean;
}

type FilterChangeKind = 'patterns' | 'overrides';

export function normalizeFilterPath(relativePath: string): string {
  const normalized = relativePath
    .replace(/\\/g, '/')
    .replace(/^\.\/+/, '')
    .replace(/\/{2,}/g, '/')
    .replace(/\/$/, '');
  return normalized === '.' ? '' : normalized;
}

/** Pure helper retained for unit tests and settings semantics. */
export function isPathIncluded(
  relativePath: string,
  includes: string[],
  excludes: string[],
  overrides: PathOverrides
): boolean {
  const normalizedPath = normalizeFilterPath(relativePath);
  const override = findNearestRelativeOverride(normalizedPath, overrides);
  if (override !== undefined) {
    return override;
  }

  if (excludes.some((pattern) => globMatch(normalizedPath, pattern))) {
    return false;
  }
  return includes.some((pattern) => globMatch(normalizedPath, pattern));
}

/** Cached workspace-aware matcher and visual-selection store. */
export class FilterService implements vscode.Disposable {
  private readonly overrides = new Map<string, StoredPathOverride>();
  private includes: string[] = [];
  private excludes: string[] = [];
  private includeMatchers: Minimatch[] = [];
  private excludeMatchers: Minimatch[] = [];
  private overrideUpdateTail: Promise<void> = Promise.resolve();
  private readonly _onDidChange = new vscode.EventEmitter<FilterChangeKind>();
  readonly onDidChange = this._onDidChange.event;
  private readonly configurationSubscription: vscode.Disposable;

  constructor(private readonly workspaceState: vscode.Memento) {
    this.refreshPatterns();
    this.configurationSubscription = vscode.workspace.onDidChangeConfiguration((event) => {
      if (!event.affectsConfiguration('cherryDiff.includePaths')
        && !event.affectsConfiguration('cherryDiff.excludePaths')) {
        return;
      }
      this.refreshPatterns();
      this._onDidChange.fire('patterns');
    });
  }

  async initialize(): Promise<void> {
    const stored = this.workspaceState.get<StoredPathOverride[]>(PATH_OVERRIDES_STATE_KEY);
    if (stored) {
      this.setStoredOverrides(stored);
      return;
    }

    // Migrate the former workspace-setting representation without retaining a
    // settings.json entry that Cherry Diff could later observe as a file edit.
    const config = vscode.workspace.getConfiguration('cherryDiff');
    const legacy = config.get<PathOverrides>('pathOverrides', {});
    const migrated: StoredPathOverride[] = [];
    for (const folder of vscode.workspace.workspaceFolders ?? []) {
      for (const [path, included] of Object.entries(legacy)) {
        migrated.push({
          root: folder.uri.toString(),
          path: normalizeFilterPath(path),
          included,
        });
      }
    }
    this.setStoredOverrides(migrated);
    await this.persistOverrides();

    const inspection = config.inspect<PathOverrides>('pathOverrides');
    if (inspection?.workspaceValue !== undefined) {
      await config.update('pathOverrides', undefined, vscode.ConfigurationTarget.Workspace);
    }
  }

  isIncluded(uri: vscode.Uri, asDirectory = false): boolean {
    const location = this.getLocation(uri);
    if (!location) {
      return false;
    }

    const pathToMatch = asDirectory
      ? `${location.path ? `${location.path}/` : ''}__cherry_diff_descendant__`
      : location.path;
    const override = this.getNearestOverride(location.root, pathToMatch);
    if (override !== undefined) {
      return override;
    }
    if (this.excludeMatchers.some((matcher) => matcher.match(pathToMatch))) {
      return false;
    }
    return this.includeMatchers.some((matcher) => matcher.match(pathToMatch));
  }

  getLocation(uri: vscode.Uri): FilterLocation | undefined {
    const folder = vscode.workspace.getWorkspaceFolder(uri);
    if (!folder) {
      return undefined;
    }
    return {
      root: folder.uri.toString(),
      path: getWorkspaceRelativePath(folder, uri),
    };
  }

  getDisplayPath(uri: vscode.Uri): string {
    const folder = vscode.workspace.getWorkspaceFolder(uri);
    if (!folder) {
      return uri.toString();
    }
    const relativePath = getWorkspaceRelativePath(folder, uri);
    return (vscode.workspace.workspaceFolders?.length ?? 0) > 1
      ? `${folder.name}/${relativePath}`.replace(/\/$/, '')
      : relativePath || folder.name;
  }

  getIncludePatterns(): readonly string[] {
    return this.includes;
  }

  getExcludePatterns(): readonly string[] {
    return this.excludes;
  }

  getIncludedOverrideUris(): vscode.Uri[] {
    const included = [...this.overrides.values()]
      .filter((override) => override.included)
      .sort((left, right) => left.path.length - right.path.length);
    const roots: StoredPathOverride[] = [];

    for (const candidate of included) {
      if (roots.some((root) => root.root === candidate.root
        && isDescendant(candidate.path, root.path))) {
        continue;
      }
      roots.push(candidate);
    }

    return roots.map((override) => {
      const rootUri = vscode.Uri.parse(override.root);
      return override.path ? vscode.Uri.joinPath(rootUri, override.path) : rootUri;
    });
  }

  updateOverrides(
    updates: ReadonlyArray<{
      uri: vscode.Uri;
      included: boolean;
      recursive: boolean;
    }>
  ): Promise<void> {
    return this.enqueueOverrideUpdate(async () => {
      for (const update of updates) {
        const location = this.getLocation(update.uri);
        if (!location) {
          continue;
        }
        const key = getOverrideKey(location.root, location.path);
        this.overrides.set(key, { ...location, included: update.included });

        if (update.recursive) {
          for (const [existingKey, existing] of this.overrides) {
            if (existingKey !== key
              && existing.root === location.root
              && isDescendant(existing.path, location.path)) {
              this.overrides.delete(existingKey);
            }
          }
        }
      }

      await this.persistOverrides();
      this._onDidChange.fire('overrides');
    });
  }

  clearOverrides(): Promise<void> {
    return this.enqueueOverrideUpdate(async () => {
      this.overrides.clear();
      await this.persistOverrides();
      this._onDidChange.fire('overrides');
    });
  }

  dispose(): void {
    this.configurationSubscription.dispose();
    this._onDidChange.dispose();
  }

  private refreshPatterns(): void {
    const config = vscode.workspace.getConfiguration('cherryDiff');
    this.includes = config.get<string[]>('includePaths', ['**/*']);
    this.excludes = config.get<string[]>('excludePaths', []);
    this.includeMatchers = this.includes.map(
      (pattern) => new Minimatch(normalizeFilterPath(pattern), FILTER_MATCH_OPTIONS)
    );
    this.excludeMatchers = this.excludes.map(
      (pattern) => new Minimatch(normalizeFilterPath(pattern), FILTER_MATCH_OPTIONS)
    );
  }

  private getNearestOverride(root: string, relativePath: string): boolean | undefined {
    let candidate: string | undefined = normalizeFilterPath(relativePath);
    while (candidate !== undefined) {
      const override = this.overrides.get(getOverrideKey(root, candidate));
      if (override) {
        return override.included;
      }
      if (!candidate) {
        candidate = undefined;
      } else {
        const separatorIndex = candidate.lastIndexOf('/');
        candidate = separatorIndex === -1 ? '' : candidate.slice(0, separatorIndex);
      }
    }
    return undefined;
  }

  private setStoredOverrides(stored: StoredPathOverride[]): void {
    this.overrides.clear();
    for (const override of stored) {
      const normalized = {
        ...override,
        path: normalizeFilterPath(override.path),
      };
      this.overrides.set(getOverrideKey(normalized.root, normalized.path), normalized);
    }
  }

  private enqueueOverrideUpdate(operation: () => Promise<void>): Promise<void> {
    const result = this.overrideUpdateTail.then(operation, operation);
    this.overrideUpdateTail = result.then(() => undefined, () => undefined);
    return result;
  }

  private async persistOverrides(): Promise<void> {
    await this.workspaceState.update(
      PATH_OVERRIDES_STATE_KEY,
      [...this.overrides.values()]
    );
  }
}

function findNearestRelativeOverride(
  relativePath: string,
  overrides: PathOverrides
): boolean | undefined {
  let candidate: string | undefined = relativePath;
  while (candidate !== undefined) {
    if (Object.prototype.hasOwnProperty.call(overrides, candidate)) {
      return overrides[candidate];
    }
    if (!candidate) {
      candidate = undefined;
    } else {
      const separatorIndex = candidate.lastIndexOf('/');
      candidate = separatorIndex === -1 ? '' : candidate.slice(0, separatorIndex);
    }
  }
  return undefined;
}

function getWorkspaceRelativePath(
  folder: vscode.WorkspaceFolder,
  uri: vscode.Uri
): string {
  if (uri.scheme === folder.uri.scheme && uri.authority === folder.uri.authority) {
    if (uri.path === folder.uri.path) {
      return '';
    }
    const rootPrefix = folder.uri.path.endsWith('/')
      ? folder.uri.path
      : `${folder.uri.path}/`;
    if (uri.path.startsWith(rootPrefix)) {
      return normalizeFilterPath(uri.path.slice(rootPrefix.length));
    }
  }
  return normalizeFilterPath(vscode.workspace.asRelativePath(uri, false));
}

function getOverrideKey(root: string, relativePath: string): string {
  return `${root}\0${relativePath}`;
}

function isDescendant(candidate: string, parent: string): boolean {
  return parent === '' || candidate.startsWith(`${parent}/`);
}
