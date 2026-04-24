import { Global, Module } from '@nestjs/common';
import { Redis } from 'ioredis';

export const REDIS_CLIENT = Symbol('REDIS_CLIENT');
export const REDIS_PUBSUB_CLIENT = Symbol('REDIS_PUBSUB_CLIENT');

/**
 * Базовые Redis-клиенты. Один — для обычных операций, второй — только для pub/sub
 * (socket.io adapter поднимает из него pub+sub duplicate). Глобальный, чтобы любой модуль мог инжектить.
 */
@Global()
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      useFactory: () => {
        const url =
          process.env.REDIS_URL ??
          `redis://${process.env.REDIS_HOST ?? 'localhost'}:${process.env.REDIS_PORT ?? 6379}`;
        return new Redis(url, {
          maxRetriesPerRequest: null, // BullMQ требует null
          enableReadyCheck: true,
          lazyConnect: false,
        });
      },
    },
    {
      provide: REDIS_PUBSUB_CLIENT,
      useFactory: () => {
        const url =
          process.env.REDIS_URL ??
          `redis://${process.env.REDIS_HOST ?? 'localhost'}:${process.env.REDIS_PORT ?? 6379}`;
        return new Redis(url, { maxRetriesPerRequest: null });
      },
    },
  ],
  exports: [REDIS_CLIENT, REDIS_PUBSUB_CLIENT],
})
export class RedisClientModule {}
