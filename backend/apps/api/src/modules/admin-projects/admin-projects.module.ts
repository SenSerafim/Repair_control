import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { AdminProjectsService } from './admin-projects.service';
import { AdminProjectsController } from './admin-projects.controller';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule],
  controllers: [AdminProjectsController],
  providers: [AdminProjectsService],
  exports: [AdminProjectsService],
})
export class AdminProjectsModule {}
