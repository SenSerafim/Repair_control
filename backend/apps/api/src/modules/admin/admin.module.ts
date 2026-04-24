import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { FeedModule } from '../feed/feed.module';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule, FeedModule],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
