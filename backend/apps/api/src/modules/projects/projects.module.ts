import { Module } from '@nestjs/common';
import { ProjectsService } from './projects.service';
import { ProjectsController } from './projects.controller';
import { MembersService } from './members.service';
import { InvitationsService } from './invitations.service';
import { ChatsModule } from '../chats/chats.module';

@Module({
  imports: [ChatsModule],
  controllers: [ProjectsController],
  providers: [ProjectsService, MembersService, InvitationsService],
  exports: [ProjectsService],
})
export class ProjectsModule {}
