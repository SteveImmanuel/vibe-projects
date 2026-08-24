import * as vscode from 'vscode';
import { UTF8_BOM_BYTES } from './constants';

type TextEncoding = 'utf8' | 'utf8bom';

export interface FileSnapshot {
  exists: boolean;
  bytes: Uint8Array;
  /** Undefined for binary or unsupported text encodings. */
  text?: string;
  encoding?: TextEncoding;
}

type FileReadResult =
  | { kind: 'snapshot'; snapshot: FileSnapshot }
  | { kind: 'directory' }
  | { kind: 'unstable' };

export function missingFileSnapshot(): FileSnapshot {
  return {
    exists: false,
    bytes: new Uint8Array(),
    text: '',
    encoding: 'utf8',
  };
}

export function textFileSnapshot(
  text: string,
  encoding: TextEncoding = 'utf8'
): FileSnapshot {
  return {
    exists: true,
    bytes: encodeText(text, encoding),
    text,
    encoding,
  };
}

export function snapshotFromBytes(bytes: Uint8Array): FileSnapshot {
  const decoded = decodeText(bytes);
  return {
    exists: true,
    bytes,
    text: decoded?.text,
    encoding: decoded?.encoding,
  };
}

function encodeText(text: string, encoding: TextEncoding): Uint8Array {
  const content = new TextEncoder().encode(text);
  if (encoding === 'utf8') {
    return content;
  }

  const bytes = new Uint8Array(UTF8_BOM_BYTES.length + content.length);
  bytes.set(UTF8_BOM_BYTES, 0);
  bytes.set(content, UTF8_BOM_BYTES.length);
  return bytes;
}

export function snapshotsEqual(left: FileSnapshot, right: FileSnapshot): boolean {
  if (left.exists !== right.exists || left.bytes.length !== right.bytes.length) {
    return false;
  }
  for (let index = 0; index < left.bytes.length; index++) {
    if (left.bytes[index] !== right.bytes[index]) {
      return false;
    }
  }
  return true;
}

export function isFileNotFound(error: unknown): boolean {
  const code = typeof vscode.FileSystemError === 'function'
    && error instanceof vscode.FileSystemError
    ? error.code
    : typeof error === 'object' && error !== null && 'code' in error
      ? (error as { code?: unknown }).code
      : undefined;
  return code === 'FileNotFound' || code === 'ENOENT';
}

/**
 * Read a stable file snapshot. Open UTF-8 documents use their in-memory text
 * so unsaved edits are included; unsupported encodings remain byte-only.
 */
export async function readFileSnapshot(uri: vscode.Uri): Promise<FileReadResult> {
  let statBefore: vscode.FileStat;
  try {
    statBefore = await vscode.workspace.fs.stat(uri);
  } catch (error) {
    if (isFileNotFound(error)) {
      return { kind: 'snapshot', snapshot: missingFileSnapshot() };
    }
    throw error;
  }

  if ((statBefore.type & vscode.FileType.Directory) !== 0) {
    return { kind: 'directory' };
  }

  const uriKey = uri.toString();
  const openDocument = vscode.workspace.textDocuments.find(
    (document) => document.uri.toString() === uriKey
  );
  const documentVersion = openDocument?.version;

  let diskBytes: Uint8Array;
  let statAfter: vscode.FileStat;
  try {
    diskBytes = await vscode.workspace.fs.readFile(uri);
    statAfter = await vscode.workspace.fs.stat(uri);
  } catch (error) {
    if (isFileNotFound(error)) {
      return { kind: 'unstable' };
    }
    throw error;
  }

  if (statBefore.mtime !== statAfter.mtime || statBefore.size !== statAfter.size) {
    return { kind: 'unstable' };
  }
  if (documentVersion !== undefined && openDocument?.version !== documentVersion) {
    return { kind: 'unstable' };
  }

  const diskSnapshot = snapshotFromBytes(diskBytes);
  if (!openDocument || diskSnapshot.text === undefined || !diskSnapshot.encoding) {
    return { kind: 'snapshot', snapshot: diskSnapshot };
  }

  const text = openDocument.getText();
  return {
    kind: 'snapshot',
    snapshot: textFileSnapshot(text, diskSnapshot.encoding),
  };
}

function decodeText(
  bytes: Uint8Array
): { text: string; encoding: TextEncoding } | undefined {
  const hasBom = bytes.length >= UTF8_BOM_BYTES.length
    && bytes[0] === UTF8_BOM_BYTES[0]
    && bytes[1] === UTF8_BOM_BYTES[1]
    && bytes[2] === UTF8_BOM_BYTES[2];

  try {
    const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    if (text.includes('\0')) {
      return undefined;
    }
    return {
      text,
      encoding: hasBom ? 'utf8bom' : 'utf8',
    };
  } catch {
    return undefined;
  }
}
