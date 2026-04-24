import { DocumentsService } from './documents.service';
import { FeedService } from '../feed/feed.service';
import { FilesService } from '@app/files';
import { FixedClock, InvalidInputError, PrismaService } from '@app/common';
import type { Queue } from 'bullmq';

type Doc = {
  id: string;
  projectId: string;
  stageId: string | null;
  stepId: string | null;
  category: string;
  title: string;
  fileKey: string;
  thumbKey: string | null;
  thumbStatus: string;
  mimeType: string;
  sizeBytes: number;
  uploadedById: string;
  deletedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

const mkPrisma = (documents: Doc[] = []) => {
  const docs = new Map<string, Doc>(documents.map((d) => [d.id, d]));
  let seq = docs.size;
  const prisma: any = {
    document: {
      findUnique: jest.fn(({ where }: any) => docs.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) => {
        const list = [...docs.values()].filter((d) => {
          if (where.projectId && d.projectId !== where.projectId) return false;
          if (where.deletedAt === null && d.deletedAt !== null) return false;
          if (where.stageId && d.stageId !== where.stageId) return false;
          if (where.stepId && d.stepId !== where.stepId) return false;
          if (where.category && d.category !== where.category) return false;
          return true;
        });
        return list.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
      }),
      create: jest.fn(({ data }: any) => {
        seq++;
        const d: Doc = {
          id: data.id ?? `d${seq}`,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          stepId: data.stepId ?? null,
          category: data.category,
          title: data.title,
          fileKey: data.fileKey,
          thumbKey: null,
          thumbStatus: data.thumbStatus ?? 'pending',
          mimeType: data.mimeType,
          sizeBytes: data.sizeBytes,
          uploadedById: data.uploadedById,
          deletedAt: null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        docs.set(d.id, d);
        return d;
      }),
      update: jest.fn(({ where, data }: any) => {
        const d = docs.get(where.id);
        if (!d) throw new Error('not found');
        Object.assign(d, data);
        return d;
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, docs };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;
const mkQueue = (): Queue => ({ add: jest.fn().mockResolvedValue({ id: 'j1' }) }) as any;

const mkFiles = (opts: { statOk?: boolean } = {}): FilesService => {
  return {
    createPresignedUpload: jest.fn().mockResolvedValue({
      key: 'docs/p1/d1/file.pdf',
      uploadUrl: 'http://minio/upload-url',
      expiresAt: new Date(),
    }),
    createPresignedDownload: jest.fn().mockResolvedValue({
      url: 'http://minio/download-url',
      expiresAt: new Date(),
    }),
    statObject: jest.fn(() =>
      opts.statOk === false
        ? Promise.reject(new Error('not found'))
        : Promise.resolve({ size: 10000, etag: 'etag', lastModified: new Date() }),
    ),
  } as unknown as FilesService;
};

describe('DocumentsService', () => {
  it('presignUpload — создаёт Document со статусом pending', async () => {
    const state = mkPrisma();
    const svc = new DocumentsService(
      state.prisma,
      new FixedClock(new Date()),
      mkFiles(),
      mkFeed(),
      mkQueue(),
    );

    const out = await svc.presignUpload('p1', 'u1', {
      category: 'blueprint' as any,
      title: 'Схема.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 10000,
    });

    expect(out.documentId).toBeTruthy();
    expect(out.uploadUrl).toContain('http');
    const saved = state.docs.get(out.documentId);
    expect(saved?.thumbStatus).toBe('pending');
    expect(saved?.projectId).toBe('p1');
  });

  it('confirm — PDF ставит job в thumbnail queue и эмитит document_uploaded', async () => {
    const existing: Doc = {
      id: 'd1',
      projectId: 'p1',
      stageId: null,
      stepId: null,
      category: 'blueprint',
      title: 'S.pdf',
      fileKey: 'docs/p1/d1/s.pdf',
      thumbKey: null,
      thumbStatus: 'pending',
      mimeType: 'application/pdf',
      sizeBytes: 10000,
      uploadedById: 'u1',
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const state = mkPrisma([existing]);
    const queue = mkQueue();
    const feed = mkFeed();
    const svc = new DocumentsService(
      state.prisma,
      new FixedClock(new Date()),
      mkFiles(),
      feed,
      queue,
    );

    await svc.confirm('d1', 'u1');
    expect(queue.add).toHaveBeenCalledWith(
      'generate',
      expect.objectContaining({ documentId: 'd1' }),
      expect.anything(),
    );
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'document_uploaded' }));
  });

  it('confirm — не-PDF ставит thumbStatus=skipped, queue не трогается', async () => {
    const existing: Doc = {
      id: 'd1',
      projectId: 'p1',
      stageId: null,
      stepId: null,
      category: 'photo',
      title: 'p.jpg',
      fileKey: 'docs/p1/d1/p.jpg',
      thumbKey: null,
      thumbStatus: 'pending',
      mimeType: 'image/jpeg',
      sizeBytes: 5000,
      uploadedById: 'u1',
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const state = mkPrisma([existing]);
    const queue = mkQueue();
    const svc = new DocumentsService(
      state.prisma,
      new FixedClock(new Date()),
      mkFiles(),
      mkFeed(),
      queue,
    );

    await svc.confirm('d1', 'u1');
    expect(queue.add).not.toHaveBeenCalled();
    expect(state.docs.get('d1')?.thumbStatus).toBe('skipped');
  });

  it('confirm — файла нет в MinIO → InvalidInputError', async () => {
    const existing: Doc = {
      id: 'd1',
      projectId: 'p1',
      stageId: null,
      stepId: null,
      category: 'blueprint',
      title: 'x.pdf',
      fileKey: 'missing-key',
      thumbKey: null,
      thumbStatus: 'pending',
      mimeType: 'application/pdf',
      sizeBytes: 100,
      uploadedById: 'u1',
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const state = mkPrisma([existing]);
    const svc = new DocumentsService(
      state.prisma,
      new FixedClock(new Date()),
      mkFiles({ statOk: false }),
      mkFeed(),
      mkQueue(),
    );

    await expect(svc.confirm('d1', 'u1')).rejects.toThrow(InvalidInputError);
  });

  it('list — deletedAt скрывает документ', async () => {
    const existing: Doc = {
      id: 'd1',
      projectId: 'p1',
      stageId: null,
      stepId: null,
      category: 'blueprint',
      title: 'x.pdf',
      fileKey: 'k',
      thumbKey: null,
      thumbStatus: 'done',
      mimeType: 'application/pdf',
      sizeBytes: 100,
      uploadedById: 'u1',
      deletedAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const state = mkPrisma([existing]);
    const svc = new DocumentsService(
      state.prisma,
      new FixedClock(new Date()),
      mkFiles(),
      mkFeed(),
      mkQueue(),
    );

    const list = await svc.list('p1');
    expect(list).toEqual([]);
  });

  it('softDelete — ставит deletedAt, эмитит document_deleted', async () => {
    const existing: Doc = {
      id: 'd1',
      projectId: 'p1',
      stageId: null,
      stepId: null,
      category: 'blueprint',
      title: 'x.pdf',
      fileKey: 'k',
      thumbKey: null,
      thumbStatus: 'done',
      mimeType: 'application/pdf',
      sizeBytes: 100,
      uploadedById: 'u1',
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const state = mkPrisma([existing]);
    const feed = mkFeed();
    const svc = new DocumentsService(
      state.prisma,
      new FixedClock(new Date()),
      mkFiles(),
      feed,
      mkQueue(),
    );

    await svc.softDelete('d1', 'u1');
    expect(state.docs.get('d1')?.deletedAt).not.toBeNull();
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'document_deleted' }));
  });
});
