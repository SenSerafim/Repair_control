import { forwardRef, Module } from '@nestjs/common';
import { ApprovalsModule } from '../approvals/approvals.module';
import { ExportsModule } from '../exports/exports.module';
import { MaterialsController } from './materials.controller';
import { MaterialsPdfService } from './materials-pdf.service';
import { MaterialsScheduler } from './materials.scheduler';
import { MaterialsService } from './materials.service';

@Module({
  imports: [forwardRef(() => ApprovalsModule), ExportsModule],
  controllers: [MaterialsController],
  providers: [MaterialsService, MaterialsScheduler, MaterialsPdfService],
  exports: [MaterialsService],
})
export class MaterialsModule {}
