import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { BroadcastsService } from './broadcasts.service';
import { BroadcastsController } from './broadcasts.controller';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule],
  controllers: [BroadcastsController],
  providers: [BroadcastsService],
  exports: [BroadcastsService],
})
export class BroadcastsModule {}
