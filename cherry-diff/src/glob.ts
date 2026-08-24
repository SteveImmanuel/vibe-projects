/**
 * Match a workspace-relative path against a glob containing **, *, and ?.
 * Paths and patterns are normalized to forward slashes for portability.
 */
export function globMatch(filepath: string, pattern: string): boolean {
  filepath = filepath.replace(/\\/g, '/');
  pattern = pattern.replace(/\\/g, '/');

  let regex = '';
  let i = 0;
  while (i < pattern.length) {
    if (pattern[i] === '*' && pattern[i + 1] === '*') {
      if (pattern[i + 2] === '/') {
        regex += '(?:.+/)?';
        i += 3;
      } else {
        regex += '.*';
        i += 2;
      }
    } else if (pattern[i] === '*') {
      regex += '[^/]*';
      i++;
    } else if (pattern[i] === '?') {
      regex += '[^/]';
      i++;
    } else if ('.+^${}()|[]\\'.includes(pattern[i])) {
      regex += `\\${pattern[i]}`;
      i++;
    } else {
      regex += pattern[i];
      i++;
    }
  }

  try {
    return new RegExp(`^${regex}$`).test(filepath);
  } catch {
    return false;
  }
}
