import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { FilesModule } from '@app/files';
import { FeedModule } from '../feed/feed.module';
import { QUEUE_DOCUMENT_THUMBNAILS } from '../queues/queues.module';
import { DocumentsService } from './documents.service';
import { DocumentsController } from './documents.controller';
import { ThumbnailWorker } from './thumbnail-worker.service';

@Module({
  imports: [
    PrismaModule,
    ClockModule,
    RbacModule,
    FeedModule,
    FilesModule.forRoot(),
    BullModule.registerQueue({ name: QUEUE_DOCUMENT_THUMBNAILS }),
  ],
  controllers: [DocumentsController],
  providers: [DocumentsService, ThumbnailWorker],
  exports: [DocumentsService],
})
export class DocumentsModule {}
