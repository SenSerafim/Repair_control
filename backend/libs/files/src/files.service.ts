import { Inject, Injectable, Logger } from '@nestjs/common';
import { Client as MinioClient } from 'minio';
import { nanoid } from 'nanoid';
import sharp from 'sharp';
import { InvalidInputError } from '@app/common';
import { MINIO_CLIENT, MINIO_CONFIG, MinioConfig } from './minio.client';

export interface PresignedUploadRequest {
  originalName: string;
  mimeType: string;
  sizeBytes: number;
  scope: string; // "avatars" | "stages/{stageId}/photos" | "docs/{projectId}" и т.д.
}

export interface PresignedUploadResponse {
  key: string;
  uploadUrl: string;
  expiresAt: Date;
}

@Injectable()
export class FilesService {
  private readonly logger = new Logger(FilesService.name);
  private readonly allowedMimes: Set<string>;
  private readonly maxSizeBytes: number;

  constructor(
    @Inject(MINIO_CLIENT) private readonly minio: MinioClient,
    @Inject(MINIO_CONFIG) private readonly config: MinioConfig,
    allowedMimes: string[],
    maxSizeMb: number,
  ) {
    this.allowedMimes = new Set(allowedMimes);
    this.maxSizeBytes = maxSizeMb * 1024 * 1024;
  }

  async ensureBucket(): Promise<void> {
    const exists = await this.minio.bucketExists(this.config.bucket).catch(() => false);
    if (!exists) {
      await this.minio.makeBucket(this.config.bucket, 'us-east-1');
    }
  }

  validate(req: PresignedUploadRequest): void {
    if (!this.allowedMimes.has(req.mimeType)) {
      throw new InvalidInputError('files.mime_not_allowed', `mime not allowed: ${req.mimeType}`);
    }
    if (req.sizeBytes <= 0 || req.sizeBytes > this.maxSizeBytes) {
      throw new InvalidInputError('files.size_out_of_range', `size out of range: ${req.sizeBytes}`);
    }
    if (!req.scope || req.scope.length === 0 || req.scope.length > 200) {
      throw new InvalidInputError('files.invalid_scope', 'scope is required');
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
    default:
      return '';
  }
};
