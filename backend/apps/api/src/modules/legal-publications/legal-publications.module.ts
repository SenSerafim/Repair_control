import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { AdminAuditModule } from '../admin-audit/admin-audit.module';
import { LegalPublicationsService } from './legal-publications.service';
import { LegalPublicationsController } from './legal-publications.controller';
import { LegalPublicationsPublicController } from './legal-publications-public.controller';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule, AdminAuditModule],
  controllers: [LegalPublicationsController, LegalPublicationsPublicController],
  providers: [LegalPublicationsService],
  exports: [LegalPublicationsService],
})
export class LegalPublicationsModule {}
