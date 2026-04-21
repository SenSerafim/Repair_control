import { InvalidInputError } from '../errors/domain-errors';
import { Money } from './money';

describe('Money value-object (ТЗ §4, §5.6)', () => {
  it('plus/minus: арифметика int64 копеек', () => {
    const a = Money.ofKopeks(500_000_00); // 500k₽
    const b = Money.ofKopeks(100_000_00); // 100k₽
    expect(a.plus(b).kopeks()).toBe(BigInt(600_000_00));
    expect(a.minus(b).kopeks()).toBe(BigInt(400_000_00));
  });

  it('складывает суммы, превышающие MAX_SAFE_INTEGER', () => {
    const big = BigInt(Number.MAX_SAFE_INTEGER) - BigInt(100);
    const a = Money.ofKopeks(big);
    const b = Money.ofKopeks(200);
    const sum = a.plus(b);
    expect(sum.kopeks()).toBe(big + BigInt(200));
  });

  it('isNegative / isZero / сравнения', () => {
    expect(Money.ofKopeks(-1).isNegative()).toBe(true);
    expect(Money.zero().isZero()).toBe(true);
    expect(Money.ofKopeks(5).lessThan(Money.ofKopeks(10))).toBe(true);
    expect(Money.ofKopeks(10).greaterThan(Money.ofKopeks(5))).toBe(true);
    expect(Money.ofKopeks(5).equals(Money.ofKopeks(5))).toBe(true);
  });

  it('ensureNonNegative: отрицательные выбрасывают InvalidInputError', () => {
    expect(() => Money.ofKopeks(-1).ensureNonNegative()).toThrow(InvalidInputError);
    expect(() => Money.zero().ensureNonNegative()).not.toThrow();
    expect(() => Money.ofKopeks(100).ensureNonNegative()).not.toThrow();
  });

  it('ensurePositive: ноль и отрицательные выбрасывают', () => {
    expect(() => Money.zero().ensurePositive()).toThrow(InvalidInputError);
    expect(() => Money.ofKopeks(-1).ensurePositive()).toThrow(InvalidInputError);
    expect(() => Money.ofKopeks(1).ensurePositive()).not.toThrow();
  });

  it('sanity: amount > 10^18 копеек отклоняется', () => {
    expect(() => Money.ofKopeks(BigInt(10) ** BigInt(19))).toThrow(InvalidInputError);
  });

  it('JSON: в пределах safe int → number; за пределами → string', () => {
    expect(JSON.parse(JSON.stringify(Money.ofKopeks(1_200_000_00)))).toBe(1_200_000_00);
    const bigVal = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(10);
    const m = Money.ofKopeks(bigVal);
    expect(typeof JSON.parse(JSON.stringify(m))).toBe('string');
  });
});
