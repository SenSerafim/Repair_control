import { Injectable, Logger } from '@nestjs/common';
import {
  NotificationProvider,
  ProviderResult,
  PushMessage,
} from './notification-provider.interface';

/**
 * Firebase Cloud Messaging провайдер.
 * Инициализируется только если FCM_ENABLED=true. Иначе сервис существует, но send() возвращает skipped.
 */
@Injectable()
export class FcmProvider implements NotificationProvider {
  private readonly logger = new Logger(FcmProvider.name);
  private messaging: any | null = null;
  private readonly enabled: boolean;

  constructor() {
    this.enabled = process.env.FCM_ENABLED === 'true';
    if (this.enabled) this.initialize();
  }

  private initialize(): void {
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const admin = require('firebase-admin');
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FCM_PROJECT_ID,
            clientEmail: process.env.FCM_CLIENT_EMAIL,
            privateKey: (process.env.FCM_PRIVATE_KEY ?? '').replace(/\\n/g, '\n'),
          }),
        });
      }
      this.messaging = admin.messaging();
    } catch (e) {
      this.logger.error(`FCM init failed: ${(e as Error).message}`);
      this.messaging = null;
    }
  }

  async send(token: string, message: PushMessage): Promise<ProviderResult> {
    if (!this.enabled || !this.messaging) {
      return { success: false, error: 'fcm_disabled' };
    }
    try {
      await this.messaging.send({
        token,
        notification: { title: message.title, body: message.body },
        data: message.data ?? {},
      });
      return { success: true };
    } catch (e: any) {
      const code: string = e?.code ?? '';
      const tokenInvalid =
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/invalid-argument';
      return { success: false, tokenInvalid, error: code || e?.message };
    }
  }
}

@Injectable()
export class NoopProvider implements NotificationProvider {
  async send(_token: string, _message: PushMessage): Promise<ProviderResult> {
    return { success: true };
  }
}
