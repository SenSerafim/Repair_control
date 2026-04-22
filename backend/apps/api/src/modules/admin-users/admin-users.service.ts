import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { ConfigService } from '@nestjs/config';
import { randomBytes } from 'crypto';
import { Prisma, SystemRole } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
    private readonly cfg: ConfigService,
  ) {}

  async list(
    filters: {
      q?: string;
      role?: SystemRole;
      banned?: boolean;
      limit?: number;
      offset?: number;
    } = {},
  ) {
    const where: Prisma.UserWhereInput = {
      ...(filters.role ? { roles: { some: { role: filters.role } } } : {}),
      ...(filters.banned === true ? { bannedAt: { not: null } } : {}),
      ...(filters.banned === false ? { bannedAt: null } : {}),
      ...(filters.q
        ? {
            OR: [
              { phone: { contains: filters.q, mode: 'insensitive' } },
              { email: { contains: filters.q, mode: 'insensitive' } },
              { firstName: { contains: filters.q, mode: 'insensitive' } },
              { lastName: { contains: filters.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(filters.limit ?? 50, 200),
        skip: filters.offset ?? 0,
        select: {
          id: true,
          phone: true,
          email: true,
          firstName: true,
          lastName: true,
          activeRole: true,
          bannedAt: true,
          banReason: true,
          lastSeenAt: true,
          createdAt: true,
          roles: { select: { role: true, isActive: true, addedAt: true } },
          _count: {
            select: { sessions: true, devices: true, ownedProjects: true, memberships: true },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { items, total };
  }

  async detail(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        roles: true,
        devices: true,
        sessions: {
          where: { revokedAt: null },
          select: {
            id: true,
            deviceId: true,
            ipFingerprint: true,
            createdAt: true,
            expiresAt: true,
          },
        },
        _count: { select: { ownedProjects: true, memberships: true } },
      },
    });
    if (!user) throw new NotFoundError(ErrorCodes.USER_NOT_FOUND, 'user not found');
    return user;
  }

  async ban(targetId: string, actorId: string, reason: string) {
    if (targetId === actorId) {
      throw new ForbiddenError(ErrorCodes.USER_CANNOT_BAN_SELF, 'cannot ban yourself');
    }
    const u = await this.prisma.user.findUnique({
      where: { id: targetId },
      include: { roles: true },
    });
    if (!u) throw new NotFoundError(ErrorCodes.USER_NOT_FOUND, 'user not found');
    if (u.roles.some((r) => r.role === 'admin')) {
      throw new ForbiddenError(ErrorCodes.USER_CANNOT_BAN_ADMIN, 'cannot ban admin user');
    }
    if (u.bannedAt) {
      throw new ConflictError(ErrorCodes.USER_ALREADY_BANNED, 'user already banned');
    }
    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.user.update({
        where: { id: targetId },
        data: { bannedAt: now, banReason: reason },
      });
      // force-logout: отзываем все активные сессии
      await tx.session.updateMany({
        where: { userId: targetId, revokedAt: null },
        data: { revokedAt: now },
      });
      return result;
    });
    await this.audit.log({
      actorId,
      action: 'user.ban',
      targetType: 'User',
      targetId,
      metadata: { reason },
    });
    return { id: updated.id, bannedAt: updated.bannedAt, banReason: updated.banReason };
  }

  async unban(targetId: string, actorId: string) {
    const u = await this.prisma.user.findUnique({ where: { id: targetId } });
    if (!u) throw new NotFoundError(ErrorCodes.USER_NOT_FOUND, 'user not found');
    if (!u.bannedAt) {
      throw new ConflictError(ErrorCodes.USER_NOT_BANNED, 'user is not banned');
    }
    await this.prisma.user.update({
      where: { id: targetId },
      data: { bannedAt: null, banReason: null },
    });
    await this.audit.log({ actorId, action: 'user.unban', targetType: 'User', targetId });
    return { id: targetId, bannedAt: null };
  }

  async resetPassword(targetId: string, actorId: string) {
    const u = await this.prisma.user.findUnique({ where: { id: targetId } });
    if (!u) throw new NotFoundError(ErrorCodes.USER_NOT_FOUND, 'user not found');
    const tempPassword = randomBytes(8).toString('base64url');
    const cost = this.cfg.get<number>('BCRYPT_COST', 12);
    const passwordHash = await bcrypt.hash(tempPassword, cost);
    const now = this.clock.now();
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: targetId }, data: { passwordHash } }),
      this.prisma.session.updateMany({
        where: { userId: targetId, revokedAt: null },
        data: { revokedAt: now },
      }),
    ]);
    await this.audit.log({
      actorId,
      action: 'user.reset_password',
      targetType: 'User',
      targetId,
    });
    // Возвращаем временный пароль только в ответе admin (в реальной прод-среде — отправить через SMS).
    return { id: targetId, tempPassword };
  }

  async forceLogout(targetId: string, actorId: string) {
    const u = await this.prisma.user.findUnique({ where: { id: targetId } });
    if (!u) throw new NotFoundError(ErrorCodes.USER_NOT_FOUND, 'user not found');
    const now = this.clock.now();
    const result = await this.prisma.session.updateMany({
      where: { userId: targetId, revokedAt: null },
      data: { revokedAt: now },
    });
    await this.audit.log({
      actorId,
      action: 'user.force_logout',
      targetType: 'User',
      targetId,
      metadata: { revokedSessions: result.count },
    });
    return { revokedSessions: result.count };
  }

  async setRoles(targetId: string, actorId: string, roles: SystemRole[]) {
    const u = await this.prisma.user.findUnique({ where: { id: targetId } });
    if (!u) throw new NotFoundError(ErrorCodes.USER_NOT_FOUND, 'user not found');
    const normalized = Array.from(new Set(roles));
    if (normalized.length === 0) {
      throw new ConflictError(ErrorCodes.ROLE_CANNOT_REMOVE_LAST, 'must have at least one role');
    }
    await this.prisma.$transaction(async (tx) => {
      // стираем лишние
      await tx.userRole.deleteMany({
        where: { userId: targetId, role: { notIn: normalized } },
      });
      // добавляем новые
      for (const r of normalized) {
        await tx.userRole.upsert({
          where: { userId_role: { userId: targetId, role: r } },
          create: { userId: targetId, role: r },
          update: { isActive: true },
        });
      }
      // Если activeRole больше не в списке — переключаем на первую
      if (!normalized.includes(u.activeRole)) {
        await tx.user.update({ where: { id: targetId }, data: { activeRole: normalized[0] } });
      }
    });
    await this.audit.log({
      actorId,
      action: 'user.set_roles',
      targetType: 'User',
      targetId,
      metadata: { roles: normalized },
    });
    return { id: targetId, roles: normalized };
  }

  async getUserAudit(targetId: string) {
    return this.prisma.adminAuditLog.findMany({
      where: { targetType: 'User', targetId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }
}
