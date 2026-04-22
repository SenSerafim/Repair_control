import { Injectable } from '@nestjs/common';
import { LegalDocument, LegalKind } from '@prisma/client';
import { Clock, ConflictError, ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

@Injectable()
export class LegalService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
  ) {}

  // ----- Public -----

  async getActive(kind: LegalKind): Promise<LegalDocument | null> {
    return this.prisma.legalDocument.findFirst({
      where: { kind, isActive: true, publishedAt: { not: null } },
      orderBy: { version: 'desc' },
    });
  }

  async listVersions(kind: LegalKind) {
    return this.prisma.legalDocument.findMany({
      where: { kind, publishedAt: { not: null } },
      orderBy: { version: 'desc' },
      select: {
        id: true,
        kind: true,
        version: true,
        title: true,
        publishedAt: true,
        isActive: true,
      },
    });
  }

  async getAcceptanceStatus(userId: string) {
    // Возвращает для каждого LegalKind: есть ли активная версия и принял ли её юзер
    const actives = await this.prisma.legalDocument.findMany({
      where: { isActive: true, publishedAt: { not: null } },
    });
    const acceptances = await this.prisma.legalAcceptance.findMany({
      where: { userId, documentId: { in: actives.map((a) => a.id) } },
    });
    const acceptedIds = new Set(acceptances.map((a) => a.documentId));
    const result: Record<string, { required: boolean; accepted: boolean; version: number | null }> =
      {};
    for (const a of actives) {
      result[a.kind] = {
        required: true,
        accepted: acceptedIds.has(a.id),
        version: a.version,
      };
    }
    return result;
  }

  async accept(userId: string, kind: LegalKind) {
    const active = await this.getActive(kind);
    if (!active) {
      throw new NotFoundError(ErrorCodes.LEGAL_DOCUMENT_NOT_FOUND, 'no active document');
    }
    await this.prisma.legalAcceptance.upsert({
      where: { userId_documentId: { userId, documentId: active.id } },
      create: { userId, documentId: active.id, acceptedAt: this.clock.now() },
      update: { acceptedAt: this.clock.now() },
    });
    return { kind, version: active.version, acceptedAt: this.clock.now() };
  }

  // ----- Admin -----

  async listAll(kind?: LegalKind) {
    return this.prisma.legalDocument.findMany({
      where: kind ? { kind } : {},
      orderBy: [{ kind: 'asc' }, { version: 'desc' }],
    });
  }

  async getById(id: string) {
    const d = await this.prisma.legalDocument.findUnique({ where: { id } });
    if (!d) throw new NotFoundError(ErrorCodes.LEGAL_DOCUMENT_NOT_FOUND, 'not found');
    return d;
  }

  async createDraft(actorId: string, input: { kind: LegalKind; title: string; bodyMd: string }) {
    // Новая версия = max(existing) + 1 для того же kind
    const last = await this.prisma.legalDocument.findFirst({
      where: { kind: input.kind },
      orderBy: { version: 'desc' },
    });
    const nextVersion = (last?.version ?? 0) + 1;
    const doc = await this.prisma.legalDocument.create({
      data: {
        kind: input.kind,
        version: nextVersion,
        title: input.title,
        bodyMd: input.bodyMd,
      },
    });
    await this.audit.log({
      actorId,
      action: 'legal.draft_created',
      targetType: 'LegalDocument',
      targetId: doc.id,
      metadata: { kind: input.kind, version: nextVersion },
    });
    return doc;
  }

  async updateDraft(id: string, actorId: string, input: { title?: string; bodyMd?: string }) {
    const d = await this.getById(id);
    if (d.publishedAt) {
      throw new ConflictError(
        ErrorCodes.LEGAL_DOCUMENT_ALREADY_PUBLISHED,
        'published document cannot be edited; create a new version',
      );
    }
    const updated = await this.prisma.legalDocument.update({
      where: { id },
      data: {
        title: input.title,
        bodyMd: input.bodyMd,
      },
    });
    await this.audit.log({
      actorId,
      action: 'legal.draft_updated',
      targetType: 'LegalDocument',
      targetId: id,
    });
    return updated;
  }

  async publish(id: string, actorId: string) {
    const d = await this.getById(id);
    if (d.publishedAt) {
      throw new ConflictError(ErrorCodes.LEGAL_DOCUMENT_ALREADY_PUBLISHED, 'already published');
    }
    const now = this.clock.now();
    // Деактивируем прошлые активные версии того же kind
    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.legalDocument.updateMany({
        where: { kind: d.kind, isActive: true },
        data: { isActive: false },
      });
      return tx.legalDocument.update({
        where: { id },
        data: { publishedAt: now, publishedById: actorId, isActive: true },
      });
    });
    await this.audit.log({
      actorId,
      action: 'legal.published',
      targetType: 'LegalDocument',
      targetId: id,
      metadata: { kind: d.kind, version: d.version },
    });
    return updated;
  }

  async renderPublic(
    kind: LegalKind,
  ): Promise<{ title: string; version: number; bodyMd: string; publishedAt: Date | null }> {
    const active = await this.getActive(kind);
    if (!active) {
      throw new NotFoundError(ErrorCodes.LEGAL_DOCUMENT_NOT_FOUND, `no published ${kind} document`);
    }
    return {
      title: active.title,
      version: active.version,
      bodyMd: active.bodyMd,
      publishedAt: active.publishedAt,
    };
  }
}
