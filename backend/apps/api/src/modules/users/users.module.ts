import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { ProjectsModule } from '../projects/projects.module';

@Module({
  // ProjectsModule даёт MembersService — общий §1.4-фильтр видимости,
  // которым пользуется UsersService.listTeammates (нижний таб «Команда»).
  imports: [ProjectsModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
