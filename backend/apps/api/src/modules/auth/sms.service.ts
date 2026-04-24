import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * SMS-провайдер (ТЗ §3.1: SMSC.ru / SMS Aero / Stream Telecom).
 * На старте — stub: код не отправляется, а логируется (для dev/test).
 * В прод конфиге SMS_PROVIDER=smsc|smsaero|stream активирует реальную интеграцию.
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(private readonly cfg: ConfigService) {}

  async sendRecoveryCode(phone: string, code: string): Promise<void> {
    const provider = this.cfg.get<string>('SMS_PROVIDER', 'stub');
    if (provider === 'stub') {
      const stubCode = this.cfg.get<string>('SMS_STUB_CODE', '123456');
      this.logger.warn(
        `╔══════════════════════════════════════════════════╗\n` +
          `║ [SMS STUB — реальный SMS не отправлен]           ║\n` +
          `║ phone:  ${phone.padEnd(41)} ║\n` +
          `║ code:   ${code.padEnd(41)} ║\n` +
          `║ accept: ${stubCode.padEnd(41)} ║\n` +
          `╚══════════════════════════════════════════════════╝`,
      );
      return;
    }
    // В следующих итерациях: вызов провайдера с API_KEY из конфига.
    this.logger.warn(`SMS provider ${provider} not implemented, falling back to stub`);
  }
}
