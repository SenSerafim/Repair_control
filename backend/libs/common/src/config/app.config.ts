export interface AppConfig {
  nodeEnv: 'development' | 'test' | 'staging' | 'production';
  port: number;
  jwt: {
    accessSecret: string;
    refreshSecret: string;
    accessTtl: number;
    refreshTtl: number;
  };
  bcrypt: { cost: number };
  recovery: { maxAttempts: number; blockSeconds: number };
  loginRateLimit: { max: number; windowSeconds: number; blockSeconds: number };
  files: {
    maxSizeMb: number;
    allowedMimes: string[];
  };
  minio: {
    endpoint: string;
    port: number;
    useSSL: boolean;
    accessKey: string;
    secretKey: string;
    bucket: string;
    presignTtlSeconds: number;
  };
}

export const appConfigFactory = (env: Record<string, string | undefined>): AppConfig => ({
  nodeEnv: (env.NODE_ENV as AppConfig['nodeEnv']) ?? 'development',
  port: Number(env.PORT ?? 3000),
  jwt: {
    accessSecret: env.JWT_ACCESS_SECRET ?? 'dev_access_secret_change_me_min16',
    refreshSecret: env.JWT_REFRESH_SECRET ?? 'dev_refresh_secret_change_me_min16',
    accessTtl: Number(env.JWT_ACCESS_TTL ?? 900),
    refreshTtl: Number(env.JWT_REFRESH_TTL ?? 2_592_000),
  },
  bcrypt: { cost: Number(env.BCRYPT_COST ?? 12) },
  recovery: {
    maxAttempts: Number(env.RECOVERY_MAX_ATTEMPTS ?? 3),
    blockSeconds: Number(env.RECOVERY_BLOCK_SECONDS ?? 300),
  },
  loginRateLimit: {
    max: Number(env.RATE_LIMIT_LOGIN_MAX ?? 5),
    windowSeconds: Number(env.RATE_LIMIT_LOGIN_WINDOW_SECONDS ?? 300),
    blockSeconds: Number(env.RATE_LIMIT_LOGIN_BLOCK_SECONDS ?? 300),
  },
  files: {
    maxSizeMb: Number(env.FILE_MAX_SIZE_MB ?? 25),
    allowedMimes: (env.FILE_ALLOWED_MIMES ?? '')
      .split(',')
      .map((m) => m.trim())
      .filter(Boolean),
  },
  minio: {
    endpoint: env.MINIO_ENDPOINT ?? 'localhost',
    port: Number(env.MINIO_PORT ?? 9000),
    useSSL: env.MINIO_USE_SSL === 'true',
    accessKey: env.MINIO_ACCESS_KEY ?? 'minioadmin',
    secretKey: env.MINIO_SECRET_KEY ?? 'minioadmin',
    bucket: env.MINIO_BUCKET ?? 'repair-control',
    presignTtlSeconds: Number(env.MINIO_PRESIGN_TTL_SECONDS ?? 300),
  },
});
