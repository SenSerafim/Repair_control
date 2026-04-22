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
      useFactory: () => ({
        connection: {
          url:
            process.env.REDIS_URL ??
            `redis://${process.env.REDIS_HOST ?? 'localhost'}:${process.env.REDIS_PORT ?? 6379}`,
          maxRetriesPerRequest: null,
        },
        defaultJobOptions: {
          attempts: 3,
          backoff: { type: 'exponential', delay: 2000 },
          removeOnComplete: { count: 1000, age: 7 * 24 * 3600 },
          removeOnFail: { count: 1000, age: 7 * 24 * 3600 },
        },
      }),
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
