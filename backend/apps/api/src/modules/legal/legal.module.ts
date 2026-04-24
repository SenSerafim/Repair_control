import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { LegalService } from './legal.service';
import { LegalController } from './legal.controller';
import { LegalPublicController } from './legal-public.controller';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule],
  controllers: [LegalController, LegalPublicController],
  providers: [LegalService],
  exports: [LegalService],
})
export class LegalModule {}
