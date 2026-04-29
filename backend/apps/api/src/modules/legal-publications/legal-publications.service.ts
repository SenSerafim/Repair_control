import { createHash } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { LegalPublication, LegalPublicationKind } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FilesService } from '@app/files';
import { AdminAuditService } from '../admin-audit/admin-audit.service';
import { CreateLegalPublicationDto, UpdateLegalPublicationDto } from './dto';

@Injectable()
export class LegalPublicationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
    private readonly files: FilesService,
  ) {}

  // ---------- Public ----------

  /** Список активных публикаций — для mobile listing. */
  async listActive() {
    return this.prisma.legalPublication.findMany({
      where: { isActive: true, publishedAt: { not: null } },
      orderBy: [{ kind: 'asc' }, { version: 'desc' }],
      select: {
        id: true,
        kind: true,
        slug: true,
        title: true,
        version: true,
        sizeBytes: true,
        publishedAt: true,
      },
    });
  }

  /** Активная публикация по slug — для public stream endpoint. */
  async getActiveBySlug(slug: string): Promise<LegalPublication> {
    const pub = await this.prisma.legalPublication.findFirst({
      where: { slug, isActive: true, publishedAt: { not: null } },
    });
    if (!pub) {
      throw new NotFoundError(
        ErrorCodes.LEGAL_PUBLICATION_NOT_FOUND,
        `no active legal publication: ${slug}`,
      );
    }
    return pub;
  }

  // ---------- Admin ----------

  async listAll(kind?: LegalPublicationKind) {
    return this.prisma.legalPublication.findMany({
      where: kind ? { kind } : {},
      orderBy: [{ kind: 'asc' }, { version: 'desc' }],
    });
  }

  async getById(id: string): Promise<LegalPublication> {
    const pub = await this.prisma.legalPublication.findUnique({ where: { id } });
    if (!pub) throw new NotFoundError(ErrorCodes.LEGAL_PUBLICATION_NOT_FOUND, 'not found');
    return pub;
  }

  async create(actorId: string, dto: CreateLegalPublicationDto): Promise<LegalPublication> {
    // Файл должен быть в MinIO (presigned upload завершён клиентом).
    await this.requireFileExists(dto.fileKey, dto.sizeBytes);

    const existingSlug = await this.prisma.legalPublication.findUnique({
      where: { slug: dto.slug },
    });
    if (existingSlug) {
      throw new ConflictError(
        ErrorCodes.LEGAL_PUBLICATION_SLUG_TAKEN,
        `slug already used: ${dto.slug}`,
      );
    }
    const last = await this.prisma.legalPublication.findFirst({
      where: { kind: dto.kind },
      orderBy: { version: 'desc' },
    });
    const nextVersion = (last?.version ?? 0) + 1;

    const etag = await this.computeFileEtag(dto.fileKey);

    const created = await this.prisma.legalPublication.create({
      data: {
        kind: dto.kind,
        slug: dto.slug,
        title: dto.title,
        fileKey: dto.fileKey,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
        etag,
        version: nextVersion,
      },
    });
    await this.audit.log({
      actorId,
      action: 'legal_publication.created',
      targetType: 'LegalPublication',
      targetId: created.id,
      metadata: { kind: dto.kind, slug: dto.slug, version: nextVersion },
    });
    return created;
  }

  async update(
    id: string,
    actorId: string,
    dto: UpdateLegalPublicationDto,
  ): Promise<LegalPublication> {
    const pub = await this.getById(id);
    const data: Parameters<PrismaService['legalPublication']['update']>[0]['data'] = {};

    if (dto.title !== undefined) data.title = dto.title;

    if (dto.fileKey !== undefined) {
      if (!dto.mimeType || !dto.sizeBytes) {
        throw new InvalidInputError(
          'legal_publications.invalid_file_meta',
          'mimeType and sizeBytes are required when replacing file',
        );
      }
      await this.requireFileExists(dto.fileKey, dto.sizeBytes);
      data.fileKey = dto.fileKey;
      data.mimeType = dto.mimeType;
      data.sizeBytes = dto.sizeBytes;
      data.etag = await this.computeFileEtag(dto.fileKey);
      data.version = pub.version + 1;
      // Замена файла = новый контент → нужно повторно опубликовать
      data.isActive = false;
      data.publishedAt = null;
      data.publishedById = null;
    }

    const updated = await this.prisma.legalPublication.update({ where: { id }, data });
    await this.audit.log({
      actorId,
      action: 'legal_publication.updated',
      targetType: 'LegalPublication',
      targetId: id,
      metadata: { fileReplaced: dto.fileKey !== undefined },
    });
    return updated;
  }

  /** Активирует публикацию, деактивируя предыдущие активные того же kind. */
  async publish(id: string, actorId: string): Promise<LegalPublication> {
    const pub = await this.getById(id);
    const now = this.clock.now();
    const result = await this.prisma.$transaction(async (tx) => {
      await tx.legalPublication.updateMany({
        where: { kind: pub.kind, isActive: true, NOT: { id } },
        data: { isActive: false },
      });
      return tx.legalPublication.update({
        where: { id },
        data: { isActive: true, publishedAt: now, publishedById: actorId },
      });
    });
    await this.audit.log({
      actorId,
      action: 'legal_publication.published',
      targetType: 'LegalPublication',
      targetId: id,
      metadata: { kind: pub.kind, slug: pub.slug, version: pub.version },
    });
    return result;
  }

  /** Soft-deactivate — публикация перестаёт быть доступной по public URL. */
  async deactivate(id: string, actorId: string): Promise<LegalPublication> {
    const pub = await this.getById(id);
    if (!pub.isActive) return pub;
    const updated = await this.prisma.legalPublication.update({
      where: { id },
      data: { isActive: false },
    });
    await this.audit.log({
      actorId,
      action: 'legal_publication.deactivated',
      targetType: 'LegalPublication',
      targetId: id,
      metadata: { kind: pub.kind, slug: pub.slug },
    });
    return updated;
  }

  // ---------- Helpers ----------

  /** Проверяет что файл реально лежит в MinIO и его размер совпадает с claim'ом из DTO. */
  private async requireFileExists(fileKey: string, expectedSize: number): Promise<void> {
    let stat: { size: number };
    try {
      stat = await this.files.statObject(fileKey);
    } catch {
      throw new NotFoundError(
        ErrorCodes.LEGAL_PUBLICATION_FILE_MISSING,
        `file not found in storage: ${fileKey}`,
      );
    }
    if (stat.size !== expectedSize) {
      throw new InvalidInputError(
        'legal_publications.size_mismatch',
        `file size mismatch: stored=${stat.size}, claimed=${expectedSize}`,
      );
    }
  }

  /** SHA-256 содержимого файла → ETag для public endpoint. */
  private async computeFileEtag(fileKey: string): Promise<string> {
    const buf = await this.files.getObjectBuffer(fileKey);
    return createHash('sha256').update(buf).digest('hex');
  }
}
