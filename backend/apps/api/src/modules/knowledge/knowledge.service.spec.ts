import { KnowledgeService } from './knowledge.service';
import { FixedClock, InvalidInputError, NotFoundError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';
import { FilesService } from '@app/files';

const mkFiles = (): jest.Mocked<FilesService> => {
  return {
    statObject: jest.fn().mockImplementation(async (key: string) => ({
      size: key.includes('250mb') ? 250 * 1024 * 1024 : 1024,
      etag: 'minio-etag',
      lastModified: new Date(),
    })),
    createPresignedDownload: jest.fn().mockResolvedValue({
      url: 'https://presigned',
      expiresAt: new Date(Date.now() + 60_000),
    }),
  } as unknown as jest.Mocked<FilesService>;
};

const mkPrisma = () => {
  const cats: any[] = [];
  const articles: any[] = [];
  const assets: any[] = [];
  const audit: any[] = [];

  let nextCatId = 1;
  let nextArtId = 1;
  let nextAssetId = 1;

  const prisma: any = {
    knowledgeCategory: {
      findUnique: jest.fn(({ where }: any) => cats.find((c) => c.id === where.id) ?? null),
      findMany: jest.fn(({ orderBy, include }: any) => {
        const out = [...cats];
        const ord = Array.isArray(orderBy) ? orderBy[0] : orderBy;
        const key = ord && Object.keys(ord)[0];
        if (key) out.sort((a, b) => (a[key] ?? 0) - (b[key] ?? 0));
        if (include?._count) {
          return out.map((c) => ({
            ...c,
            _count: { articles: articles.filter((a) => a.categoryId === c.id).length },
          }));
        }
        return out;
      }),
      create: jest.fn(({ data }: any) => {
        const c = {
          id: `cat-${nextCatId++}`,
          ...data,
          isPublished: data.isPublished ?? true,
          orderIndex: data.orderIndex ?? 0,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        cats.push(c);
        return c;
      }),
      update: jest.fn(({ where, data }: any) => {
        const c = cats.find((x) => x.id === where.id);
        Object.assign(c, data, { updatedAt: new Date() });
        return c;
      }),
      delete: jest.fn(({ where }: any) => {
        const idx = cats.findIndex((x) => x.id === where.id);
        const removed = cats[idx];
        cats.splice(idx, 1);
        return removed;
      }),
    },
    knowledgeArticle: {
      findUnique: jest.fn(({ where, include }: any) => {
        const a = articles.find((x) => x.id === where.id);
        if (!a) return null;
        if (include?.assets) {
          const list = assets
            .filter((s) => s.articleId === a.id)
            .sort((x, y) => x.orderIndex - y.orderIndex);
          return { ...a, assets: list };
        }
        return a;
      }),
      create: jest.fn(({ data }: any) => {
        const art = {
          id: `art-${nextArtId++}`,
          ...data,
          version: data.version ?? 1,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        articles.push(art);
        return art;
      }),
      update: jest.fn(({ where, data }: any) => {
        const art = articles.find((x) => x.id === where.id);
        Object.assign(art, data, { updatedAt: new Date() });
        return art;
      }),
      delete: jest.fn(({ where }: any) => {
        const idx = articles.findIndex((x) => x.id === where.id);
        articles.splice(idx, 1);
      }),
    },
    knowledgeAsset: {
      findFirst: jest.fn(
        ({ where }: any) =>
          assets.find((s) => s.id === where.id && s.articleId === where.articleId) ?? null,
      ),
      create: jest.fn(({ data }: any) => {
        const s = { id: `asset-${nextAssetId++}`, ...data, createdAt: new Date() };
        assets.push(s);
        return s;
      }),
      update: jest.fn(({ where, data }: any) => {
        const s = assets.find((x) => x.id === where.id);
        Object.assign(s, data);
        return s;
      }),
      delete: jest.fn(({ where }: any) => {
        const idx = assets.findIndex((x) => x.id === where.id);
        assets.splice(idx, 1);
      }),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: any) => {
        audit.push(data);
        return data;
      }),
    },
  };
  return {
    prisma: prisma as unknown as PrismaService,
    state: { cats, articles, assets, audit },
  };
};

describe('KnowledgeService — categories', () => {
  it('createCategory: scope=project_module без moduleSlug → InvalidInputError', async () => {
    const { prisma } = mkPrisma();
    const svc = new KnowledgeService(
      prisma,
      new FixedClock(new Date()),
      new AdminAuditService(prisma, new FixedClock(new Date())),
      mkFiles(),
    );
    await expect(
      svc.createCategory('admin', {
        title: 'Stages help',
        scope: 'project_module' as any,
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('createCategory: scope=global сохраняет moduleSlug=null', async () => {
    const { prisma } = mkPrisma();
    const svc = new KnowledgeService(
      prisma,
      new FixedClock(new Date()),
      new AdminAuditService(prisma, new FixedClock(new Date())),
      mkFiles(),
    );
    const cat = await svc.createCategory('admin', {
      title: 'Общие материалы',
      scope: 'global' as any,
      moduleSlug: 'stages',
    });
    expect(cat.scope).toBe('global');
    expect(cat.moduleSlug).toBeNull();
  });

  it('createCategory: scope=project_module + moduleSlug=stages → ok', async () => {
    const { prisma } = mkPrisma();
    const svc = new KnowledgeService(
      prisma,
      new FixedClock(new Date()),
      new AdminAuditService(prisma, new FixedClock(new Date())),
      mkFiles(),
    );
    const cat = await svc.createCategory('admin', {
      title: 'Stages help',
      scope: 'project_module' as any,
      moduleSlug: 'stages',
    });
    expect(cat.moduleSlug).toBe('stages');
  });
});

describe('KnowledgeService — article ETag', () => {
  const setup = async () => {
    const { prisma, state } = mkPrisma();
    const files = mkFiles();
    const svc = new KnowledgeService(
      prisma,
      new FixedClock(new Date()),
      new AdminAuditService(prisma, new FixedClock(new Date())),
      files,
    );
    const cat = await svc.createCategory('admin', {
      title: 'Подготовка',
      scope: 'global' as any,
    });
    const art = await svc.createArticle('admin', {
      categoryId: cat.id,
      title: 'Грунтовка стен',
      body: 'Перед нанесением шпаклёвки нанесите грунт.',
    });
    return { prisma, svc, files, art, state };
  };

  it('etag меняется при изменении body', async () => {
    const { svc, art } = await setup();
    const firstEtag = art.etag;
    const firstVersion = art.version;
    const updated = await svc.updateArticle(art.id, 'admin', {
      body: 'Перед нанесением шпаклёвки нанесите два слоя грунта.',
    });
    expect(updated.etag).not.toBe(firstEtag);
    expect(updated.version).toBe(firstVersion + 1);
  });

  it('etag меняется при добавлении asset', async () => {
    const { svc, art } = await setup();
    const firstEtag = art.etag;
    await svc.confirmAsset(art.id, 'admin', {
      kind: 'image' as any,
      fileKey: 'knowledge/articles/abc/photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1024,
    });
    const after = await svc.getArticle(art.id);
    expect(after.etag).not.toBe(firstEtag);
  });

  it('confirmAsset: размер не совпадает с MinIO → InvalidInputError', async () => {
    const { svc, art } = await setup();
    await expect(
      svc.confirmAsset(art.id, 'admin', {
        kind: 'image' as any,
        fileKey: 'knowledge/articles/abc/photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 9999, // в mock'е stat возвращает 1024
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('getArticle: unpublished → NotFoundError', async () => {
    const { svc, art } = await setup();
    await svc.updateArticle(art.id, 'admin', { isPublished: false });
    await expect(svc.getArticle(art.id)).rejects.toThrow(NotFoundError);
  });
});
