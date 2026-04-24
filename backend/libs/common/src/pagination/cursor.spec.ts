import { decodeCursor, encodeCursor } from './cursor';

describe('cursor encoding', () => {
  it('round-trips payload', () => {
    const payload = { id: 'abc', ts: 1700000000 };
    const cursor = encodeCursor(payload);
    expect(decodeCursor<typeof payload>(cursor)).toEqual(payload);
  });

  it('returns null for missing cursor', () => {
    expect(decodeCursor(undefined)).toBeNull();
  });

  it('returns null for malformed cursor', () => {
    expect(decodeCursor('not-a-valid-base64url')).toBeNull();
  });
});
