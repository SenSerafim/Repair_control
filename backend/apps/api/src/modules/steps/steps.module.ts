import { Module } from '@nestjs/common';
import { StagesModule } from '../stages/stages.module';
import { StepsController } from './steps.controller';
import { StepsService } from './steps.service';
import { SubstepsService } from './substeps.service';
import { StepPhotosService } from './step-photos.service';

@Module({
  imports: [StagesModule],
  controllers: [StepsController],
  providers: [StepsService, SubstepsService, StepPhotosService],
  exports: [StepsService, SubstepsService],
})
export class StepsModule {}
