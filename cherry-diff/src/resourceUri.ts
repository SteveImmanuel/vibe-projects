import * as vscode from 'vscode';

export function isSameOrDescendant(candidate: vscode.Uri, parent: vscode.Uri): boolean {
  if (candidate.scheme !== parent.scheme || candidate.authority !== parent.authority) {
    return false;
  }
  if (candidate.path === parent.path) {
    return true;
  }
  const prefix = parent.path.endsWith('/') ? parent.path : `${parent.path}/`;
  return candidate.path.startsWith(prefix);
}
