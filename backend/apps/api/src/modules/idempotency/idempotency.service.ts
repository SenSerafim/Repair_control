import * as crypto from 'crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Clock, ConflictError, ErrorCodes, PrismaService } from '@app/common';

export const IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000; // 24 часа

export interface StoredResponse {
  statusCode: number;
  response: unknown;
}

/**
 * Idempotency-Key persistence (ТЗ §5.1).
 *
 * Key в DB: `<userId>:<endpoint>:<headerKey>` — пара (user+endpoint) изолирует ключи
 * от конфликта между разными эндпоинтами, но сохраняет идемпотентность в рамках операции.
 */
@Injectable()
export class IdempotencyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  composeKey(userId: string, endpoint: string, headerKey: string): string {
    return `${userId}:${endpoint}:${headerKey}`;
  }

  hashRequest(body: unknown): string {
    const canonical = JSON.stringify(body ?? {}, Object.keys(body ?? {}).sort());
    return crypto.createHash('sha256').update(canonical).digest('hex');
  }

  /**
   * Попытка забронировать ключ.
   * - Если запись отсутствует — создаём stub (без response) и возвращаем { reserved: true }.
   * - Если запись есть и requestHash совпадает:
   *   - response!=null → { replay: true, statusCode, response } (повтор ответа)
   *   - response===null → { inFlight: true } (запрос параллельно обрабатывается — сейчас возвращаем 409)
   * - Если requestHash не совпадает → ConflictError IDEMPOTENCY_MISMATCH.
   */
  async reserve(input: {
    key: string;
    userId: string;
    endpoint: string;
    requestHash: string;
  }): Promise<
    | { reserved: true }
    | { replay: true; statusCode: number; response: unknown }
    | { inFlight: true }
  > {
    const existing = await this.prisma.idempotencyRecord.findUnique({ where: { key: input.key } });
    const now = this.clock.now();
    if (existing && existing.expiresAt.getTime() > now.getTime()) {
      if (existing.requestHash !== input.requestHash) {
        throw new ConflictError(
          ErrorCodes.IDEMPOTENCY_MISMATCH,
          'idempotency key reused with different request body',
        );
      }
      if (existing.response != null && existing.statusCode != null) {
        return { replay: true, statusCode: existing.statusCode, response: existing.response };
      }
      return { inFlight: true };
    }
    if (existing) {
      // истёк — удаляем и пересоздаём
      await this.prisma.idempotencyRecord.delete({ where: { key: input.key } });
    }
    await this.prisma.idempotencyRecord.create({
      data: {
        key: input.key,
        userId: input.userId,
        endpoint: input.endpoint,
        requestHash: input.requestHash,
        expiresAt: new Date(now.getTime() + IDEMPOTENCY_TTL_MS),
      },
    });
    return { reserved: true };
  }

  async persistResponse(key: string, statusCode: number, response: unknown): Promise<void> {
    await this.prisma.idempotencyRecord.update({
      where: { key },
      data: { statusCode, response: response as Prisma.InputJsonValue },
    });
  }

  async releaseOnError(key: string): Promise<void> {
    // Убираем stub, чтобы клиент мог повторить
    await this.prisma.idempotencyRecord.delete({ where: { key } }).catch(() => undefined);
  }
}
