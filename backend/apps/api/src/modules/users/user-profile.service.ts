import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@app/common';

/**
 * ТЗ NEWFIX §4 — агрегатный экран профиля сотрудника. 5 секций
 * (objects / monthStats / tools / reclamations / payouts) + жёсткие
 * правила видимости по роли смотрящего. Сервис делает целевую выборку
 * каждым подзапросом, чтобы шапка экрана грузилась одним RTT.
 */
@Injectable()
export class UserProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async getAggregate(viewerUserId: string, targetUserId: string) {
    const target = await this.prisma.user.findUnique({
      where: { id: targetUserId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        email: true,
        avatarUrl: true,
        activeRole: true,
        deletedAt: true,
      },
    });
    if (!target || target.deletedAt) {
      throw new NotFoundException('user_not_found');
    }

    // Видимость: viewer должен быть либо самим target'ом, либо
    // активным членом любого проекта, где target тоже активный
    // member (или owner). Иначе чужие профили не отдаём.
    const sharedProjects = await this.findSharedActiveProjects(viewerUserId, targetUserId);
    if (sharedProjects.length === 0 && viewerUserId !== targetUserId) {
      throw new ForbiddenException('no_shared_projects');
    }

    const viewerRole = await this.resolveViewerRoleInProject(viewerUserId, sharedProjects[0]?.id);

    const [objects, monthStats, tools, payouts] = await Promise.all([
      this.collectObjects(targetUserId, sharedProjects),
      this.collectMonthStats(targetUserId, sharedProjects),
      this.collectTools(targetUserId, sharedProjects),
      this.collectPayouts(targetUserId, viewerUserId, viewerRole, sharedProjects),
    ]);

    return {
      user: {
        id: target.id,
        firstName: target.firstName,
        lastName: target.lastName,
        phone: target.phone,
        email: target.email,
        avatarUrl: target.avatarUrl,
        activeRole: target.activeRole,
      },
      objects,
      monthStats,
      tools,
      // Reclamation domain ещё не реализован (ТЗ NEWFIX §4: «специально
      // отметил, ни у кого нормально не реализовано»). Отдаём счётчик
      // с нулями; mobile отрисует «—», когда домен появится — заполним.
      reclamations: { completed: 0, total: 0 },
      payouts,
    };
  }

  /** Активные shared проекты viewer↔target (owner или активная membership). */
  private async findSharedActiveProjects(viewerId: string, targetId: string) {
    return this.prisma.project.findMany({
      where: {
        archivedAt: null,
        AND: [
          {
            OR: [
              { ownerId: viewerId },
              { memberships: { some: { userId: viewerId, removedAt: null } } },
            ],
          },
          {
            OR: [
              { ownerId: targetId },
              { memberships: { some: { userId: targetId, removedAt: null } } },
            ],
          },
        ],
      },
      select: { id: true, title: true, ownerId: true },
    });
  }

  private async resolveViewerRoleInProject(
    viewerId: string,
    projectId: string | undefined,
  ): Promise<'owner' | 'foreman' | 'representative' | 'master' | 'unknown'> {
    if (!projectId) return 'unknown';
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: {
        ownerId: true,
        memberships: {
          where: { userId: viewerId, removedAt: null },
          select: { role: true },
        },
      },
    });
    if (!project) return 'unknown';
    if (project.ownerId === viewerId) return 'owner';
    const m = project.memberships[0];
    if (!m) return 'unknown';
    if (m.role === 'foreman') return 'foreman';
    if (m.role === 'representative') return 'representative';
    if (m.role === 'master') return 'master';
    return 'unknown';
  }

  private async collectObjects(
    targetId: string,
    sharedProjects: Array<{ id: string; title: string; ownerId: string }>,
  ) {
    if (sharedProjects.length === 0) return [];
    const projectIds = sharedProjects.map((p) => p.id);
    const memberships = await this.prisma.membership.findMany({
      where: { userId: targetId, removedAt: null, projectId: { in: projectIds } },
      select: { projectId: true, stageIds: true, role: true },
    });
    // Резолвим имена этапов одним запросом — индексы по orderIndex/title.
    const stageIds = memberships.flatMap((m) => m.stageIds);
    const stages = stageIds.length
      ? await this.prisma.stage.findMany({
          where: { id: { in: stageIds } },
          select: { id: true, title: true, orderIndex: true, projectId: true },
        })
      : [];
    const stageMap = new Map(stages.map((s) => [s.id, s]));
    const byProject = new Map(sharedProjects.map((p) => [p.id, p]));
    return memberships.map((m) => {
      const p = byProject.get(m.projectId)!;
      return {
        projectId: p.id,
        title: p.title,
        role: m.role,
        stages: m.stageIds
          .map((id) => stageMap.get(id))
          .filter((s): s is NonNullable<typeof s> => !!s)
          .map((s) => ({
            stageId: s.id,
            title: s.title,
            orderIndex: s.orderIndex,
          })),
      };
    });
  }

  private async collectMonthStats(targetId: string, sharedProjects: Array<{ id: string }>) {
    if (sharedProjects.length === 0) return { stepsDoneThisMonth: 0 };
    const now = new Date();
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1, 0, 0, 0));
    // Step.assigneeIds — string[] этого пользователя. Status=done за период.
    // Скоупим только в shared-проектах, чтобы заказчик не видел чужие проекты
    // через бок (даже если viewer и target оба члены проекта A, шаги
    // проекта B мы не показываем).
    const projectIds = sharedProjects.map((p) => p.id);
    const stages = await this.prisma.stage.findMany({
      where: { projectId: { in: projectIds } },
      select: { id: true },
    });
    if (stages.length === 0) return { stepsDoneThisMonth: 0 };
    const count = await this.prisma.step.count({
      where: {
        stageId: { in: stages.map((s) => s.id) },
        status: 'done',
        assigneeIds: { has: targetId },
        updatedAt: { gte: start },
      },
    });
    return { stepsDoneThisMonth: count };
  }

  private async collectTools(targetId: string, _sharedProjects: Array<{ id: string }>) {
    // ToolItem (self-custody, 2026-05-12): инструмент «у» сотрудника, когда
    // currentHolderId == userId. shared-фильтр не применяем — инструмент
    // привязан к пользователю, не к проекту.
    const tools = await this.prisma.toolItem.findMany({
      where: { currentHolderId: targetId },
      select: {
        id: true,
        name: true,
        serial: true,
        photoKey: true,
      },
      orderBy: { name: 'asc' },
    });
    return tools.map((t) => ({
      toolId: t.id,
      name: t.name,
      serial: t.serial,
      photoKey: t.photoKey,
    }));
  }

  private async collectPayouts(
    targetId: string,
    viewerId: string,
    viewerRole: 'owner' | 'foreman' | 'representative' | 'master' | 'unknown',
    sharedProjects: Array<{ id: string; title: string }>,
  ) {
    // ТЗ NEWFIX §4.2: заказчик НЕ видит выплаты мастерам/бригадирам.
    // Бригадир видит выплаты своих мастеров. Сам пользователь видит свои.
    // Представитель — наследует представительские права; на стартовой
    // итерации не показываем (можно расширить через rights.canSeeBudget).
    const isSelf = viewerId === targetId;
    const allowed = isSelf || viewerRole === 'foreman' || viewerRole === 'master';
    if (!allowed) {
      return { visible: false, monthTotal: 0, byProject: [] };
    }
    if (sharedProjects.length === 0) {
      return { visible: true, monthTotal: 0, byProject: [] };
    }
    const now = new Date();
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1, 0, 0, 0));
    const payments = await this.prisma.payment.findMany({
      where: {
        toUserId: targetId,
        projectId: { in: sharedProjects.map((p) => p.id) },
        createdAt: { gte: start },
      },
      select: { projectId: true, amount: true },
    });
    const byProjectMap = new Map<string, bigint>();
    for (const p of payments) {
      byProjectMap.set(p.projectId, (byProjectMap.get(p.projectId) ?? 0n) + p.amount);
    }
    const byProject = sharedProjects
      .filter((p) => byProjectMap.has(p.id))
      .map((p) => ({
        projectId: p.id,
        title: p.title,
        amount: Number(byProjectMap.get(p.id)!),
      }));
    const monthTotal = byProject.reduce((acc, p) => acc + p.amount, 0);
    return { visible: true, monthTotal, byProject };
  }
}
