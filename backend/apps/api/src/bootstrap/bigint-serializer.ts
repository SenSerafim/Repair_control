/**
 * Prisma возвращает BigInt для колонок BigInt (Money, pauseDurationMs, workBudget...).
 * Express JSON.stringify не умеет их сериализовать. Приводим к number (безопасно, пока не выходим
 * за 2^53 — для копеек и миллисекунд пауз этого хватает с запасом).
 * Для защиты от потерь при больших значениях — явный cast в number только если влезает, иначе toString.
 */
(BigInt.prototype as unknown as { toJSON: () => number | string }).toJSON = function toJSON() {
  const asNumber = Number(this);
  if (Number.isSafeInteger(asNumber)) return asNumber;
  return (this as unknown as bigint).toString();
};
