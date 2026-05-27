import { forwardRef, Module } from '@nestjs/common';
import { ApprovalsModule } from '../approvals/approvals.module';
import { MaterialsController } from './materials.controller';
import { MaterialsScheduler } from './materials.scheduler';
import { MaterialsService } from './materials.service';

@Module({
  imports: [forwardRef(() => ApprovalsModule)],
  controllers: [MaterialsController],
  providers: [MaterialsService, MaterialsScheduler],
  exports: [MaterialsService],
})
export class MaterialsModule {}
