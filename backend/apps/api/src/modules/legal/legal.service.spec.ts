import { LegalService } from './legal.service';
import { ConflictError, FixedClock, NotFoundError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

interface Doc {
  id: string;
  kind: string;
  version: number;
  title: string;
  bodyMd: string;
  publishedAt: Date | null;
  publishedById: string | null;
  isActive: boolean;
}

const mkPrisma = () => {
  const docs = new Map<string, Doc>();
  const acceptances: any[] = [];
  const audit: any[] = [];
  let seq = 0;
  const prisma: any = {
    legalDocument: {
      findFirst: jest.fn(({ where, orderBy }: any) => {
        const list = [...docs.values()].filter((d) => {
          if (where.kind && d.kind !== where.kind) return false;
          if (where.isActive !== undefined && d.isActive !== where.isActive) return false;
          if (where.publishedAt?.not !== undefined && d.publishedAt === null) return false;
          return true;
        });
        if (orderBy?.version === 'desc') list.sort((a, b) => b.version - a.version);
        return list[0] ?? null;
      }),
      findUnique: jest.fn(({ where }: any) => docs.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) => {
        return [...docs.values()].filter((d) => {
          if (where?.kind && d.kind !== where.kind) return false;
          if (where?.isActive !== undefined && d.isActive !== where.isActive) return false;
          return true;
        });
      }),
      create: jest.fn(({ data }: any) => {
        const d: Doc = {
          id: `d${++seq}`,
          kind: data.kind,
          version: data.version,
          title: data.title,
          bodyMd: data.bodyMd,
          publishedAt: null,
          publishedById: null,
          isActive: false,
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
      updateMany: jest.fn(({ where, data }: any) => {
        let count = 0;
        for (const d of docs.values()) {
          if (where.kind && d.kind !== where.kind) continue;
          if (where.isActive !== undefined && d.isActive !== where.isActive) continue;
          Object.assign(d, data);
          count++;
        }
        return { count };
      }),
    },
    legalAcceptance: {
      findMany: jest.fn(({ where }: any) =>
        acceptances.filter(
          (a) =>
            (!where.userId || a.userId === where.userId) &&
            (!where.documentId?.in || where.documentId.in.includes(a.documentId)),
        ),
      ),
      upsert: jest.fn(({ where, create }: any) => {
        const existing = acceptances.find(
          (a) =>
            a.userId === where.userId_documentId.userId &&
            a.documentId === where.userId_documentId.documentId,
        );
        if (existing) return existing;
        acceptances.push(create);
        return create;
      }),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: any) => {
        audit.push(data);
        return data;
      }),
    },
    $transaction: jest.fn(async (fn: any) => (typeof fn === 'function' ? fn(prisma) : fn)),
  };
  return { prisma: prisma as unknown as PrismaService, docs, acceptances, audit };
};

const mkAudit = (prisma: PrismaService): AdminAuditService =>
  new AdminAuditService(prisma, new FixedClock(new Date()));

describe('LegalService', () => {
  it('createDraft — version = max+1 per kind', async () => {
    const state = mkPrisma();
    const svc = new LegalService(state.prisma, new FixedClock(new Date()), mkAudit(state.prisma));

    const d1 = await svc.createDraft('admin', {
      kind: 'privacy' as any,
      title: 'v1',
      bodyMd: 'text1',
    });
    expect(d1.version).toBe(1);

    const d2 = await svc.createDraft('admin', {
      kind: 'privacy' as any,
      title: 'v2',
      bodyMd: 'text2',
    });
    expect(d2.version).toBe(2);

    const d3 = await svc.createDraft('admin', { kind: 'tos' as any, title: 'tos v1', bodyMd: 't' });
    expect(d3.version).toBe(1); // другой kind
  });

  it('publish — активирует новую версию, деактивирует старую', async () => {
    const state = mkPrisma();
    const clock = new FixedClock(new Date('2026-08-10T10:00:00Z'));
    const svc = new LegalService(state.prisma, clock, mkAudit(state.prisma));

    const d1 = await svc.createDraft('admin', { kind: 'tos' as any, title: 'v1', bodyMd: 'one' });
    await svc.publish(d1.id, 'admin');
    expect(state.docs.get(d1.id)!.isActive).toBe(true);

    const d2 = await svc.createDraft('admin', { kind: 'tos' as any, title: 'v2', bodyMd: 'two' });
    await svc.publish(d2.id, 'admin');
    expect(state.docs.get(d2.id)!.isActive).toBe(true);
    expect(state.docs.get(d1.id)!.isActive).toBe(false);
  });

  it('publish уже опубликованного → ConflictError', async () => {
    const state = mkPrisma();
    const svc = new LegalService(state.prisma, new FixedClock(new Date()), mkAudit(state.prisma));
    const d = await svc.createDraft('admin', { kind: 'privacy' as any, title: 'v1', bodyMd: 't' });
    await svc.publish(d.id, 'admin');
    await expect(svc.publish(d.id, 'admin')).rejects.toThrow(ConflictError);
  });

  it('updateDraft — published документ нельзя редактировать', async () => {
    const state = mkPrisma();
    const svc = new LegalService(state.prisma, new FixedClock(new Date()), mkAudit(state.prisma));
    const d = await svc.createDraft('admin', { kind: 'tos' as any, title: 'v1', bodyMd: 't' });
    await svc.publish(d.id, 'admin');
    await expect(svc.updateDraft(d.id, 'admin', { title: 'newtitle' })).rejects.toThrow(
      ConflictError,
    );
  });

  it('renderPublic — нет активного → NotFoundError', async () => {
    const state = mkPrisma();
    const svc = new LegalService(state.prisma, new FixedClock(new Date()), mkAudit(state.prisma));
    await expect(svc.renderPublic('privacy' as any)).rejects.toThrow(NotFoundError);
  });

  it('getAcceptanceStatus — required=true, accepted=false до accept', async () => {
    const state = mkPrisma();
    const svc = new LegalService(state.prisma, new FixedClock(new Date()), mkAudit(state.prisma));
    const d = await svc.createDraft('admin', { kind: 'privacy' as any, title: 'v1', bodyMd: 't' });
    await svc.publish(d.id, 'admin');

    const status = await svc.getAcceptanceStatus('user1');
    expect(status.privacy.required).toBe(true);
    expect(status.privacy.accepted).toBe(false);

    await svc.accept('user1', 'privacy' as any);
    const status2 = await svc.getAcceptanceStatus('user1');
    expect(status2.privacy.accepted).toBe(true);
  });
});
