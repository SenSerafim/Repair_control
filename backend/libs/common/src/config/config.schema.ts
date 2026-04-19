import * as Joi from 'joi';

export const configValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'staging', 'production')
    .default('development'),
  PORT: Joi.number().default(3000),

  DATABASE_URL: Joi.string().required(),

  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().default(6379),

  JWT_ACCESS_SECRET: Joi.string().min(16).required(),
  JWT_REFRESH_SECRET: Joi.string().min(16).required(),
  JWT_ACCESS_TTL: Joi.number().default(900),
  JWT_REFRESH_TTL: Joi.number().default(2_592_000),

  BCRYPT_COST: Joi.number().min(4).max(15).default(12),

  SMS_PROVIDER: Joi.string().valid('stub', 'smsc', 'smsaero', 'stream').default('stub'),
  SMS_API_KEY: Joi.string().allow('').default(''),

  MINIO_ENDPOINT: Joi.string().default('localhost'),
  MINIO_PORT: Joi.number().default(9000),
  MINIO_USE_SSL: Joi.boolean().default(false),
  MINIO_ACCESS_KEY: Joi.string().required(),
  MINIO_SECRET_KEY: Joi.string().required(),
  MINIO_BUCKET: Joi.string().default('repair-control'),
  MINIO_PRESIGN_TTL_SECONDS: Joi.number().default(300),

  FILE_MAX_SIZE_MB: Joi.number().default(25),
  FILE_ALLOWED_MIMES: Joi.string().default(
    'image/jpeg,image/png,application/pdf,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),

  RATE_LIMIT_LOGIN_MAX: Joi.number().default(5),
  RATE_LIMIT_LOGIN_WINDOW_SECONDS: Joi.number().default(300),
  RATE_LIMIT_LOGIN_BLOCK_SECONDS: Joi.number().default(300),

  RECOVERY_MAX_ATTEMPTS: Joi.number().default(3),
  RECOVERY_BLOCK_SECONDS: Joi.number().default(300),
});
