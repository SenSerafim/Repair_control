import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AccessGuard } from './access.guard';
import { AccessRequirement, REQUIRE_ACCESS_KEY } from './access.decorator';
import { PrismaService } from '@app/common';

const buildCtx = (req: any, requirement?: AccessRequirement) => {
  const reflector = {
    getAllAndOverride: jest.fn((key: string) =>
      key === REQUIRE_ACCESS_KEY ? requirement : undefined,
    ),
  } as unknown as Reflector;
  const execCtx = {
    switchToHttp: () => ({ getRequest: () => req }),
    getHandler: () => undefined,
    getClass: () => undefined,
  } as unknown as ExecutionContext;
  return { reflector, execCtx };
};

const mkPrisma = (overrides: Partial<PrismaService> = {}) =>
  ({
    project: { findUnique: jest.fn() },
    stage: { findUnique: jest.fn() },
    ...overrides,
  }) as unknown as PrismaService;

describe('AccessGuard', () => {
  it('пропускает, если на хендлере нет @RequireAccess', async () => {
    const { reflector, execCtx } = buildCtx({ user: { userId: 'u1', systemRole: 'customer' } });
    const guard = new AccessGuard(reflector, mkPrisma());
    await expect(guard.canActivate(execCtx)).resolves.toBe(true);
  });

  it('бросает ForbiddenException, если в request нет user', async () => {
    const { reflector, execCtx } = buildCtx({}, { action: 'project.create' });
    const guard = new AccessGuard(reflector, mkPrisma());
    await expect(guard.canActivate(execCtx)).rejects.toThrow(ForbiddenException);
  });

  it('admin всегда проходит без подгрузки ресурса', async () => {
    const { reflector, execCtx } = buildCtx(
      { user: { userId: 'u-adm', systemRole: 'admin' } },
      {
        action: 'project.edit',
        resource: 'project',
        resourceIdFrom: { source: 'params', key: 'projectId' },
      },
    );
    const prisma = mkPrisma();
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).resolves.toBe(true);
  });

  it('customer-владелец проходит project.edit; подгружает ownerId и membership', async () => {
    const req = {
      user: { userId: 'u1', systemRole: 'customer' },
      params: { projectId: 'p1' },
    };
    const prisma = mkPrisma() as any;
    prisma.project.findUnique = jest.fn().mockResolvedValue({
      ownerId: 'u1',
      memberships: [{ role: 'customer', permissions: {} }],
    });
    const { reflector, execCtx } = buildCtx(req, {
      action: 'project.edit',
      resource: 'project',
      resourceIdFrom: { source: 'params', key: 'projectId' },
    });
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).resolves.toBe(true);
    expect(prisma.project.findUnique).toHaveBeenCalledWith({
      where: { id: 'p1' },
      select: expect.any(Object),
    });
  });

  it('customer не-владелец получает 403 при попытке отредактировать чужой проект', async () => {
    const req = {
      user: { userId: 'u1', systemRole: 'customer' },
      params: { projectId: 'p1' },
    };
    const prisma = mkPrisma() as any;
    prisma.project.findUnique = jest.fn().mockResolvedValue({
      ownerId: 'u-somebody-else',
      memberships: [],
    });
    const { reflector, execCtx } = buildCtx(req, {
      action: 'project.edit',
      resource: 'project',
      resourceIdFrom: { source: 'params', key: 'projectId' },
    });
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).rejects.toThrow(ForbiddenException);
  });

  it('representative без canEditStages → 403 на project.edit', async () => {
    const req = {
      user: { userId: 'u-rep', systemRole: 'representative' },
      params: { projectId: 'p1' },
    };
    const prisma = mkPrisma() as any;
    prisma.project.findUnique = jest.fn().mockResolvedValue({
      ownerId: 'u-owner',
      memberships: [{ role: 'representative', permissions: { canEditStages: false } }],
    });
    const { reflector, execCtx } = buildCtx(req, {
      action: 'project.edit',
      resource: 'project',
      resourceIdFrom: { source: 'params', key: 'projectId' },
    });
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).rejects.toThrow(ForbiddenException);
  });

  it('representative с canEditStages проходит project.edit', async () => {
    const req = {
      user: { userId: 'u-rep', systemRole: 'representative' },
      params: { projectId: 'p1' },
    };
    const prisma = mkPrisma() as any;
    prisma.project.findUnique = jest.fn().mockResolvedValue({
      ownerId: 'u-owner',
      memberships: [{ role: 'representative', permissions: { canEditStages: true } }],
    });
    const { reflector, execCtx } = buildCtx(req, {
      action: 'project.edit',
      resource: 'project',
      resourceIdFrom: { source: 'params', key: 'projectId' },
    });
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).resolves.toBe(true);
  });

  it('подгружает контекст этапа (resource=stage)', async () => {
    const req = {
      user: { userId: 'u1', systemRole: 'contractor' },
      params: { stageId: 's1' },
    };
    const prisma = mkPrisma() as any;
    prisma.stage.findUnique = jest.fn().mockResolvedValue({
      foremanIds: ['u1'],
      project: {
        id: 'p1',
        ownerId: 'u-owner',
        memberships: [{ role: 'foreman', permissions: {} }],
      },
    });
    const { reflector, execCtx } = buildCtx(req, {
      action: 'stage.start',
      resource: 'stage',
      resourceIdFrom: { source: 'params', key: 'stageId' },
    });
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).resolves.toBe(true);
    expect(prisma.stage.findUnique).toHaveBeenCalled();
  });

  it('граничный случай: resource указан, но resourceIdFrom не дал id — не падает, идёт в canAccess без контекста', async () => {
    const req = {
      user: { userId: 'u1', systemRole: 'customer' },
      params: {}, // id отсутствует
    };
    const prisma = mkPrisma();
    const { reflector, execCtx } = buildCtx(req, {
      action: 'project.create', // customer может без контекста
      resource: 'project',
      resourceIdFrom: { source: 'params', key: 'projectId' },
    });
    const guard = new AccessGuard(reflector, prisma);
    await expect(guard.canActivate(execCtx)).resolves.toBe(true);
  });
});
