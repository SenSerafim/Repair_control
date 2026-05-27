import { forwardRef, Global, Module } from '@nestjs/common';
import { ExportsModule } from '../exports/exports.module';
import { FeedController } from './feed.controller';
import { FeedPeriodPdfService } from './feed-period-pdf.service';
import { FeedService } from './feed.service';

@Global()
@Module({
  imports: [forwardRef(() => ExportsModule)],
  controllers: [FeedController],
  providers: [FeedService, FeedPeriodPdfService],
  exports: [FeedService],
})
export class FeedModule {}
