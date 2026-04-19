export interface CursorPage<T> {
  items: T[];
  nextCursor: string | null;
}

export const encodeCursor = (payload: Record<string, unknown>): string =>
  Buffer.from(JSON.stringify(payload)).toString('base64url');

export const decodeCursor = <T = Record<string, unknown>>(cursor: string | undefined): T | null => {
  if (!cursor) return null;
  try {
    return JSON.parse(Buffer.from(cursor, 'base64url').toString('utf-8')) as T;
  } catch {
    return null;
  }
};
