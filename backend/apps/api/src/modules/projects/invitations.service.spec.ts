import { ConflictException, GoneException, NotFoundException } from '@nestjs/common';
import { FixedClock, NotFoundError, PrismaService } from '@app/common';
import { InvitationsService } from './invitations.service';

const NOW = new Date('2026-04-26T10:00:00Z');

interface InvRow {
  id: string;
  projectId: string;
  phone: string;
  role: string;
  invitedById: string;
  status: 'pending' | 'accepted' | 'expired' | 'cancelled';
  token: string;
  permissions: Record<string, boolean> | null;
  stageIds: string[];
  acceptedBy: string | null;
  acceptedAt: Date | null;
  createdAt: Date;
  expiresAt: Date;
}

const mkPrisma = () => {
  const projects = new Map<string, { id: string }>();
  const memberships: Array<{
    projectId: string;
    userId: string;
    role: string;
  }> = [];
  const invitations = new Map<string, InvRow>();
  let invSeq = 0;
  let mSeq = 0;

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
    },
    membership: {
      findFirst: jest.fn(({ where }: any) => {
        return (
          memberships.find(
            (m) =>
              m.projectId === where.projectId &&
              m.userId === where.userId &&
              (!where.role || m.role === where.role),
          ) ?? null
        );
      }),
      create: jest.fn(({ data }: any) => {
        const m = { ...data, id: `m${++mSeq}` };
        memberships.push(m);
        return m;
      }),
    },
    projectInvitation: {
      create: jest.fn(({ data }: any) => {
        // эмулируем uniqueness на token
        for (const v of invitations.values()) {
          if (v.token === data.token) {
            const e: any = new Error('unique violation');
            e.code = 'P2002';
            throw e;
          }
        }
        const inv: InvRow = {
          id: `inv${++invSeq}`,
          projectId: data.projectId,
          phone: data.phone ?? '',
          role: data.role,
          invitedById: data.invitedById,
          status: data.status ?? 'pending',
          token: data.token,
          permissions: data.permissions ?? null,
          stageIds: data.stageIds ?? [],
          acceptedBy: null,
          acceptedAt: null,
          createdAt: new Date(),
          expiresAt: data.expiresAt,
        };
        invitations.set(inv.id, inv);
        return inv;
      }),
      findFirst: jest.fn(({ where }: any) => {
        return (
          [...invitations.values()].find(
            (i) => i.token === where.token && (!where.status || i.status === where.status),
          ) ?? null
        );
      }),
      update: jest.fn(({ where, data }: any) => {
        const inv = invitations.get(where.id);
        if (!inv) throw new Error('not found');
        Object.assign(inv, data);
        return inv;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };

  return { prisma: prisma as unknown as PrismaService, projects, memberships, invitations };
};

describe('InvitationsService — invite-by-code (P2)', () => {
  it('generateCode: создаёт 6-значный pending invitation', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1' });
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    const inv = await svc.generateCode({
      projectId: 'p1',
      byUserId: 'owner1',
      role: 'master',
    });
    expect(inv.token).toMatch(/^\d{6}$/);
    expect(inv.role).toBe('master');
    expect(inv.expiresAt.getTime()).toBeGreaterThan(NOW.getTime());
  });

  it('generateCode: проект не найден → NotFoundError', async () => {
    const st = mkPrisma();
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    await expect(
      svc.generateCode({ projectId: 'nope', byUserId: 'u1', role: 'master' }),
    ).rejects.toThrow(NotFoundError);
  });

  it('joinByCode: успех — создаёт membership, статус accepted', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1' });
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    const inv = await svc.generateCode({
      projectId: 'p1',
      byUserId: 'owner1',
      role: 'master',
    });
    const result = await svc.joinByCode('newUser', inv.token);
    expect(result.projectId).toBe('p1');
    expect(result.membership.role).toBe('master');
    // invitation closed
    const updated = [...st.invitations.values()][0];
    expect(updated.status).toBe('accepted');
    expect(updated.acceptedBy).toBe('newUser');
    expect(updated.acceptedAt).toBeTruthy();
    // membership created
    expect(st.memberships).toHaveLength(1);
  });

  it('joinByCode: код не найден → NotFoundException', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1' });
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    await expect(svc.joinByCode('user', '999999')).rejects.toThrow(NotFoundException);
  });

  it('joinByCode: код просрочен → GoneException', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1' });
    const past = new Date(NOW.getTime() - 24 * 60 * 60 * 1000);
    st.invitations.set('inv1', {
      id: 'inv1',
      projectId: 'p1',
      phone: '',
      role: 'master',
      invitedById: 'owner1',
      status: 'pending',
      token: '111111',
      permissions: null,
      stageIds: [],
      acceptedBy: null,
      acceptedAt: null,
      createdAt: past,
      expiresAt: past,
    });
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    await expect(svc.joinByCode('user', '111111')).rejects.toThrow(GoneException);
    expect(st.invitations.get('inv1')!.status).toBe('expired');
  });

  it('joinByCode: уже участник с этой ролью → ConflictException', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1' });
    st.memberships.push({ projectId: 'p1', userId: 'u1', role: 'master' });
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    const inv = await svc.generateCode({
      projectId: 'p1',
      byUserId: 'owner1',
      role: 'master',
    });
    await expect(svc.joinByCode('u1', inv.token)).rejects.toThrow(ConflictException);
  });

  it('generateCode: сохраняет permissions и stageIds для representative', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1' });
    const svc = new InvitationsService(st.prisma, new FixedClock(NOW));
    const inv = await svc.generateCode({
      projectId: 'p1',
      byUserId: 'owner1',
      role: 'representative',
      permissions: { canApprove: true, canSeeBudget: true },
      stageIds: ['s1', 's2'],
    });
    expect(inv.stageIds).toEqual(['s1', 's2']);
    const stored = [...st.invitations.values()][0];
    expect(stored.permissions).toEqual({ canApprove: true, canSeeBudget: true });
    expect(stored.stageIds).toEqual(['s1', 's2']);
  });
});
