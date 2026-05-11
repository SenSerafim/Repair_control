import * as crypto from 'crypto';
import {
  ConflictException,
  ForbiddenException,
  GoneException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Clock, ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { ChatsService } from '../chats/chats.service';
import { FeedService } from '../feed/feed.service';
import { MembersService, MembershipRole } from './members.service';

const INVITATION_TTL_DAYS = 14;
/** TTL для invite-by-code (P2). 7 дней. */
const CODE_TTL_DAYS = 7;
const CODE_LENGTH = 6;
const CODE_GEN_MAX_RETRIES = 5;

export interface GenerateInviteCodeInput {
  projectId: string;
  byUserId: string;
  role: MembershipRole;
  permissions?: Record<string, boolean>;
  stageIds?: string[];
}

@Injectable()
export class InvitationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly chats: ChatsService,
    private readonly feed: FeedService,
    // MembersService даёт helpers `collectRecipientUserIds` + `emitMembershipChanged`,
    // чтобы joinByCode имел те же side-effects (feed-event + WS-broadcast),
    // что и обычное addMembership. До этого вступление по коду было «тихим»:
    // ни ленты, ни push, ни чата → у других участников ничего не обновлялось
    // до перезапуска приложения (главная жалоба).
    private readonly members: MembersService,
  ) {}

  async invite(params: {
    projectId: string;
    actorUserId: string;
    phone: string;
    role: MembershipRole;
    permissions?: Record<string, boolean>;
    stageIds?: string[];
  }) {
    const project = await this.prisma.project.findUnique({ where: { id: params.projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');

    if (project.ownerId !== params.actorUserId) {
      const actor = await this.prisma.membership.findFirst({
        where: { projectId: params.projectId, userId: params.actorUserId },
        select: { role: true },
      });
      if (actor?.role === 'foreman' && params.role !== 'master') {
        throw new ForbiddenException('foreman can invite only master role');
      }
    }

    const expiresAt = new Date(
      this.clock.now().getTime() + INVITATION_TTL_DAYS * 24 * 60 * 60 * 1000,
    );

    // Генерируем numeric 6-значный token (как generateCode), чтобы получатель
    // мог ввести его в «Присоединиться по коду». Дубликат при коллизии — повтор.
    for (let i = 0; i < CODE_GEN_MAX_RETRIES; i++) {
      const token = generateNumericCode(CODE_LENGTH);
      try {
        return await this.prisma.projectInvitation.create({
          data: {
            projectId: params.projectId,
            phone: params.phone,
            role: params.role,
            invitedById: params.actorUserId,
            token,
            permissions: params.permissions ?? undefined,
            stageIds: params.stageIds ?? [],
            expiresAt,
          },
        });
      } catch (e: unknown) {
        if (
          typeof e === 'object' &&
          e !== null &&
          'code' in e &&
          (e as { code?: string }).code === 'P2002'
        ) {
          continue;
        }
        throw e;
      }
    }
    throw new ConflictException('failed to generate unique code, retry');
  }

  async listForProject(projectId: string) {
    return this.prisma.projectInvitation.findMany({
      where: { projectId, status: 'pending' },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancel(projectId: string, invitationId: string) {
    await this.prisma.projectInvitation.updateMany({
      where: { id: invitationId, projectId, status: 'pending' },
      data: { status: 'cancelled' },
    });
  }

  // ---------- P2: invite-by-code ----------

  /**
   * Генерирует 6-значный код приглашения.
   * Если случайный код уже занят активным pending — повтор до 5 раз.
   */
  async generateCode(input: GenerateInviteCodeInput) {
    const project = await this.prisma.project.findUnique({
      where: { id: input.projectId },
      select: { id: true, ownerId: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');

    // Бригадир может пригласить только мастера. RBAC matrix допускает
    // foreman→project.invite_member на уровне роли — здесь сужаем до
    // конкретной приглашаемой роли (ТЗ §1.5: foreman не приглашает
    // representative/foreman).
    if (project.ownerId !== input.byUserId) {
      const actor = await this.prisma.membership.findFirst({
        where: { projectId: input.projectId, userId: input.byUserId },
        select: { role: true },
      });
      if (actor?.role === 'foreman' && input.role !== 'master') {
        throw new ForbiddenException('foreman can invite only master role');
      }
    }

    const expiresAt = new Date(this.clock.now().getTime() + CODE_TTL_DAYS * 24 * 60 * 60 * 1000);

    for (let i = 0; i < CODE_GEN_MAX_RETRIES; i++) {
      const code = generateNumericCode(CODE_LENGTH);
      try {
        return await this.prisma.projectInvitation.create({
          data: {
            projectId: input.projectId,
            phone: '',
            role: input.role,
            invitedById: input.byUserId,
            token: code,
            permissions: input.permissions ?? undefined,
            stageIds: input.stageIds ?? [],
            expiresAt,
          },
          select: {
            id: true,
            token: true,
            role: true,
            stageIds: true,
            expiresAt: true,
          },
        });
      } catch (e: unknown) {
        // Prisma unique violation на token — пробуем ещё раз.
        if (
          typeof e === 'object' &&
          e !== null &&
          'code' in e &&
          (e as { code?: string }).code === 'P2002'
        ) {
          continue;
        }
        throw e;
      }
    }
    throw new ConflictException('failed to generate unique code, retry');
  }

  /**
   * Принять приглашение по коду. Создаёт Membership + закрывает invitation.
   *
   * ТЗ §10.1/§13.2/§14: вступивший по коду должен немедленно:
   *  1) появиться в общем project-чате (`chats.ensureProjectChat` + add),
   *  2) сгенерировать feed-событие `membership_added` → notification-router
   *     отправит push новому участнику ([Проект — Роль] Вас добавили),
   *  3) спровоцировать тихий WS-broadcast `project:membership_changed`,
   *     чтобы у всех остальных клиентов инвалидировались списки
   *     проектов / команды / чатов без pull-to-refresh.
   *
   * До этого joinByCode только писал Membership и `acceptedAt` — все
   * остальные стороны узнавали об изменении только после перезапуска
   * приложения. Это и было главной причиной жалобы пользователя.
   */
  async joinByCode(userId: string, code: string) {
    const inv = await this.prisma.projectInvitation.findFirst({
      where: { token: code, status: 'pending' },
    });
    if (!inv) throw new NotFoundException('invite code not found');

    if (inv.expiresAt < this.clock.now()) {
      await this.prisma.projectInvitation.update({
        where: { id: inv.id },
        data: { status: 'expired' },
      });
      throw new GoneException('invite code expired');
    }

    const existing = await this.prisma.membership.findFirst({
      where: { projectId: inv.projectId, userId, role: inv.role },
    });
    if (existing) throw new ConflictException('already a member with this role');

    const result = await this.prisma.$transaction(async (tx) => {
      const membership = await tx.membership.create({
        data: {
          projectId: inv.projectId,
          userId,
          role: inv.role,
          permissions: (inv.permissions ?? {}) as object,
          stageIds: inv.stageIds ?? [],
        },
      });
      // Появление foreman включает требование согласования плана (зеркалит
      // members.service:addMembership). ТЗ §4.2 — кнопка «Старт» этапа серая
      // до approval плана от заказчика.
      if (inv.role === 'foreman') {
        await tx.project.update({
          where: { id: inv.projectId },
          data: { requiresPlanApproval: true },
        });
      }
      await tx.projectInvitation.update({
        where: { id: inv.id },
        data: {
          status: 'accepted',
          acceptedBy: userId,
          acceptedAt: this.clock.now(),
        },
      });
      // Лента + маршрутизация push новому участнику. Эмитим внутри транзакции,
      // чтобы feed_event коммитился атомарно с membership.
      await this.feed.emit({
        tx,
        kind: 'membership_added',
        projectId: inv.projectId,
        actorId: userId,
        payload: { userId, role: inv.role },
      });
      return { membership, projectId: inv.projectId };
    });

    // Чат-side и WS-broadcast — вне транзакции, не валим accept если что-то
    // упадёт по сети/redis. Membership уже создан, остальное — best-effort.
    try {
      await this.chats.ensureProjectChat(result.projectId, userId);
      await this.chats.addProjectChatParticipant(result.projectId, userId);
    } catch (_e) {
      // membership уже создан — не откатываем
    }

    // Тихий WS-broadcast всем участникам проекта (включая нового — чтобы у него
    // сразу появился проект в списке). Без push, чтобы не плодить шум.
    try {
      const recipientUserIds = await this.members.collectRecipientUserIds(
        result.projectId,
        userId,
      );
      this.members.emitMembershipChanged({
        projectId: result.projectId,
        userId,
        role: inv.role,
        action: 'added',
        recipientUserIds,
      });
    } catch (_e) {
      /* best-effort */
    }

    return result;
  }
}

function generateNumericCode(length: number): string {
  const min = 10 ** (length - 1);
  const max = 10 ** length;
  return crypto.randomInt(min, max).toString();
}
