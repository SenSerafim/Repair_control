import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { RedisClientModule } from '../queues/redis.module';

@Module({
  imports: [RedisClientModule],
  controllers: [HealthController],
})
export class HealthModule {}
