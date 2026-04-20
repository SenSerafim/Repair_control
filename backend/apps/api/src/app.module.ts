import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ScheduleModule } from '@nestjs/schedule';
import { ClockModule, PrismaModule, configValidationSchema } from '@app/common';
import { FilesModule } from '@app/files';
import { RbacModule } from '@app/rbac';
import { HealthModule } from './modules/health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProjectsModule } from './modules/projects/projects.module';
import { StagesModule } from './modules/stages/stages.module';
import { TemplatesModule } from './modules/templates/templates.module';
import { FeedModule } from './modules/feed/feed.module';
import { FilesApiModule } from './modules/files/files-api.module';
import { StepsModule } from './modules/steps/steps.module';
import { NotesModule } from './modules/notes/notes.module';
import { QuestionsModule } from './modules/questions/questions.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
      validationSchema: configValidationSchema,
      validationOptions: { allowUnknown: true, abortEarly: false },
    }),
    EventEmitterModule.forRoot(),
    ScheduleModule.forRoot(),
    PrismaModule,
    ClockModule,
    FilesModule.forRoot(),
    RbacModule,
    HealthModule,
    AuthModule,
    UsersModule,
    ProjectsModule,
    StagesModule,
    TemplatesModule,
    FeedModule,
    FilesApiModule,
    StepsModule,
    NotesModule,
    QuestionsModule,
  ],
})
export class AppModule {}
