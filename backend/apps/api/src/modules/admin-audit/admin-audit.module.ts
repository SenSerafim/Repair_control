import { Global, Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { AdminAuditService } from './admin-audit.service';
import { AdminAuditController } from './admin-audit.controller';

@Global()
@Module({
  imports: [PrismaModule, ClockModule, RbacModule],
  controllers: [AdminAuditController],
  providers: [AdminAuditService],
  exports: [AdminAuditService],
})
export class AdminAuditModule {}
