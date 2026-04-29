import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { AdminAuditModule } from '../admin-audit/admin-audit.module';
import { KnowledgeService } from './knowledge.service';
import { KnowledgeSearchService } from './knowledge-search.service';
import { KnowledgeController } from './knowledge.controller';
import { KnowledgeAdminController } from './knowledge-admin.controller';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule, AdminAuditModule],
  controllers: [KnowledgeController, KnowledgeAdminController],
  providers: [KnowledgeService, KnowledgeSearchService],
  exports: [KnowledgeService, KnowledgeSearchService],
})
export class KnowledgeModule {}
