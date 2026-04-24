import * as Joi from 'joi';

export const configValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'staging', 'production')
    .default('development'),
  PORT: Joi.number().default(3000),

  DATABASE_URL: Joi.string().required(),

  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().default(6379),
  REDIS_URL: Joi.string()
    .uri({ scheme: ['redis', 'rediss'] })
    .default('redis://localhost:6379'),

  JWT_ACCESS_SECRET: Joi.string().min(16).required(),
  JWT_REFRESH_SECRET: Joi.string().min(16).required(),
  JWT_ACCESS_TTL: Joi.number().default(900),
  JWT_REFRESH_TTL: Joi.number().default(2_592_000),

  BCRYPT_COST: Joi.number().min(4).max(15).default(12),

  SMS_PROVIDER: Joi.string().valid('stub', 'smsc', 'smsaero', 'stream').default('stub'),
  SMS_API_KEY: Joi.string().allow('').default(''),
  // Заглушка пока не подключён реальный SMS-провайдер. При SMS_PROVIDER=stub
  // любой звонок `sendRecoveryCode` будет использовать этот фиксированный код
  // вместо случайного (удобно для тестирования без SMS).
  SMS_STUB_CODE: Joi.string()
    .pattern(/^[0-9]{4,6}$/)
    .default('123456'),

  MINIO_ENDPOINT: Joi.string().default('localhost'),
  MINIO_PORT: Joi.number().default(9000),
  MINIO_USE_SSL: Joi.boolean().default(false),
  MINIO_ACCESS_KEY: Joi.string().required(),
  MINIO_SECRET_KEY: Joi.string().required(),
  MINIO_BUCKET: Joi.string().default('repair-control'),
  MINIO_PRESIGN_TTL_SECONDS: Joi.number().default(300),
  MINIO_REGION: Joi.string().default('us-east-1'),
  MINIO_PATH_STYLE: Joi.boolean().default(true),

  FILE_MAX_SIZE_MB: Joi.number().default(25),
  FILE_ALLOWED_MIMES: Joi.string().default(
    'image/jpeg,image/png,application/pdf,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),

  RATE_LIMIT_LOGIN_MAX: Joi.number().default(5),
  RATE_LIMIT_LOGIN_WINDOW_SECONDS: Joi.number().default(300),
  RATE_LIMIT_LOGIN_BLOCK_SECONDS: Joi.number().default(300),

  RECOVERY_MAX_ATTEMPTS: Joi.number().default(3),
  RECOVERY_BLOCK_SECONDS: Joi.number().default(300),

  // S5 — Observability
  SENTRY_DSN: Joi.string().uri().allow('').default(''),
  LOG_LEVEL: Joi.string()
    .valid('trace', 'debug', 'info', 'warn', 'error', 'fatal', 'silent')
    .default('info'),
  LOG_PRETTY: Joi.boolean().default(false),
  METRICS_TOKEN: Joi.string().allow('').default(''),

  // S5 — FCM push (abstracted via NotificationProvider; actual send only if FCM_ENABLED=true)
  FCM_ENABLED: Joi.boolean().default(false),
  FCM_PROJECT_ID: Joi.string().allow('').default(''),
  FCM_CLIENT_EMAIL: Joi.string().allow('').default(''),
  FCM_PRIVATE_KEY: Joi.string().allow('').default(''),

  // S5 — Export jobs (PDF/ZIP)
  EXPORT_TEMP_DIR: Joi.string().default('/tmp/repair-control-exports'),
  PDF_LOGO_URL: Joi.string().allow('').default(''),
  ZIP_MAX_SIZE_MB: Joi.number().default(500),

  // S5 — Admin / support
  SUPPORT_TELEGRAM_URL: Joi.string().default('https://t.me/repaircontrol_support'),

  // S5 — WebSocket
  WS_CORS_ORIGIN: Joi.string().default('*'),
  WS_PING_INTERVAL_MS: Joi.number().default(25_000),
  WS_PING_TIMEOUT_MS: Joi.number().default(20_000),
});
