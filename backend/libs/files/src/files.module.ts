import { DynamicModule, Global, Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FilesService, ScopePolicy } from './files.service';
import { MINIO_CLIENT, MINIO_CONFIG, MinioProvider, MinioConfig } from './minio.client';

const DEFAULT_SCOPE_POLICIES: ScopePolicy[] = [
  {
    prefix: 'knowledge/',
    allowedMimes: ['image/jpeg', 'image/png', 'video/mp4', 'video/quicktime', 'application/pdf'],
    maxSizeMb: 200,
  },
  {
    prefix: 'legal/',
    allowedMimes: ['application/pdf'],
    maxSizeMb: 25,
  },
];

function parseScopePolicies(raw: string | undefined): ScopePolicy[] {
  if (!raw || raw.trim().length === 0) return DEFAULT_SCOPE_POLICIES;
  try {
    const parsed = JSON.parse(raw) as Record<string, { max?: number; mimes?: string[] }>;
    return Object.entries(parsed).map(([prefix, val]) => ({
      prefix,
      allowedMimes: Array.isArray(val.mimes) ? val.mimes : [],
      maxSizeMb: typeof val.max === 'number' ? val.max : 25,
    }));
  } catch (e) {
    new Logger('FilesModule').warn(
      `FILE_SCOPE_POLICIES_JSON parse failed, falling back to defaults: ${(e as Error).message}`,
    );
    return DEFAULT_SCOPE_POLICIES;
  }
}

@Global()
@Module({})
export class FilesModule {
  static forRoot(): DynamicModule {
    return {
      global: true,
      module: FilesModule,
      providers: [
        {
          provide: MINIO_CONFIG,
          useFactory: (cfg: ConfigService): MinioConfig => ({
            endPoint: cfg.get<string>('MINIO_ENDPOINT', 'localhost'),
            port: cfg.get<number>('MINIO_PORT', 9000),
            useSSL: cfg.get<boolean>('MINIO_USE_SSL', false),
            accessKey: cfg.get<string>('MINIO_ACCESS_KEY', 'minioadmin'),
            secretKey: cfg.get<string>('MINIO_SECRET_KEY', 'minioadmin'),
            bucket: cfg.get<string>('MINIO_BUCKET', 'repair-control'),
            presignTtlSeconds: cfg.get<number>('MINIO_PRESIGN_TTL_SECONDS', 300),
            region: cfg.get<string>('MINIO_REGION', 'us-east-1'),
            pathStyle: cfg.get<boolean>('MINIO_PATH_STYLE', true),
          }),
          inject: [ConfigService],
        },
        {
          provide: MINIO_CLIENT,
          useFactory: (config: MinioConfig) => MinioProvider.createClient(config),
          inject: [MINIO_CONFIG],
        },
        {
          provide: FilesService,
          useFactory: (client: any, config: MinioConfig, cfg: ConfigService) =>
            new FilesService(
              client,
              config,
              cfg
                .get<string>('FILE_ALLOWED_MIMES', '')
                .split(',')
                .map((m) => m.trim())
                .filter(Boolean),
              cfg.get<number>('FILE_MAX_SIZE_MB', 25),
              parseScopePolicies(cfg.get<string>('FILE_SCOPE_POLICIES_JSON')),
            ),
          inject: [MINIO_CLIENT, MINIO_CONFIG, ConfigService],
        },
      ],
      exports: [FilesService, MINIO_CLIENT, MINIO_CONFIG],
    };
  }
}
