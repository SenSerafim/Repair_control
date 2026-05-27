import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UserProfileService } from './user-profile.service';
import { UsersController } from './users.controller';
import { UserProfileController } from './user-profile.controller';
import { ProjectsModule } from '../projects/projects.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  // ProjectsModule даёт MembersService — общий §1.4-фильтр видимости,
  // которым пользуется UsersService.listTeammates (нижний таб «Команда»).
  // AuthModule — для перевыпуска токенов при смене активной роли.
  imports: [ProjectsModule, AuthModule],
  controllers: [UsersController, UserProfileController],
  providers: [UsersService, UserProfileService],
  exports: [UsersService],
})
export class UsersModule {}
