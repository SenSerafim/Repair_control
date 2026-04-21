import { InvalidInputError } from '../errors/domain-errors';

/**
 * Money value-object — int64 копейки (ТЗ §4, §5.6).
 *
 * Inner representation: BigInt. JSON serialization:
 *  - if |value| <= MAX_SAFE_INTEGER → number (удобно для фронта)
 *  - иначе → string (чтобы не потерять точность)
 *
 * Все финансовые сервисы обязаны использовать Money для сумм:
 * никаких `number` для денег на уровне доменной логики.
 */
export class Money {
  // 10^18 копеек = 10^16 рублей — sanity bound, покрывает любые реальные суммы и
  // оставляет ветку string-JSON-сериализации (для значений > MAX_SAFE_INTEGER) рабочей.
  private static readonly MAX_ABS_KOPEKS = BigInt(10) ** BigInt(18);
  private readonly value: bigint;

  private constructor(value: bigint) {
    this.value = value;
  }

  static ofKopeks(n: bigint | number): Money {
    const big = typeof n === 'bigint' ? n : BigInt(Math.trunc(n));
    if (big > Money.MAX_ABS_KOPEKS || big < -Money.MAX_ABS_KOPEKS) {
      throw new InvalidInputError(
        'finance.amount_out_of_range',
        `amount exceeds sanity bound: ${big.toString()}`,
      );
    }
    return new Money(big);
  }

  static zero(): Money {
    return new Money(BigInt(0));
  }

  kopeks(): bigint {
    return this.value;
  }

  plus(other: Money): Money {
    return Money.ofKopeks(this.value + other.value);
  }

  minus(other: Money): Money {
    return Money.ofKopeks(this.value - other.value);
  }

  isNegative(): boolean {
    return this.value < BigInt(0);
  }

  isZero(): boolean {
    return this.value === BigInt(0);
  }

  lessThan(other: Money): boolean {
    return this.value < other.value;
  }

  greaterThan(other: Money): boolean {
    return this.value > other.value;
  }

  equals(other: Money): boolean {
    return this.value === other.value;
  }

  ensureNonNegative(errorCode = 'finance.negative_amount'): Money {
    if (this.isNegative()) {
      throw new InvalidInputError(errorCode, `amount must be non-negative: ${this.value}`);
    }
    return this;
  }

  ensurePositive(errorCode = 'finance.non_positive_amount'): Money {
    if (this.value <= BigInt(0)) {
      throw new InvalidInputError(errorCode, `amount must be positive: ${this.value}`);
    }
    return this;
  }

  /**
   * JSON-сериализация. Возвращает number если влезает в 2^53, иначе string.
   * Совместимо с bigint-serializer.ts, который патчит BigInt.prototype.toJSON.
   */
  toJSON(): number | string {
    const v = this.value;
    const max = BigInt(Number.MAX_SAFE_INTEGER);
    if (v >= -max && v <= max) return Number(v);
    return v.toString();
  }

  toString(): string {
    return this.value.toString();
  }
}
