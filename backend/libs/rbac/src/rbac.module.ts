import { Module } from '@nestjs/common';
import { AccessGuard } from './access.guard';

@Module({
  providers: [AccessGuard],
  exports: [AccessGuard],
})
export class RbacModule {}
