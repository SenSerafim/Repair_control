import {
  DEFAULT_REPRESENTATIVE_RIGHTS,
  sanitizeRepresentativeRights,
} from './representative-rights';

describe('sanitizeRepresentativeRights', () => {
  it('returns defaults when input is undefined', () => {
    expect(sanitizeRepresentativeRights(undefined)).toEqual(DEFAULT_REPRESENTATIVE_RIGHTS);
  });

  it('accepts only boolean values and drops unknown keys', () => {
    const result = sanitizeRepresentativeRights({
      canApprove: true,
      canEditStages: false,
      canSeeBudget: 'yes' as unknown as boolean, // должен быть отброшен (не boolean)
      unknownKey: true, // не в списке — должен быть отброшен
    });
    expect(result.canApprove).toBe(true);
    expect(result.canEditStages).toBe(false);
    expect(result.canSeeBudget).toBe(false); // остался дефолт
    expect((result as any).unknownKey).toBeUndefined();
  });

  it('does not mutate DEFAULT_REPRESENTATIVE_RIGHTS', () => {
    const before = { ...DEFAULT_REPRESENTATIVE_RIGHTS };
    sanitizeRepresentativeRights({ canApprove: true });
    expect(DEFAULT_REPRESENTATIVE_RIGHTS).toEqual(before);
  });
});
