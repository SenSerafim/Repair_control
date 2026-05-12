import { DocumentsCleanupCron } from './documents-cleanup.cron';
import { FixedClock, PrismaService } from '@app/common';
import { FilesService } from '@app/files';

type Doc = {
  id: string;
  fileKey: string;
  thumbStatus: string;
  deletedAt: Date | null;
  createdAt: Date;
};

const buildPrisma = (docs: Doc[]) => {
  const map = new Map(docs.map((d) => [d.id, { ...d }]));
  return {
    document: {
      findMany: jest.fn(({ where, take }: any) => {
        const cutoff = where.createdAt?.lt as Date | undefined;
        const list = [...map.values()].filter((d) => {
          if (where.thumbStatus && d.thumbStatus !== where.thumbStatus) return false;
          if (where.deletedAt === null && d.deletedAt !== null) return false;
          if (cutoff && d.createdAt.getTime() >= cutoff.getTime()) return false;
          return true;
        });
        return list.slice(0, take ?? list.length);
      }),
      update: jest.fn(({ where, data }: any) => {
        const d = map.get(where.id);
        if (d) Object.assign(d, data);
        return d;
      }),
    },
    _internal: map,
  } as unknown as PrismaService & { _internal: Map<string, Doc> };
};

const buildFiles = (existingKeys: Set<string>) =>
  ({
    statObject: jest.fn(async (key: string) => {
      if (!existingKeys.has(key)) throw new Error('NoSuchKey');
      return { size: 1, etag: 'x', lastModified: new Date() };
    }),
  }) as unknown as FilesService;

describe('DocumentsCleanupCron', () => {
  const now = new Date('2026-05-12T12:00:00.000Z');
  const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);
  const tenMinutesAgo = new Date(now.getTime() - 10 * 60 * 1000);

  it('soft-deletes pending documents older than 1h without S3 object', async () => {
    const prisma = buildPrisma([
      {
        id: 'orphan',
        fileKey: 'k1',
        thumbStatus: 'pending',
        deletedAt: null,
        createdAt: twoHoursAgo,
      },
      {
        id: 'has-file',
        fileKey: 'k2',
        thumbStatus: 'pending',
        deletedAt: null,
        createdAt: twoHoursAgo,
      },
    ]);
    const files = buildFiles(new Set(['k2']));
    const cron = new DocumentsCleanupCron(prisma, files, new FixedClock(now));

    const res = await cron.runOnce();

    expect(res).toEqual({ scanned: 2, orphaned: 1 });
    expect(prisma._internal.get('orphan')!.deletedAt).toEqual(now);
    expect(prisma._internal.get('has-file')!.deletedAt).toBeNull();
  });

  it('skips documents younger than the 1h threshold', async () => {
    const prisma = buildPrisma([
      {
        id: 'fresh',
        fileKey: 'k1',
        thumbStatus: 'pending',
        deletedAt: null,
        createdAt: tenMinutesAgo,
      },
    ]);
    const files = buildFiles(new Set());
    const cron = new DocumentsCleanupCron(prisma, files, new FixedClock(now));

    const res = await cron.runOnce();

    expect(res).toEqual({ scanned: 0, orphaned: 0 });
    expect(files.statObject).not.toHaveBeenCalled();
  });

  it('skips already deleted documents', async () => {
    const prisma = buildPrisma([
      { id: 'gone', fileKey: 'k1', thumbStatus: 'pending', deletedAt: now, createdAt: twoHoursAgo },
    ]);
    const files = buildFiles(new Set());
    const cron = new DocumentsCleanupCron(prisma, files, new FixedClock(now));

    const res = await cron.runOnce();

    expect(res).toEqual({ scanned: 0, orphaned: 0 });
  });

  it('leaves documents with thumbStatus other than pending alone', async () => {
    const prisma = buildPrisma([
      { id: 'done', fileKey: 'k1', thumbStatus: 'done', deletedAt: null, createdAt: twoHoursAgo },
      {
        id: 'skipped',
        fileKey: 'k2',
        thumbStatus: 'skipped',
        deletedAt: null,
        createdAt: twoHoursAgo,
      },
    ]);
    const files = buildFiles(new Set());
    const cron = new DocumentsCleanupCron(prisma, files, new FixedClock(now));

    const res = await cron.runOnce();

    expect(res).toEqual({ scanned: 0, orphaned: 0 });
  });
});
