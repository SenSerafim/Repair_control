import { forwardRef, Module } from '@nestjs/common';
import { StagesService } from './stages.service';
import { StagesController } from './stages.controller';
import { ProgressCalculator } from './progress-calculator';
import { StageLifecycle } from './stage-lifecycle';
import { ProgressCronService } from './progress-cron.service';
import { ApprovalsModule } from '../approvals/approvals.module';
import { ChatsModule } from '../chats/chats.module';

@Module({
  imports: [forwardRef(() => ApprovalsModule), ChatsModule],
  controllers: [StagesController],
  providers: [StagesService, ProgressCalculator, StageLifecycle, ProgressCronService],
  exports: [StagesService, ProgressCalculator],
})
export class StagesModule {}
