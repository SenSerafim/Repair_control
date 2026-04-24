export interface PushMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface ProviderResult {
  success: boolean;
  tokenInvalid?: boolean;
  error?: string;
}

export interface NotificationProvider {
  /** Отправить push на конкретный device-token. */
  send(token: string, message: PushMessage): Promise<ProviderResult>;
}

export const NOTIFICATION_PROVIDER = Symbol('NOTIFICATION_PROVIDER');
