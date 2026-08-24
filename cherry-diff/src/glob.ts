import { Minimatch } from 'minimatch';
import { FILTER_MATCH_OPTIONS } from './constants';

/** Match a normalized workspace-relative path with the shared glob semantics. */
export function globMatch(filepath: string, pattern: string): boolean {
  try {
    return new Minimatch(
      pattern.replace(/\\/g, '/'),
      FILTER_MATCH_OPTIONS
    ).match(filepath.replace(/\\/g, '/'));
  } catch {
    return false;
  }
}
