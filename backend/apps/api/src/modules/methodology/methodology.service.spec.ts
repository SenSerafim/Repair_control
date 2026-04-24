import { MethodologyService } from './methodology.service';
import { FeedService } from '../feed/feed.service';
import { InvalidInputError, NotFoundError, PrismaService } from '@app/common';

type SectionRow = { id: string; title: string; orderIndex: number };
type ArticleRow = {
  id: string;
  sectionId: string;
  title: string;
  body: string;
  orderIndex: number;
  version: number;
  etag: string;
  createdAt: Date;
  updatedAt: Date;
  referencePhotos?: Array<{ fileKey: string }>;
};

const mkPrisma = () => {
  const sections = new Map<string, SectionRow>();
  const articles = new Map<string, ArticleRow>();
  let sSeq = 0;
  let aSeq = 0;
  const rawQueryResults: any[] = [];

  const prisma: any = {
    methodologySection: {
      create: jest.fn(({ data }: any) => {
        const s: SectionRow = { id: `sec${++sSeq}`, ...data };
        sections.set(s.id, s);
        return s;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const s = sections.get(where.id);
        if (!s) return null;
        if (include?.articles) {
          return {
            ...s,
            articles: [...articles.values()]
              .filter((a) => a.sectionId === s.id)
              .sort((x, y) => x.orderIndex - y.orderIndex),
          };
        }
        return s;
      }),
      findMany: jest.fn(() =>
        [...sections.values()]
          .sort((a, b) => a.orderIndex - b.orderIndex)
          .map((s) => ({
            ...s,
            articles: [...articles.values()]
              .filter((a) => a.sectionId === s.id)
              .map((a) => ({
                id: a.id,
                title: a.title,
                orderIndex: a.orderIndex,
                version: a.version,
                etag: a.etag,
              })),
          })),
      ),
      update: jest.fn(({ where, data }: any) => {
        const s = sections.get(where.id);
        if (!s) throw new Error('not found');
        Object.assign(s, data);
        return s;
      }),
      delete: jest.fn(({ where }: any) => {
        sections.delete(where.id);
      }),
    },
    methodologyArticle: {
      create: jest.fn(({ data }: any) => {
        const now = new Date();
        const a: ArticleRow = {
          id: `art${++aSeq}`,
          sectionId: data.sectionId,
          title: data.title,
          body: data.body,
          orderIndex: data.orderIndex,
          version: data.version ?? 1,
          etag: data.etag,
          createdAt: now,
          updatedAt: now,
        };
        articles.set(a.id, a);
        return a;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const a = articles.get(where.id);
        if (!a) return null;
        if (include?.referencePhotos) return { ...a, referencePhotos: a.referencePhotos ?? [] };
        return a;
      }),
      update: jest.fn(({ where, data }: any) => {
        const a = articles.get(where.id);
        if (!a) throw new Error('not found');
        const updates = { ...data };
        for (const [k, v] of Object.entries(updates)) {
          if (v !== undefined) (a as any)[k] = v;
        }
        a.updatedAt = new Date();
        return a;
      }),
      delete: jest.fn(({ where }: any) => {
        articles.delete(where.id);
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
    $queryRaw: jest.fn(async () => rawQueryResults),
  };
  return {
    prisma: prisma as unknown as PrismaService,
    sections,
    articles,
    rawQueryResults,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('MethodologyService — sections CRUD', () => {
  it('createSection + emit methodology_section_created', async () => {
    const st = mkPrisma();
    const feed = mkFeed();
    const svc = new MethodologyService(st.prisma, feed);
    const s = await svc.createSection({ title: 'Электрика', orderIndex: 0, actorUserId: 'admin' });
    expect(s.title).toBe('Электрика');
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'methodology_section_created' }),
    );
  });

  it('getSection 404', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    await expect(svc.getSection('missing')).rejects.toThrow(NotFoundError);
  });

  it('deleteSection + emit', async () => {
    const st = mkPrisma();
    const feed = mkFeed();
    const svc = new MethodologyService(st.prisma, feed);
    const s = await svc.createSection({ title: 'A', orderIndex: 0, actorUserId: 'admin' });
    await svc.deleteSection(s.id, 'admin');
    expect(st.sections.size).toBe(0);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('methodology_section_deleted');
  });
});

describe('MethodologyService — article ETag', () => {
  it('createArticle вычисляет etag (sha256 от title+body+refs)', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    const s = await svc.createSection({ title: 'A', orderIndex: 0, actorUserId: 'admin' });
    const a = await svc.createArticle({
      sectionId: s.id,
      title: 'Штукатурка',
      body: 'Нанесите раствор...',
      orderIndex: 0,
      actorUserId: 'admin',
    });
    expect(a.etag).toMatch(/^[a-f0-9]{64}$/);
    expect(a.version).toBe(1);
  });

  it('etag одинаковый для одинакового контента', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    const e1 = svc.computeEtag('T', 'B', []);
    const e2 = svc.computeEtag('T', 'B', []);
    expect(e1).toBe(e2);
  });

  it('etag меняется при изменении body, версия+1', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    const s = await svc.createSection({ title: 'A', orderIndex: 0, actorUserId: 'admin' });
    const a = await svc.createArticle({
      sectionId: s.id,
      title: 'T',
      body: 'v1',
      orderIndex: 0,
      actorUserId: 'admin',
    });
    const v1etag = a.etag;
    const upd = await svc.updateArticle(a.id, { body: 'v2 обновлённый', actorUserId: 'admin' });
    expect(upd.etag).not.toBe(v1etag);
    expect(upd.version).toBe(2);
  });

  it('etag стабилен, если изменился только orderIndex', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    const s = await svc.createSection({ title: 'A', orderIndex: 0, actorUserId: 'admin' });
    const a = await svc.createArticle({
      sectionId: s.id,
      title: 'T',
      body: 'v1',
      orderIndex: 0,
      actorUserId: 'admin',
    });
    const beforeEtag = a.etag;
    const upd = await svc.updateArticle(a.id, { orderIndex: 5, actorUserId: 'admin' });
    expect(upd.etag).toBe(beforeEtag);
    expect(upd.version).toBe(1);
  });

  it('getArticle 404', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    await expect(svc.getArticle('missing')).rejects.toThrow(NotFoundError);
  });

  it('createArticle в несуществующую секцию → 404', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    await expect(
      svc.createArticle({
        sectionId: 'missing',
        title: 'T',
        body: 'B',
        orderIndex: 0,
        actorUserId: 'admin',
      }),
    ).rejects.toThrow(NotFoundError);
  });
});

describe('MethodologyService.search', () => {
  it('требует непустой query', async () => {
    const st = mkPrisma();
    const svc = new MethodologyService(st.prisma, mkFeed());
    await expect(svc.search('')).rejects.toThrow(InvalidInputError);
    await expect(svc.search('   ')).rejects.toThrow(InvalidInputError);
  });

  it('вызывает $queryRaw и маппит результат', async () => {
    const st = mkPrisma();
    st.rawQueryResults.push({
      id: 'art1',
      sectionId: 'sec1',
      title: 'Штукатурка',
      snippet: '«шпатлевание» поверхности...',
      rank: 0.45,
    });
    const svc = new MethodologyService(st.prisma, mkFeed());
    const hits = await svc.search('шпатлёвка');
    expect(hits).toHaveLength(1);
    expect(hits[0].id).toBe('art1');
    expect(hits[0].rank).toBeCloseTo(0.45);
    expect(st.prisma.$queryRaw).toHaveBeenCalled();
  });
});
