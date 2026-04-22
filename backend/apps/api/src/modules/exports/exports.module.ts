import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { FilesModule } from '@app/files';
import { FeedModule } from '../feed/feed.module';
import { IdempotencyModule } from '../idempotency/idempotency.module';
import { QUEUE_EXPORTS } from '../queues/queues.module';
import { ExportService } from './export.service';
import { ExportsController } from './exports.controller';
import { PdfRendererService } from './pdf-renderer.service';
import { ZipPackerService } from './zip-packer.service';
import { ExportProcessor } from './export-pdf.processor';

@Module({
  imports: [
    PrismaModule,
    ClockModule,
    RbacModule,
    FeedModule,
    IdempotencyModule,
    FilesModule.forRoot(),
    BullModule.registerQueue({ name: QUEUE_EXPORTS }),
  ],
  controllers: [ExportsController],
  providers: [ExportService, PdfRendererService, ZipPackerService, ExportProcessor],
  exports: [ExportService],
})
export class ExportsModule {}
