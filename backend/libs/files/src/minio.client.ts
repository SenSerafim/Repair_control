import { Client as MinioClient } from 'minio';
import { Injectable } from '@nestjs/common';

export interface MinioConfig {
  endPoint: string;
  port: number;
  useSSL: boolean;
  accessKey: string;
  secretKey: string;
  bucket: string;
  presignTtlSeconds: number;
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
    });
  }
}
