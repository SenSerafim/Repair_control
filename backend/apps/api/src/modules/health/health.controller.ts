import { Controller, Get, Inject } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Redis } from 'ioredis';
import { Client as MinioClient } from 'minio';
import { PrismaService } from '@app/common';
import { MINIO_CLIENT } from '@app/files';
import { REDIS_CLIENT } from '../queues/redis.module';

export interface HealthPayload {
  status: 'ok' | 'degraded';
  db: boolean;
  redis: boolean;
  minio: boolean;
  uptime: number;
}

@ApiTags('health')
@Controller()
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @Inject(MINIO_CLIENT) private readonly minio: MinioClient,
  ) {}

  @Get('healthz')
  async health(): Promise<HealthPayload> {
    const [db, redis, minio] = await Promise.all([
      this.checkDb(),
      this.checkRedis(),
      this.checkMinio(),
    ]);
    return {
      status: db && redis && minio ? 'ok' : 'degraded',
      db,
      redis,
      minio,
      uptime: Math.round(process.uptime()),
    };
  }

  private async checkDb(): Promise<boolean> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return true;
    } catch {
      return false;
    }
  }

  private async checkRedis(): Promise<boolean> {
    try {
      const reply = await withTimeout(this.redis.ping(), 500);
      return reply === 'PONG';
    } catch {
      return false;
    }
  }

  private async checkMinio(): Promise<boolean> {
    try {
      await withTimeout(this.minio.listBuckets(), 500);
      return true;
    } catch {
      return false;
    }
  }
}

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    p,
    new Promise<T>((_r, reject) => setTimeout(() => reject(new Error('timeout')), ms)),
  ]);
}
