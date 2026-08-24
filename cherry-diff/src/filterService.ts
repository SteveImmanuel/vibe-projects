import * as vscode from 'vscode';
import { globMatch } from './glob';

export type PathOverrides = Record<string, boolean>;

export function normalizeFilterPath(relativePath: string): string {
  const normalized = relativePath.replace(/\\/g, '/').replace(/^\.\//, '');
  return normalized === '.' ? '' : normalized.replace(/\/$/, '');
}

export function getFilterPath(uri: vscode.Uri): string {
  return normalizeFilterPath(vscode.workspace.asRelativePath(uri, false));
}

export function isPathIncluded(
  relativePath: string,
  includes: string[],
  excludes: string[],
  overrides: PathOverrides
): boolean {
  const normalizedPath = normalizeFilterPath(relativePath);
  const override = getNearestOverride(normalizedPath, overrides);
  if (override !== undefined) {
    return override;
  }

  if (excludes.some((pattern) => globMatch(normalizedPath, pattern))) {
    return false;
  }
  return includes.some((pattern) => globMatch(normalizedPath, pattern));
}

export function isUriIncluded(uri: vscode.Uri, asDirectory = false): boolean {
  const config = vscode.workspace.getConfiguration('cherryDiff');
  const filterPath = getFilterPath(uri);
  return isPathIncluded(
    asDirectory ? `${filterPath}/__cherry_diff_child__` : filterPath,
    config.get<string[]>('includePaths', ['**/*']),
    config.get<string[]>('excludePaths', []),
    config.get<PathOverrides>('pathOverrides', {})
  );
}

export async function updatePathOverrides(
  updates: ReadonlyArray<{ path: string; included: boolean; recursive: boolean }>
): Promise<void> {
  const config = vscode.workspace.getConfiguration('cherryDiff');
  const overrides = {
    ...config.get<PathOverrides>('pathOverrides', {}),
  };

  for (const update of updates) {
    const filterPath = normalizeFilterPath(update.path);
    overrides[filterPath] = update.included;
    if (update.recursive) {
      for (const existingPath of Object.keys(overrides)) {
        if (existingPath !== filterPath && isDescendant(existingPath, filterPath)) {
          delete overrides[existingPath];
        }
      }
    }
  }

  const target = vscode.workspace.workspaceFolders
    ? vscode.ConfigurationTarget.Workspace
    : vscode.ConfigurationTarget.Global;
  await config.update('pathOverrides', overrides, target);
}

export async function clearPathOverrides(): Promise<void> {
  const config = vscode.workspace.getConfiguration('cherryDiff');
  const target = vscode.workspace.workspaceFolders
    ? vscode.ConfigurationTarget.Workspace
    : vscode.ConfigurationTarget.Global;
  await config.update('pathOverrides', {}, target);
}

function getNearestOverride(
  relativePath: string,
  overrides: PathOverrides
): boolean | undefined {
  let nearestPathLength = -1;
  let result: boolean | undefined;

  for (const [overridePathValue, included] of Object.entries(overrides)) {
    const overridePath = normalizeFilterPath(overridePathValue);
    if (relativePath === overridePath || isDescendant(relativePath, overridePath)) {
      if (overridePath.length > nearestPathLength) {
        nearestPathLength = overridePath.length;
        result = included;
      }
    }
  }

  return result;
}

function isDescendant(candidate: string, parent: string): boolean {
  return parent === '' || candidate.startsWith(`${parent}/`);
}
