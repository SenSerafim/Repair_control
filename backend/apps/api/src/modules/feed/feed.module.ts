import { Global, Module } from '@nestjs/common';
import { FeedService } from './feed.service';

@Global()
@Module({
  providers: [FeedService],
  exports: [FeedService],
})
export class FeedModule {}
