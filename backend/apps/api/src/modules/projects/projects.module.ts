import { Module } from '@nestjs/common';
import { ProjectsService } from './projects.service';
import { ProjectsController } from './projects.controller';
import { MembersService } from './members.service';
import { InvitationsService } from './invitations.service';

@Module({
  controllers: [ProjectsController],
  providers: [ProjectsService, MembersService, InvitationsService],
  exports: [ProjectsService],
})
export class ProjectsModule {}
