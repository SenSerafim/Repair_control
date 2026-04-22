import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ClockModule, PrismaModule } from '@app/common';
import { RbacModule } from '@app/rbac';
import { QUEUE_PUSH } from '../queues/queues.module';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { NotificationRouter } from './notification-router';
import { PushProcessor } from './push.processor';
import { FcmProvider, NoopProvider } from './fcm.provider';
import { NOTIFICATION_PROVIDER } from './notification-provider.interface';

@Module({
  imports: [PrismaModule, ClockModule, RbacModule, BullModule.registerQueue({ name: QUEUE_PUSH })],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationRouter,
    PushProcessor,
    FcmProvider,
    NoopProvider,
    {
      provide: NOTIFICATION_PROVIDER,
      useFactory: (fcm: FcmProvider, noop: NoopProvider) =>
        process.env.FCM_ENABLED === 'true' ? fcm : noop,
      inject: [FcmProvider, NoopProvider],
    },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
