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
      this.logger.log(`[STUB SMS] ${phone} → code ${code}`);
      return;
    }
    // В следующих итерациях: вызов провайдера с API_KEY из конфига.
    this.logger.warn(`SMS provider ${provider} not implemented, falling back to stub`);
  }
}
