import { forwardRef, Module } from '@nestjs/common';
import { StagesModule } from '../stages/stages.module';
import { ApprovalsController } from './approvals.controller';
import { ApprovalsService } from './approvals.service';

@Module({
  imports: [forwardRef(() => StagesModule)],
  controllers: [ApprovalsController],
  providers: [ApprovalsService],
  exports: [ApprovalsService],
})
export class ApprovalsModule {}
