import { DynamicModule, Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FilesService } from './files.service';
import { MINIO_CLIENT, MINIO_CONFIG, MinioProvider, MinioConfig } from './minio.client';

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
            ),
          inject: [MINIO_CLIENT, MINIO_CONFIG, ConfigService],
        },
      ],
      exports: [FilesService, MINIO_CLIENT, MINIO_CONFIG],
    };
  }
}
