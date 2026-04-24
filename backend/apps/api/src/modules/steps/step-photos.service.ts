import { Inject, Injectable } from '@nestjs/common';
import { Client as MinioClient } from 'minio';
import sharp from 'sharp';
import {
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FilesService, MINIO_CLIENT, MINIO_CONFIG, MinioConfig } from '@app/files';
import { FeedService } from '../feed/feed.service';

const ALLOWED_PHOTO_MIMES = new Set(['image/jpeg', 'image/png']);
const MAX_PHOTO_BYTES = 25 * 1024 * 1024;

@Injectable()
export class StepPhotosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly files: FilesService,
    private readonly feed: FeedService,
    @Inject(MINIO_CLIENT) private readonly minio: MinioClient,
    @Inject(MINIO_CONFIG) private readonly config: MinioConfig,
  ) {}

  async presign(
    stepId: string,
    mime: string,
    size: number,
    originalName?: string,
    _actorUserId?: string,
  ) {
    if (!ALLOWED_PHOTO_MIMES.has(mime)) {
      throw new InvalidInputError(ErrorCodes.PHOTO_INVALID_MIME, `mime not allowed: ${mime}`);
    }
    if (size <= 0 || size > MAX_PHOTO_BYTES) {
      throw new InvalidInputError(ErrorCodes.PHOTO_TOO_LARGE, `size out of range: ${size}`);
    }
    const step = await this.prisma.step.findUnique({ where: { id: stepId }, select: { id: true } });
    if (!step) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');

    return this.files.createPresignedUpload({
      originalName: originalName ?? `photo-${stepId}`,
      mimeType: mime,
      sizeBytes: size,
      scope: `steps/${stepId}/photos`,
    });
  }

  async confirm(
    stepId: string,
    input: { fileKey: string; mimeType: string; sizeBytes: number },
    actorUserId: string,
  ) {
    if (!ALLOWED_PHOTO_MIMES.has(input.mimeType)) {
      throw new InvalidInputError(ErrorCodes.PHOTO_INVALID_MIME, 'mime not allowed');
    }
    const step = await this.prisma.step.findUnique({
      where: { id: stepId },
      select: { id: true, stageId: true, stage: { select: { projectId: true } } },
    });
    if (!step) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');

    // скачиваем объект, убиваем EXIF, перезагружаем + создаём thumbnail
    const originalBuffer = await this.downloadObject(input.fileKey);
    const sanitized = await sharp(originalBuffer).rotate().withMetadata({}).toBuffer();
    await this.putObject(input.fileKey, sanitized, input.mimeType);

    const thumbBuffer = await this.files.generateThumbnail(sanitized);
    const thumbKey = this.deriveThumbKey(input.fileKey);
    await this.putObject(thumbKey, thumbBuffer, 'image/jpeg');

    const photo = await this.prisma.$transaction(async (tx) => {
      const p = await tx.stepPhoto.create({
        data: {
          stepId: step.id,
          fileKey: input.fileKey,
          thumbKey,
          mimeType: input.mimeType,
          sizeBytes: sanitized.byteLength,
          uploadedBy: actorUserId,
          exifCleared: true,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'photo_attached',
        projectId: step.stage.projectId,
        actorId: actorUserId,
        payload: { stepId: step.id, photoId: p.id },
      });
      return p;
    });
    return photo;
  }

  async listForStep(stepId: string) {
    const photos = await this.prisma.stepPhoto.findMany({
      where: { stepId },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(
      photos.map(async (p) => ({
        ...p,
        downloadUrl: (await this.files.createPresignedDownload(p.fileKey)).url,
        thumbUrl: p.thumbKey ? (await this.files.createPresignedDownload(p.thumbKey)).url : null,
      })),
    );
  }

  async delete(photoId: string, actorUserId: string) {
    const photo = await this.prisma.stepPhoto.findUnique({
      where: { id: photoId },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!photo) throw new NotFoundError(ErrorCodes.PHOTO_NOT_FOUND, 'photo not found');
    if (photo.uploadedBy !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.PHOTO_NOT_FOUND, 'only uploader can delete');
    }

    await this.removeObjectSafely(photo.fileKey);
    if (photo.thumbKey) await this.removeObjectSafely(photo.thumbKey);

    await this.prisma.$transaction(async (tx) => {
      await tx.stepPhoto.delete({ where: { id: photoId } });
      await this.feed.emit({
        tx,
        kind: 'photo_deleted',
        projectId: photo.step.stage.projectId,
        actorId: actorUserId,
        payload: { photoId, stepId: photo.stepId },
      });
    });
  }

  private async downloadObject(key: string): Promise<Buffer> {
    const stream = await this.minio.getObject(this.config.bucket, key);
    const chunks: Buffer[] = [];
    return new Promise((resolve, reject) => {
      stream.on('data', (chunk: Buffer) => chunks.push(chunk));
      stream.on('end', () => resolve(Buffer.concat(chunks)));
      stream.on('error', (err: Error) => reject(err));
    });
  }

  private async putObject(key: string, buffer: Buffer, mime: string): Promise<void> {
    await this.minio.putObject(this.config.bucket, key, buffer, buffer.byteLength, {
      'Content-Type': mime,
    });
  }

  private async removeObjectSafely(key: string): Promise<void> {
    try {
      await this.minio.removeObject(this.config.bucket, key);
    } catch {
      // no-op: объект может уже отсутствовать
    }
  }

  private deriveThumbKey(key: string): string {
    const dot = key.lastIndexOf('.');
    const base = dot >= 0 ? key.slice(0, dot) : key;
    return `${base}.thumb.jpg`;
  }
}
