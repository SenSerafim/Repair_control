import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { AuthError, Clock, ErrorCodes, PrismaService } from '@app/common';
import { SmsService } from './sms.service';

@Injectable()
export class RecoveryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sms: SmsService,
    private readonly cfg: ConfigService,
    private readonly clock: Clock,
  ) {}

  /**
   * Шаг 1: инициирование восстановления.
   * Единый ответ «ок» даже если номер не найден — защита от энумерации (ТЗ §5.1).
   */
  async sendCode(phone: string): Promise<{ sent: boolean }> {
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) return { sent: true };

    const code = this.generateCode();
    const expiresAt = new Date(this.clock.now().getTime() + 10 * 60 * 1000); // 10 минут
    await this.prisma.recoveryAttempt.create({
      data: {
        userId: user.id,
        code,
        attempts: 0,
        expiresAt,
      },
    });
    await this.sms.sendRecoveryCode(phone, code);
    return { sent: true };
  }

  /**
   * Шаг 2: проверка кода. 3 неверные попытки → блок 5 минут (ТЗ §3.2 / gaps).
   */
  async verifyCode(phone: string, code: string): Promise<void> {
    const attempt = await this.loadActiveAttempt(phone);
    const maxAttempts = this.cfg.get<number>('RECOVERY_MAX_ATTEMPTS', 3);
    const blockSeconds = this.cfg.get<number>('RECOVERY_BLOCK_SECONDS', 300);
    const now = this.clock.now();

    if (attempt.blockedUntil && attempt.blockedUntil > now) {
      throw new AuthError(ErrorCodes.RECOVERY_BLOCKED, 'recovery temporarily blocked');
    }
    if (attempt.expiresAt < now) {
      throw new AuthError(ErrorCodes.RECOVERY_EXPIRED, 'recovery code expired');
    }

    if (attempt.code !== code) {
      const nextAttempts = attempt.attempts + 1;
      const shouldBlock = nextAttempts >= maxAttempts;
      await this.prisma.recoveryAttempt.update({
        where: { id: attempt.id },
        data: {
          attempts: nextAttempts,
          blockedUntil: shouldBlock ? new Date(now.getTime() + blockSeconds * 1000) : null,
        },
      });
      throw new AuthError(ErrorCodes.RECOVERY_INVALID_CODE, 'invalid code');
    }
  }

  /**
   * Шаг 3: сброс пароля при валидном коде.
   */
  async resetPassword(phone: string, code: string, newPassword: string): Promise<void> {
    await this.verifyCode(phone, code);
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) throw new AuthError(ErrorCodes.RECOVERY_EXPIRED, 'recovery expired');
    const cost = this.cfg.get<number>('BCRYPT_COST', 12);
    const hash = await bcrypt.hash(newPassword, cost);
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: user.id }, data: { passwordHash: hash } }),
      this.prisma.recoveryAttempt.updateMany({
        where: { userId: user.id, isUsed: false },
        data: { isUsed: true },
      }),
      this.prisma.session.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: this.clock.now() },
      }),
    ]);
  }

  private async loadActiveAttempt(phone: string) {
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) throw new AuthError(ErrorCodes.RECOVERY_EXPIRED, 'recovery expired');
    const latest = await this.prisma.recoveryAttempt.findFirst({
      where: { userId: user.id, isUsed: false },
      orderBy: { createdAt: 'desc' },
    });
    if (!latest) throw new AuthError(ErrorCodes.RECOVERY_EXPIRED, 'no active recovery');
    return latest;
  }

  private generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}
