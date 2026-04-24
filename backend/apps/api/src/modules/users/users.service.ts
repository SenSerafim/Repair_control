import { Injectable } from '@nestjs/common';
import {
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { SystemRole } from '@app/rbac';

export interface UpdateProfileInput {
  firstName?: string;
  lastName?: string;
  avatarUrl?: string | null;
  language?: string;
  email?: string | null;
}

export interface RegisterDeviceInput {
  platform: 'ios' | 'android';
  token: string;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { roles: true, devices: true },
    });
    if (!user) throw new NotFoundError(ErrorCodes.ROLE_NOT_FOUND, 'user not found');
    const { passwordHash: _passwordHash, ...safe } = user;
    void _passwordHash;
    return safe;
  }

  async updateProfile(userId: string, input: UpdateProfileInput) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        firstName: input.firstName,
        lastName: input.lastName,
        avatarUrl: input.avatarUrl,
        language: input.language,
        email: input.email,
      },
      select: {
        id: true,
        phone: true,
        email: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        language: true,
        activeRole: true,
      },
    });
  }

  async addRole(userId: string, role: SystemRole) {
    if (role === 'admin') {
      throw new InvalidInputError(ErrorCodes.ROLE_NOT_FOUND, 'admin role cannot be self-assigned');
    }
    const existing = await this.prisma.userRole.findUnique({
      where: { userId_role: { userId, role } },
    });
    if (existing) {
      throw new ConflictError(ErrorCodes.ROLE_ALREADY_HAS, 'user already has this role');
    }
    await this.prisma.userRole.create({ data: { userId, role } });
    return this.listRoles(userId);
  }

  async removeRole(userId: string, role: SystemRole) {
    const all = await this.prisma.userRole.findMany({ where: { userId } });
    const existing = all.find((r) => r.role === role);
    if (!existing) throw new NotFoundError(ErrorCodes.ROLE_NOT_FOUND, 'role not found');
    if (all.length <= 1) {
      throw new InvalidInputError(
        ErrorCodes.ROLE_CANNOT_REMOVE_LAST,
        'cannot remove the last role',
      );
    }
    await this.prisma.userRole.delete({ where: { userId_role: { userId, role } } });

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user?.activeRole === role) {
      const remaining = all.find((r) => r.role !== role)!;
      await this.prisma.user.update({
        where: { id: userId },
        data: { activeRole: remaining.role },
      });
    }
    return this.listRoles(userId);
  }

  async setActiveRole(userId: string, role: SystemRole) {
    const has = await this.prisma.userRole.findUnique({
      where: { userId_role: { userId, role } },
    });
    if (!has) throw new NotFoundError(ErrorCodes.ROLE_NOT_FOUND, 'role not added');
    await this.prisma.user.update({ where: { id: userId }, data: { activeRole: role } });
    return { activeRole: role };
  }

  async listRoles(userId: string) {
    const roles = await this.prisma.userRole.findMany({ where: { userId } });
    return roles.map((r) => ({ role: r.role, addedAt: r.addedAt, isActive: r.isActive }));
  }

  async registerDevice(userId: string, input: RegisterDeviceInput) {
    await this.prisma.deviceToken.upsert({
      where: { token: input.token },
      update: { userId, platform: input.platform, lastSeenAt: new Date() },
      create: { userId, platform: input.platform, token: input.token },
    });
    return { registered: true };
  }
}
