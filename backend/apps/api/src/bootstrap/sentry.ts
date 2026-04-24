import * as Sentry from '@sentry/node';

/**
 * Инициализация Sentry для бекенда. Вызывается ДО NestFactory.create в main.ts.
 * Если SENTRY_DSN пуст — init не выполняется (dev/test).
 */
export function initSentry(env: NodeJS.ProcessEnv = process.env): boolean {
  const dsn = env.SENTRY_DSN;
  if (!dsn) return false;

  Sentry.init({
    dsn,
    environment: env.NODE_ENV ?? 'development',
    tracesSampleRate: env.NODE_ENV === 'production' ? 0.1 : 1.0,
    release: env.SENTRY_RELEASE,
    integrations: [Sentry.httpIntegration()],
  });
  return true;
}
