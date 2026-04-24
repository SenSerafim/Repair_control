import { Client as MinioClient } from 'minio';
import { Injectable } from '@nestjs/common';

/**
 * Конфигурация S3-совместимого хранилища. По умолчанию — MinIO,
 * для продакшена используется Selectel S3 (`s3.ru-7.storage.selcloud.ru`,
 * region `ru-7`, path-style URLs).
 */
export interface MinioConfig {
  endPoint: string;
  port: number;
  useSSL: boolean;
  accessKey: string;
  secretKey: string;
  bucket: string;
  presignTtlSeconds: number;
  /** S3 region. Для Selectel — `ru-7`, для MinIO local — `us-east-1`. */
  region: string;
  /** Для Selectel и MinIO должен быть `true` (URL вида /<bucket>/<key>). */
  pathStyle: boolean;
}

export const MINIO_CONFIG = Symbol('MINIO_CONFIG');
export const MINIO_CLIENT = Symbol('MINIO_CLIENT');

@Injectable()
export class MinioProvider {
  static createClient(config: MinioConfig): MinioClient {
    return new MinioClient({
      endPoint: config.endPoint,
      port: config.port,
      useSSL: config.useSSL,
      accessKey: config.accessKey,
      secretKey: config.secretKey,
      region: config.region,
      pathStyle: config.pathStyle,
    });
  }
}
