import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Client as MinioClient } from 'minio';
import { nanoid } from 'nanoid';
import sharp from 'sharp';
import { InvalidInputError } from '@app/common';
import { MINIO_CLIENT, MINIO_CONFIG, MinioConfig } from './minio.client';

export interface PresignedUploadRequest {
  /** Исходное имя файла (любое человеко-читаемое). Алиасы: filename. */
  originalName?: string;
  filename?: string;
  mimeType: string;
  sizeBytes: number;
  scope: string; // "avatars" | "stages/{stageId}/photos" | "docs/{projectId}" и т.д.
}

export interface PresignedUploadResponse {
  key: string;
  uploadUrl: string;
  expiresAt: Date;
}

/**
 * Per-scope политика — позволяет одним scope (knowledge/) разрешить video и 200 MB,
 * а остальным оставить дефолтные жёсткие лимиты. Префикс scope сравнивается прямо
 * (startsWith), prefix с самым длинным совпадением выигрывает.
 */
export interface ScopePolicy {
  prefix: string; // e.g. "knowledge/", "legal/"
  allowedMimes: string[];
  maxSizeMb: number;
}

@Injectable()
export class FilesService implements OnModuleInit {
  private readonly logger = new Logger(FilesService.name);
  private readonly defaultAllowedMimes: Set<string>;
  private readonly defaultMaxSizeBytes: number;
  private readonly scopePolicies: Array<{
    prefix: string;
    allowedMimes: Set<string>;
    maxSizeBytes: number;
  }>;

  constructor(
    @Inject(MINIO_CLIENT) private readonly minio: MinioClient,
    @Inject(MINIO_CONFIG) private readonly config: MinioConfig,
    allowedMimes: string[],
    maxSizeMb: number,
    scopePolicies: ScopePolicy[] = [],
  ) {
    this.defaultAllowedMimes = new Set(allowedMimes);
    this.defaultMaxSizeBytes = maxSizeMb * 1024 * 1024;
    // длинные префиксы первыми, чтобы "knowledge/articles/" побил "knowledge/"
    this.scopePolicies = [...scopePolicies]
      .sort((a, b) => b.prefix.length - a.prefix.length)
      .map((p) => ({
        prefix: p.prefix,
        allowedMimes: new Set(p.allowedMimes),
        maxSizeBytes: p.maxSizeMb * 1024 * 1024,
      }));
  }

  private policyForScope(scope: string): { allowedMimes: Set<string>; maxSizeBytes: number } {
    const match = this.scopePolicies.find((p) => scope.startsWith(p.prefix));
    if (match) return { allowedMimes: match.allowedMimes, maxSizeBytes: match.maxSizeBytes };
    return { allowedMimes: this.defaultAllowedMimes, maxSizeBytes: this.defaultMaxSizeBytes };
  }

  async onModuleInit(): Promise<void> {
    try {
      await this.ensureBucket();
    } catch (e) {
      this.logger.warn(`ensureBucket failed at startup: ${(e as Error).message}`);
    }
  }

  async ensureBucket(): Promise<void> {
    const exists = await this.minio.bucketExists(this.config.bucket).catch(() => false);
    if (!exists) {
      await this.minio.makeBucket(this.config.bucket, 'us-east-1');
    }
  }

  validate(req: PresignedUploadRequest): void {
    if (!req.scope || req.scope.length === 0 || req.scope.length > 200) {
      throw new InvalidInputError('files.invalid_scope', 'scope is required');
    }
    const policy = this.policyForScope(req.scope);
    if (!policy.allowedMimes.has(req.mimeType)) {
      throw new InvalidInputError('files.mime_not_allowed', `mime not allowed: ${req.mimeType}`);
    }
    if (req.sizeBytes <= 0 || req.sizeBytes > policy.maxSizeBytes) {
      throw new InvalidInputError('files.size_out_of_range', `size out of range: ${req.sizeBytes}`);
    }
  }

  buildKey(req: PresignedUploadRequest): string {
    const ext = extensionFromMime(req.mimeType);
    const safeScope = req.scope.replace(/[^a-zA-Z0-9_\-\/]/g, '_');
    return `${safeScope}/${nanoid()}${ext}`;
  }

  async createPresignedUpload(req: PresignedUploadRequest): Promise<PresignedUploadResponse> {
    this.validate(req);
    const key = this.buildKey(req);
    const url = await this.minio.presignedPutObject(
      this.config.bucket,
      key,
      this.config.presignTtlSeconds,
    );
    return {
      key,
      uploadUrl: url,
      expiresAt: new Date(Date.now() + this.config.presignTtlSeconds * 1000),
    };
  }

  async createPresignedDownload(key: string): Promise<{ url: string; expiresAt: Date }> {
    const url = await this.minio.presignedGetObject(
      this.config.bucket,
      key,
      this.config.presignTtlSeconds,
    );
    return { url, expiresAt: new Date(Date.now() + this.config.presignTtlSeconds * 1000) };
  }

  async generateThumbnail(input: Buffer, width = 320): Promise<Buffer> {
    return sharp(input)
      .rotate()
      .resize({ width, withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toBuffer();
  }

  /**
   * Проверка существования файла. Используется в documents.confirm (после клиентского upload).
   */
  async statObject(key: string): Promise<{ size: number; etag: string; lastModified: Date }> {
    const info = await this.minio.statObject(this.config.bucket, key);
    return { size: info.size, etag: info.etag, lastModified: info.lastModified };
  }

  async getObjectBuffer(key: string): Promise<Buffer> {
    const stream = await this.minio.getObject(this.config.bucket, key);
    const chunks: Buffer[] = [];
    return new Promise((resolve, reject) => {
      stream.on('data', (c: Buffer) => chunks.push(c));
      stream.on('end', () => resolve(Buffer.concat(chunks)));
      stream.on('error', reject);
    });
  }

  /** Возвращает Readable stream объекта — для proxy-стрима в HTTP-response без буферизации. */
  async streamObject(key: string): Promise<NodeJS.ReadableStream> {
    return this.minio.getObject(this.config.bucket, key);
  }

  async putObject(key: string, buffer: Buffer, mimeType: string): Promise<void> {
    await this.minio.putObject(this.config.bucket, key, buffer, buffer.length, {
      'Content-Type': mimeType,
    });
  }

  async removeObject(key: string): Promise<void> {
    try {
      await this.minio.removeObject(this.config.bucket, key);
    } catch (e) {
      this.logger.warn(`removeObject failed for ${key}: ${(e as Error).message}`);
    }
  }
}

const extensionFromMime = (mime: string): string => {
  switch (mime) {
    case 'image/jpeg':
      return '.jpg';
    case 'image/png':
      return '.png';
    case 'application/pdf':
      return '.pdf';
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return '.xlsx';
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return '.docx';
    case 'video/mp4':
      return '.mp4';
    case 'video/quicktime':
      return '.mov';
    default:
      return '';
  }
};
