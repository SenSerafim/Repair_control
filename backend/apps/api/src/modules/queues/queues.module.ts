import { Global, Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { RedisClientModule } from './redis.module';

export const QUEUE_EXPORTS = 'exports';
export const QUEUE_PUSH = 'push';
export const QUEUE_DOCUMENT_THUMBNAILS = 'documents.thumbnails';

/**
 * BullMQ queue registry + Redis client provisioning.
 * @nestjs/bullmq сам поднимает ioredis из connection; мы также экспортируем отдельный клиент
 * для других потребителей (Socket.IO adapter, health checks).
 */
@Global()
@Module({
  imports: [
    RedisClientModule,
    BullModule.forRootAsync({
      useFactory: () => {
        // BullMQ (bullmq@5) принимает host/port отдельно, а не url.
        // Если REDIS_URL задан — парсим его руками. Это исправляет
        // регрессию ECONNREFUSED 127.0.0.1:6379 при наличии REDIS_URL=redis://redis:6379
        // (BullMQ молча игнорировал поле `url` и фоллбэчил на дефолты).
        const raw = process.env.REDIS_URL;
        let host = process.env.REDIS_HOST ?? 'localhost';
        let port = Number(process.env.REDIS_PORT ?? 6379);
        if (raw) {
          try {
            const u = new URL(raw);
            if (u.hostname) host = u.hostname;
            if (u.port) port = Number(u.port);
          } catch {
            // оставляем host/port из env vars
          }
        }
        return {
          connection: {
            host,
            port,
            maxRetriesPerRequest: null,
          },
          defaultJobOptions: {
            attempts: 3,
            backoff: { type: 'exponential', delay: 2000 },
            removeOnComplete: { count: 1000, age: 7 * 24 * 3600 },
            removeOnFail: { count: 1000, age: 7 * 24 * 3600 },
          },
        };
      },
    }),
    BullModule.registerQueue(
      { name: QUEUE_EXPORTS },
      { name: QUEUE_PUSH },
      { name: QUEUE_DOCUMENT_THUMBNAILS },
    ),
  ],
  exports: [BullModule, RedisClientModule],
})
export class QueuesModule {}
