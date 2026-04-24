import { Module } from '@nestjs/common';
import { PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { AdminOverviewController } from './admin-overview.controller';
import { AdminOverviewService } from './admin-overview.service';

@Module({
  imports: [PrismaModule, RbacModule],
  controllers: [AdminOverviewController],
  providers: [AdminOverviewService],
})
export class AdminOverviewModule {}
