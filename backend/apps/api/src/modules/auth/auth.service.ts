import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { AuthError, Clock, ConflictError, ErrorCodes, PrismaService } from '@app/common';
import { SystemRole } from '@app/rbac';
import { TokenService } from './token.service';

export interface RegisterInput {
  phone: string;
  password: string;
  firstName: string;
  lastName: string;
  role: SystemRole;
  language?: string;
}

export interface LoginInput {
  phone: string;
  password: string;
  deviceId: string;
  ip: string;
  userAgent?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly cfg: ConfigService,
    private readonly clock: Clock,
  ) {}

  /**
   * Регистрация по телефону без SMS (финал ТЗ §1.1).
   * Создаём пользователя с одной ролью и выдаём токены.
   */
  async register(input: RegisterInput): Promise<AuthTokens & { userId: string }> {
    await this.ensurePhoneFree(input.phone);
    const cost = this.cfg.get<number>('BCRYPT_COST', 12);
    const passwordHash = await bcrypt.hash(input.password, cost);

    const user = await this.prisma.user.create({
      data: {
        phone: input.phone,
        passwordHash,
        firstName: input.firstName,
        lastName: input.lastName,
        language: input.language ?? 'ru',
        activeRole: input.role,
        roles: { create: { role: input.role } },
      },
    });

    const tokens = await this.issueSession(user.id, input.role, {
      deviceId: 'initial',
      ip: '0.0.0.0',
    });
    return { userId: user.id, ...tokens };
  }

  async login(input: LoginInput): Promise<AuthTokens & { userId: string; systemRole: SystemRole }> {
    const now = this.clock.now();
    await this.assertNotRateLimited(input.phone, input.ip, now);

    const user = await this.prisma.user.findUnique({
      where: { phone: input.phone },
      include: { roles: true },
    });
    const ok = user ? await bcrypt.compare(input.password, user.passwordHash) : false;

    await this.prisma.loginAttempt.create({
      data: {
        userId: user?.id ?? null,
        phone: input.phone,
        ip: input.ip,
        success: ok,
        createdAt: now,
      },
    });

    if (!user || !ok) {
      throw new AuthError(ErrorCodes.INVALID_CREDENTIALS, 'invalid phone or password');
    }

    const systemRole = user.activeRole as SystemRole;
    const tokens = await this.issueSession(user.id, systemRole, {
      deviceId: input.deviceId,
      ip: input.ip,
      userAgent: input.userAgent,
    });
    await this.prisma.user.update({ where: { id: user.id }, data: { lastSeenAt: now } });
    return { userId: user.id, systemRole, ...tokens };
  }

  async refresh(refreshToken: string, deviceId: string, ip: string): Promise<AuthTokens> {
    let payload: { sub: string; sid: string };
    try {
      payload = await this.tokens.verifyRefresh(refreshToken);
    } catch {
      throw new AuthError(ErrorCodes.TOKEN_INVALID, 'invalid refresh token');
    }
    const session = await this.prisma.session.findUnique({ where: { id: payload.sid } });
    if (!session || session.revokedAt || session.userId !== payload.sub) {
      throw new AuthError(ErrorCodes.SESSION_REVOKED, 'session revoked');
    }
    if (session.expiresAt < this.clock.now()) {
      throw new AuthError(ErrorCodes.TOKEN_EXPIRED, 'session expired');
    }
    const matches = await this.tokens.compareRefresh(refreshToken, session.refreshTokenHash);
    if (!matches) throw new AuthError(ErrorCodes.TOKEN_INVALID, 'refresh mismatch');

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) throw new AuthError(ErrorCodes.TOKEN_INVALID, 'user not found');

    // ротация: инвалидируем старую сессию, создаём новую
    await this.prisma.session.update({
      where: { id: session.id },
      data: { revokedAt: this.clock.now() },
    });
    return this.issueSession(user.id, user.activeRole as SystemRole, { deviceId, ip });
  }

  async logout(refreshToken: string): Promise<void> {
    try {
      const payload = await this.tokens.verifyRefresh(refreshToken);
      await this.prisma.session.updateMany({
        where: { id: payload.sid, revokedAt: null },
        data: { revokedAt: this.clock.now() },
      });
    } catch {
      // тихо — logout идемпотентен
    }
  }

  private async ensurePhoneFree(phone: string): Promise<void> {
    const existing = await this.prisma.user.findUnique({ where: { phone } });
    if (existing) throw new ConflictError(ErrorCodes.PHONE_IN_USE, 'phone already registered');
  }

  private async issueSession(
    userId: string,
    systemRole: SystemRole,
    ctx: { deviceId: string; ip: string; userAgent?: string },
  ): Promise<AuthTokens> {
    const refreshTtl = this.cfg.get<number>('JWT_REFRESH_TTL', 2_592_000);
    const accessTtl = this.cfg.get<number>('JWT_ACCESS_TTL', 900);
    const session = await this.prisma.session.create({
      data: {
        userId,
        refreshTokenHash: 'pending',
        deviceId: ctx.deviceId,
        ipFingerprint: ctx.ip,
        userAgent: ctx.userAgent,
        expiresAt: new Date(this.clock.now().getTime() + refreshTtl * 1000),
      },
    });
    const refreshToken = await this.tokens.signRefresh({ sub: userId, sid: session.id });
    const refreshTokenHash = await this.tokens.hashRefresh(refreshToken);
    await this.prisma.session.update({
      where: { id: session.id },
      data: { refreshTokenHash },
    });
    const accessToken = await this.tokens.signAccess({ sub: userId, systemRole });
    return { accessToken, refreshToken, expiresIn: accessTtl };
  }

  private async assertNotRateLimited(phone: string, ip: string, now: Date): Promise<void> {
    const max = this.cfg.get<number>('RATE_LIMIT_LOGIN_MAX', 5);
    const window = this.cfg.get<number>('RATE_LIMIT_LOGIN_WINDOW_SECONDS', 300);
    const since = new Date(now.getTime() - window * 1000);
    const recent = await this.prisma.loginAttempt.count({
      where: {
        OR: [{ phone }, { ip }],
        success: false,
        createdAt: { gte: since },
      },
    });
    if (recent >= max) {
      throw new AuthError(ErrorCodes.LOGIN_BLOCKED, 'too many failed attempts');
    }
  }
}
