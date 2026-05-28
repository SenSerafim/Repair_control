import { ToolsService } from './tools.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

/**
 * In-memory mock Prisma — повторяет ровно те запросы, которые делает
 * упрощённый ToolsService (self-custody, 2026-05-12). Сознательно НЕ имитирует
 * Postgres-семантику кроме нужного минимума.
 */
const mkPrisma = () => {
  const users = new Map<string, any>();
  const tools = new Map<string, any>();
  const events: any[] = [];
  const memberships: any[] = [];
  let tSeq = 0;
  let eSeq = 0;

  const prisma: any = {
    user: {
      findUnique: jest.fn(({ where }: any) => users.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) => {
        if (where?.id?.in) return [...users.values()].filter((u) => where.id.in.includes(u.id));
        return [...users.values()];
      }),
    },
    toolItem: {
      create: jest.fn(({ data }: any) => {
        const t = {
          id: `tl${++tSeq}`,
          ownerId: data.ownerId,
          currentHolderId: data.currentHolderId,
          name: data.name,
          article: data.article ?? null,
          photoKey: data.photoKey ?? null,
          serial: data.serial ?? null,
          status: data.status ?? 'in_storage',
          storageLocation: data.storageLocation ?? null,
          assignedEmployeeId: data.assignedEmployeeId ?? null,
          projectId: data.projectId ?? null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        tools.set(t.id, t);
        return t;
      }),
      findUnique: jest.fn(({ where }: any) => tools.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) =>
        [...tools.values()].filter((t) => {
          if (where.ownerId && t.ownerId !== where.ownerId) return false;
          if (where.projectId === null && t.projectId !== null) return false;
          if (where.projectId && where.projectId !== null && t.projectId !== where.projectId)
            return false;
          if (where.id?.in) return where.id.in.includes(t.id);
          if (where.status && t.status !== where.status) return false;
          if (where.name?.contains) {
            if (!t.name.toLowerCase().includes(where.name.contains.toLowerCase())) {
              return false;
            }
          }
          return true;
        }),
      ),
      update: jest.fn(({ where, data }: any) => {
        const t = tools.get(where.id);
        if (!t) throw new Error('not found');
        // Эмулируем Prisma relation operations
        if (data.assignedEmployee?.connect) {
          t.assignedEmployeeId = data.assignedEmployee.connect.id;
        } else if (data.assignedEmployee?.disconnect) {
          t.assignedEmployeeId = null;
        }
        const cleaned = { ...data };
        delete cleaned.assignedEmployee;
        Object.assign(t, cleaned);
        return t;
      }),
      delete: jest.fn(({ where }: any) => {
        tools.delete(where.id);
        return null;
      }),
    },
    toolCustodyEvent: {
      create: jest.fn(({ data }: any) => {
        const e = {
          id: `ev${++eSeq}`,
          toolItemId: data.toolItemId,
          projectId: data.projectId,
          holderId: data.holderId,
          previousHolderId: data.previousHolderId ?? null,
          note: data.note ?? null,
          createdAt: new Date(Date.now() + eSeq), // монотонное возрастание
        };
        events.push(e);
        return e;
      }),
      findMany: jest.fn(({ where, orderBy }: any) => {
        let list = events.filter((e) => e.toolItemId === where.toolItemId);
        if (orderBy?.createdAt === 'desc')
          list = [...list].sort((a, b) => b.createdAt - a.createdAt);
        return list;
      }),
    },
    membership: {
      findFirst: jest.fn(({ where }: any) => {
        return (
          memberships.find((m) => {
            if (where.projectId && m.projectId !== where.projectId) return false;
            if (where.userId && m.userId !== where.userId) return false;
            if (where.removedAt === null && m.removedAt !== null) return false;
            if (where.user?.activeRole) {
              const u = users.get(m.userId);
              if (!u || u.activeRole !== where.user.activeRole) return false;
            }
            return true;
          }) ?? null
        );
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, users, tools, events, memberships };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

const addUser = (
  st: ReturnType<typeof mkPrisma>,
  id: string,
  firstName = 'F',
  lastName = 'L',
  phone = `+7900000${id.slice(-4)}`,
  activeRole: string = 'master',
) => {
  st.users.set(id, { id, firstName, lastName, phone, avatarUrl: null, activeRole });
};

const addMember = (
  st: ReturnType<typeof mkPrisma>,
  projectId: string,
  userId: string,
  role = 'foreman',
) => {
  st.memberships.push({ projectId, userId, role, removedAt: null });
};

// ============================================================================

describe('ToolsService.createMyTool', () => {
  it('создаёт инструмент в личном профиле; holder = owner', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Перфоратор' });
    expect(t.ownerId).toBe('u-owner');
    expect(t.currentHolderId).toBe('u-owner');
    expect(t.projectId).toBeNull();
  });
});

describe('ToolsService.createInProject', () => {
  it('создаёт инструмент сразу в проекте от actor-а; пишет initial custody event', async () => {
    const st = mkPrisma();
    addUser(st, 'u-actor');
    addMember(st, 'p1', 'u-actor');
    const feed = mkFeed();
    const svc = new ToolsService(st.prisma, feed);

    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-actor',
      name: 'Шуруповёрт',
    });

    expect(t.ownerId).toBe('u-actor');
    expect(t.currentHolderId).toBe('u-actor');
    expect(t.projectId).toBe('p1');
    expect(st.events).toHaveLength(1);
    expect(st.events[0]).toMatchObject({
      toolItemId: t.id,
      holderId: 'u-actor',
      previousHolderId: null,
    });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'tool_added_to_project' }),
    );
  });

  it('позволяет актору указать другого owner-а (member проекта)', async () => {
    const st = mkPrisma();
    addUser(st, 'u-actor');
    addUser(st, 'u-other');
    addMember(st, 'p1', 'u-actor');
    addMember(st, 'p1', 'u-other');
    const svc = new ToolsService(st.prisma, mkFeed());

    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-actor',
      ownerId: 'u-other',
      name: 'Болгарка',
    });

    expect(t.ownerId).toBe('u-other');
    expect(t.currentHolderId).toBe('u-other');
  });

  it('403 если actor не member проекта', async () => {
    const st = mkPrisma();
    addUser(st, 'u-actor');
    const svc = new ToolsService(st.prisma, mkFeed());
    await expect(
      svc.createInProject({ projectId: 'p1', actorUserId: 'u-actor', name: 'X' }),
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('403 если указанный owner не member проекта', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-actor');
    const svc = new ToolsService(st.prisma, mkFeed());
    await expect(
      svc.createInProject({
        projectId: 'p1',
        actorUserId: 'u-actor',
        ownerId: 'u-stranger',
        name: 'X',
      }),
    ).rejects.toBeInstanceOf(ForbiddenError);
  });
});

describe('ToolsService.attachFromMy', () => {
  it('переносит инструменты owner-а в проект; создаёт events', async () => {
    const st = mkPrisma();
    addUser(st, 'u-actor');
    addMember(st, 'p1', 'u-actor');
    const svc = new ToolsService(st.prisma, mkFeed());

    const t1 = await svc.createMyTool({ ownerId: 'u-actor', name: 'A' });
    const t2 = await svc.createMyTool({ ownerId: 'u-actor', name: 'B' });

    const result = await svc.attachFromMy('p1', [t1.id, t2.id], 'u-actor');
    expect(result).toHaveLength(2);
    for (const t of result) {
      expect(t.projectId).toBe('p1');
      expect(t.currentHolderId).toBe('u-actor');
    }
    expect(st.events).toHaveLength(2);
  });

  it('403 при попытке привязать чужой инструмент', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-actor');
    const svc = new ToolsService(st.prisma, mkFeed());
    const foreign = await svc.createMyTool({ ownerId: 'u-other', name: 'X' });
    await expect(svc.attachFromMy('p1', [foreign.id], 'u-actor')).rejects.toBeInstanceOf(
      ForbiddenError,
    );
  });
});

describe('ToolsService.claim (self-custody)', () => {
  it('текущий пользователь становится holder-ом; пишется event с previousHolderId', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-other');
    const feed = mkFeed();
    const svc = new ToolsService(st.prisma, feed);

    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'Дрель',
    });

    const updated = await svc.claim(t.id, 'u-other', 'на 3 этаж');

    expect(updated.currentHolderId).toBe('u-other');
    const claimEvent = st.events.find(
      (e) => e.holderId === 'u-other' && e.previousHolderId === 'u-owner',
    );
    expect(claimEvent).toBeDefined();
    expect(claimEvent!.note).toBe('на 3 этаж');
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'tool_custody_changed',
        actorId: 'u-other',
      }),
    );
  });

  it('409 если actor уже держит этот инструмент', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'Х',
    });
    await expect(svc.claim(t.id, 'u-owner')).rejects.toBeInstanceOf(ConflictError);
  });

  it('403 если actor не member проекта', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'X',
    });
    await expect(svc.claim(t.id, 'u-stranger')).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('400 если инструмент не в проекте (личный)', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'X' });
    await expect(svc.claim(t.id, 'u-other')).rejects.toBeInstanceOf(InvalidInputError);
  });

  it('404 если tool не существует', async () => {
    const st = mkPrisma();
    const svc = new ToolsService(st.prisma, mkFeed());
    await expect(svc.claim('does-not-exist', 'u-x')).rejects.toBeInstanceOf(NotFoundError);
  });
});

describe('ToolsService.listProjectTools', () => {
  it('возвращает инструменты проекта с обогащёнными owner/holder', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner', 'Иван', 'Петров');
    addUser(st, 'u-other', 'Пётр', 'Сидоров');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-other');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'Кувалда',
    });
    await svc.claim(t.id, 'u-other');

    const list = await svc.listProjectTools('p1', 'u-other');
    expect(list).toHaveLength(1);
    expect(list[0]._owner?.firstName).toBe('Иван');
    expect(list[0]._holder?.firstName).toBe('Пётр');
  });

  it('403 если viewer не member проекта', async () => {
    const st = mkPrisma();
    const svc = new ToolsService(st.prisma, mkFeed());
    await expect(svc.listProjectTools('p1', 'u-stranger')).rejects.toBeInstanceOf(ForbiddenError);
  });
});

describe('ToolsService enrichment (single-tool returns)', () => {
  it('getTool возвращает _owner и _holder с phone (для tap-to-call)', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner', 'Иван', 'Петров', '+79991110000');
    addUser(st, 'u-other', 'Пётр', 'Сидоров', '+79991111111');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-other');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'Лестница',
    });
    await svc.claim(t.id, 'u-other');

    const got = await svc.getTool(t.id, 'u-other');
    expect(got._owner?.firstName).toBe('Иван');
    expect(got._owner?.phone).toBe('+79991110000');
    expect(got._holder?.firstName).toBe('Пётр');
    expect(got._holder?.phone).toBe('+79991111111');
  });

  it('claim возвращает обогащённый инструмент с новым _holder', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner', 'Иван', 'Петров', '+79991110000');
    addUser(st, 'u-other', 'Пётр', 'Сидоров', '+79991111111');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-other');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'Молоток',
    });
    const claimed = await svc.claim(t.id, 'u-other');
    expect(claimed.currentHolderId).toBe('u-other');
    expect(claimed._holder?.firstName).toBe('Пётр');
    expect(claimed._owner?.firstName).toBe('Иван');
  });

  it('createInProject и attachFromMy возвращают обогащённые объекты', async () => {
    const st = mkPrisma();
    addUser(st, 'u-actor', 'Алексей', 'Иванов', '+79991112222');
    addMember(st, 'p1', 'u-actor');
    const svc = new ToolsService(st.prisma, mkFeed());

    const created = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-actor',
      name: 'Болгарка',
    });
    expect(created._owner?.firstName).toBe('Алексей');
    expect(created._holder?.firstName).toBe('Алексей');

    const my = await svc.createMyTool({ ownerId: 'u-actor', name: 'Шуруповёрт' });
    const attached = await svc.attachFromMy('p1', [my.id], 'u-actor');
    expect(attached).toHaveLength(1);
    expect(attached[0]._holder?.firstName).toBe('Алексей');
  });
});

describe('ToolsService.listCustodyHistory', () => {
  it('возвращает события DESC по времени', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addUser(st, 'u-a');
    addUser(st, 'u-b');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-a');
    addMember(st, 'p1', 'u-b');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'Тест',
    });
    await svc.claim(t.id, 'u-a');
    await svc.claim(t.id, 'u-b');

    const history = await svc.listCustodyHistory(t.id, 'u-owner');
    expect(history).toHaveLength(3);
    // первый по DESC — последний по времени → claim u-b
    expect(history[0].holderId).toBe('u-b');
    expect(history[0].previousHolderId).toBe('u-a');
    expect(history[2].previousHolderId).toBeNull();
  });
});

describe('ToolsService.deleteTool', () => {
  it('запрещает удалить если currentHolder ≠ owner', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-other');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'X',
    });
    await svc.claim(t.id, 'u-other');

    await expect(svc.deleteTool(t.id, 'u-owner')).rejects.toBeInstanceOf(ConflictError);
  });

  it('разрешает удалить если у owner-а', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'X' });
    await svc.deleteTool(t.id, 'u-owner');
    expect(st.tools.has(t.id)).toBe(false);
  });
});

describe('ToolsService.detachFromProject', () => {
  it('убирает projectId и возвращает currentHolder = owner', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-other');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'X',
    });
    await svc.claim(t.id, 'u-other');

    const u = await svc.detachFromProject(t.id, 'u-owner');
    expect(u.projectId).toBeNull();
    expect(u.currentHolderId).toBe('u-owner');
  });

  it('403 если actor не owner', async () => {
    const st = mkPrisma();
    addMember(st, 'p1', 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createInProject({
      projectId: 'p1',
      actorUserId: 'u-owner',
      name: 'X',
    });
    await expect(svc.detachFromProject(t.id, 'u-other')).rejects.toBeInstanceOf(ForbiddenError);
  });
});

// ============================================================================
// E12 — Tools rewrite в профиле (NEWFIX-2 §7)
// ============================================================================

describe('E12 ToolsService.createMyTool — расширенные поля', () => {
  it('article/storageLocation сохраняются для in_storage', async () => {
    const st = mkPrisma();
    addUser(st, 'u1');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({
      ownerId: 'u1',
      name: 'Перфоратор',
      article: 'GBH-2-26',
      status: 'in_storage',
      storageLocation: 'Гараж',
    });
    expect(t.article).toBe('GBH-2-26');
    expect(t.status).toBe('in_storage');
    expect(t.storageLocation).toBe('Гараж');
  });

  it('with_employee без assignedEmployeeId — 400', async () => {
    const st = mkPrisma();
    addUser(st, 'u1');
    const svc = new ToolsService(st.prisma, mkFeed());
    await expect(
      svc.createMyTool({
        ownerId: 'u1',
        name: 'Шуруповёрт',
        status: 'with_employee',
      }),
    ).rejects.toBeInstanceOf(InvalidInputError);
  });

  it('with_employee сохраняет assignedEmployeeId', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addUser(st, 'u-emp');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({
      ownerId: 'u-owner',
      name: 'Шуруповёрт',
      status: 'with_employee',
      assignedEmployeeId: 'u-emp',
    });
    expect(t.status).toBe('with_employee');
    expect(t.assignedEmployeeId).toBe('u-emp');
  });
});

describe('E12 ToolsService.listMyTools — поиск и фильтр', () => {
  it('search по подстроке (case-insensitive)', async () => {
    const st = mkPrisma();
    addUser(st, 'u1');
    const svc = new ToolsService(st.prisma, mkFeed());
    await svc.createMyTool({ ownerId: 'u1', name: 'Перфоратор Bosch' });
    await svc.createMyTool({ ownerId: 'u1', name: 'Рулетка Stanley' });
    const res = await svc.listMyTools({ ownerId: 'u1', search: 'BOSCH' });
    expect(res).toHaveLength(1);
    expect(res[0].name).toContain('Bosch');
  });

  it('фильтр по status=in_storage', async () => {
    const st = mkPrisma();
    addUser(st, 'u1');
    addUser(st, 'u-emp');
    const svc = new ToolsService(st.prisma, mkFeed());
    await svc.createMyTool({ ownerId: 'u1', name: 'Tool A' });
    await svc.createMyTool({
      ownerId: 'u1',
      name: 'Tool B',
      status: 'with_employee',
      assignedEmployeeId: 'u-emp',
    });
    const inStorage = await svc.listMyTools({ ownerId: 'u1', status: 'in_storage' });
    expect(inStorage).toHaveLength(1);
    expect(inStorage[0].name).toBe('Tool A');
    const withEmp = await svc.listMyTools({ ownerId: 'u1', status: 'with_employee' });
    expect(withEmp).toHaveLength(1);
    expect(withEmp[0].name).toBe('Tool B');
  });
});

describe('E12 ToolsService.updateTool — смена статуса', () => {
  it('меняет in_storage → with_employee, очищает storageLocation', async () => {
    const st = mkPrisma();
    addUser(st, 'u1');
    addUser(st, 'u-emp');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({
      ownerId: 'u1',
      name: 'Tool',
      status: 'in_storage',
      storageLocation: 'Гараж',
    });
    const updated = await svc.updateTool(
      t.id,
      { status: 'with_employee', assignedEmployeeId: 'u-emp' },
      'u1',
    );
    expect(updated.status).toBe('with_employee');
    expect(updated.assignedEmployeeId).toBe('u-emp');
    expect(updated.storageLocation).toBeNull();
  });

  it('запрещает смену на with_employee без employee', async () => {
    const st = mkPrisma();
    addUser(st, 'u1');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u1', name: 'Tool' });
    await expect(svc.updateTool(t.id, { status: 'with_employee' }, 'u1')).rejects.toBeInstanceOf(
      InvalidInputError,
    );
  });
});

// ============================================================================
// E13 — Tools на проекте + выдача (NEWFIX-2 §8/§9)
// ============================================================================

describe('E13 ToolsService.attachFromMy — §8.3 default holder = бригадир', () => {
  it('если в проекте есть contractor — он становится initial holder', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addUser(st, 'u-foreman', 'И', 'П', '+7900', 'contractor');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-foreman');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    const [attached] = await svc.attachFromMy('p1', [t.id], 'u-owner');
    expect(attached.currentHolderId).toBe('u-foreman');
    expect(attached.status).toBe('on_project');
  });

  it('responsibleUserId переопределяет default', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addUser(st, 'u-foreman', 'И', 'П', '+7900', 'contractor');
    addUser(st, 'u-master');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p1', 'u-foreman');
    addMember(st, 'p1', 'u-master');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    const [attached] = await svc.attachFromMy('p1', [t.id], 'u-owner', 'u-master');
    expect(attached.currentHolderId).toBe('u-master');
  });

  it('если бригадира нет — fallback на actor', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addMember(st, 'p1', 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    const [attached] = await svc.attachFromMy('p1', [t.id], 'u-owner');
    expect(attached.currentHolderId).toBe('u-owner');
  });
});

describe('E13 ToolsService.attachFromMy — §8.4 блокировка дублей', () => {
  it('инструмент уже на другом проекте — 409', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addMember(st, 'p1', 'u-owner');
    addMember(st, 'p2', 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    await svc.attachFromMy('p1', [t.id], 'u-owner');
    await expect(svc.attachFromMy('p2', [t.id], 'u-owner')).rejects.toBeInstanceOf(ConflictError);
  });
});

describe('E13 ToolsService.assignToEmployee — §9', () => {
  it('переводит инструмент в with_employee + currentHolder = сотрудник', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addUser(st, 'u-emp');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    const updated = await svc.assignToEmployee(t.id, 'u-emp', 'u-owner');
    expect(updated.status).toBe('with_employee');
    expect(updated.assignedEmployeeId).toBe('u-emp');
    expect(updated.currentHolderId).toBe('u-emp');
    expect(updated.projectId).toBeNull();
  });

  it('403 не-владелец не может выдавать', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    addUser(st, 'u-other');
    addUser(st, 'u-emp');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    await expect(svc.assignToEmployee(t.id, 'u-emp', 'u-other')).rejects.toBeInstanceOf(
      ForbiddenError,
    );
  });

  it('404 если сотрудник не найден', async () => {
    const st = mkPrisma();
    addUser(st, 'u-owner');
    const svc = new ToolsService(st.prisma, mkFeed());
    const t = await svc.createMyTool({ ownerId: 'u-owner', name: 'Tool' });
    await expect(svc.assignToEmployee(t.id, 'u-missing', 'u-owner')).rejects.toBeInstanceOf(
      NotFoundError,
    );
  });
});
