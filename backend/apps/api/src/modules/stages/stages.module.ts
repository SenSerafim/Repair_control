import { Module } from '@nestjs/common';
import { StagesService } from './stages.service';
import { StagesController } from './stages.controller';
import { ProgressCalculator } from './progress-calculator';
import { StageLifecycle } from './stage-lifecycle';
import { ProgressCronService } from './progress-cron.service';

@Module({
  controllers: [StagesController],
  providers: [StagesService, ProgressCalculator, StageLifecycle, ProgressCronService],
  exports: [StagesService, ProgressCalculator],
})
export class StagesModule {}
