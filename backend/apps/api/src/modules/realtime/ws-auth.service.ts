import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '@app/common';

export interface WsUser {
  userId: string;
  systemRole: string;
}

/**
 * Проверяет JWT при handshake socket.io. Возвращает { userId, systemRole } или null.
 * Используется в ChatsGateway.handleConnection.
 */
@Injectable()
export class WsAuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async verify(tokenRaw: string | undefined): Promise<WsUser | null> {
    if (!tokenRaw) return null;
    const token = tokenRaw.replace(/^Bearer\s+/i, '').trim();
    if (!token) return null;
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string; role?: string }>(token, {
        secret: process.env.JWT_ACCESS_SECRET,
      });
      if (!payload?.sub) return null;
      // Минимальная проверка — пользователь существует
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, activeRole: true },
      });
      if (!user) return null;
      return { userId: user.id, systemRole: user.activeRole };
    } catch {
      return null;
    }
  }
}
