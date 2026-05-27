import { Module } from '@nestjs/common';
import { ProjectsService } from './projects.service';
import { ProjectsController } from './projects.controller';
import { MembersService } from './members.service';
import { InvitationsService } from './invitations.service';
import { ChatsModule } from '../chats/chats.module';
import { ProgressCalculator } from '../stages/progress-calculator';

@Module({
  imports: [ChatsModule],
  controllers: [ProjectsController],
  providers: [
    ProjectsService,
    MembersService,
    InvitationsService,
    // QA-баг #13: после copy() нужно пересчитать semaphoreCache, иначе у
    // скопированного проекта остаётся дефолтный 'green' независимо от
    // дат/статусов скопированных стадий. ProgressCalculator не зависит
    // от StagesModule (только от PrismaService + Clock), поэтому
    // подключаем его как локальный provider — без forwardRef и циклов.
    ProgressCalculator,
  ],
  exports: [ProjectsService, MembersService],
})
export class ProjectsModule {}
