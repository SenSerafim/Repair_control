import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ScheduleModule } from '@nestjs/schedule';
import { ClockModule, PrismaModule, configValidationSchema } from '@app/common';
import { FilesModule } from '@app/files';
import { RbacModule } from '@app/rbac';
import { loggerModule } from './bootstrap/logger';
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
import { ApprovalsModule } from './modules/approvals/approvals.module';
import { MethodologyModule } from './modules/methodology/methodology.module';
import { IdempotencyModule } from './modules/idempotency/idempotency.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { MaterialsModule } from './modules/materials/materials.module';
import { SelfPurchasesModule } from './modules/selfpurchases/selfpurchases.module';
import { ToolsModule } from './modules/tools/tools.module';
import { QueuesModule } from './modules/queues/queues.module';
import { MetricsModule } from './modules/metrics/metrics.module';
import { ChatsModule } from './modules/chats/chats.module';
import { RealtimeModule } from './modules/realtime/realtime.module';
import { DocumentsModule } from './modules/documents/documents.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ExportsModule } from './modules/exports/exports.module';
import { FeedbackModule } from './modules/feedback/feedback.module';
import { AdminModule } from './modules/admin/admin.module';
import { AdminAuditModule } from './modules/admin-audit/admin-audit.module';
import { AdminUsersModule } from './modules/admin-users/admin-users.module';
import { AdminProjectsModule } from './modules/admin-projects/admin-projects.module';
import { AdminOverviewModule } from './modules/admin-overview/admin-overview.module';
import { LegalModule } from './modules/legal/legal.module';
import { BroadcastsModule } from './modules/broadcasts/broadcasts.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
      validationSchema: configValidationSchema,
      validationOptions: { allowUnknown: true, abortEarly: false },
    }),
    loggerModule,
    EventEmitterModule.forRoot(),
    ScheduleModule.forRoot(),
    PrismaModule,
    ClockModule,
    FilesModule.forRoot(),
    RbacModule,
    QueuesModule,
    MetricsModule,
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
    ApprovalsModule,
    MethodologyModule,
    IdempotencyModule,
    PaymentsModule,
    MaterialsModule,
    SelfPurchasesModule,
    ToolsModule,
    // S5
    RealtimeModule,
    ChatsModule,
    DocumentsModule,
    NotificationsModule,
    ExportsModule,
    FeedbackModule,
    AdminModule,
    AdminAuditModule,
    AdminUsersModule,
    AdminProjectsModule,
    AdminOverviewModule,
    LegalModule,
    BroadcastsModule,
  ],
})
export class AppModule {}
