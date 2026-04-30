import * as crypto from 'crypto';
import {
  ConflictException,
  ForbiddenException,
  GoneException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Clock, ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { MembershipRole } from './members.service';

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

    return this.prisma.$transaction(async (tx) => {
      const membership = await tx.membership.create({
        data: {
          projectId: inv.projectId,
          userId,
          role: inv.role,
          permissions: (inv.permissions ?? {}) as object,
          stageIds: inv.stageIds ?? [],
        },
      });
      await tx.projectInvitation.update({
        where: { id: inv.id },
        data: {
          status: 'accepted',
          acceptedBy: userId,
          acceptedAt: this.clock.now(),
        },
      });
      return { membership, projectId: inv.projectId };
    });
  }
}

function generateNumericCode(length: number): string {
  const min = 10 ** (length - 1);
  const max = 10 ** length;
  return crypto.randomInt(min, max).toString();
}
