import { SetMetadata, applyDecorators, UseInterceptors } from '@nestjs/common';
import { IdempotencyInterceptor } from './idempotency.interceptor';

export const IDEMPOTENT_KEY = 'idempotency.enabled';

/**
 * @Idempotent() — включает IdempotencyInterceptor на endpoint'е.
 * Заголовок `Idempotency-Key` обязателен: его отсутствие → 400.
 */
export const Idempotent = () =>
  applyDecorators(SetMetadata(IDEMPOTENT_KEY, true), UseInterceptors(IdempotencyInterceptor));
