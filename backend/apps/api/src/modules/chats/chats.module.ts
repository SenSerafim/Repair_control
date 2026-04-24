import { Module } from '@nestjs/common';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { FeedModule } from '../feed/feed.module';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';
import { MessagesService } from './messages.service';
import { ReadReceiptsService } from './read-receipts.service';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule, FeedModule],
  controllers: [ChatsController],
  providers: [ChatsService, MessagesService, ReadReceiptsService],
  exports: [ChatsService],
})
export class ChatsModule {}
