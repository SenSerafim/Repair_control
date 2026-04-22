import { LoggerModule } from 'nestjs-pino';
import { randomUUID } from 'crypto';

/**
 * pino logger с redact чувствительных полей + x-request-id middleware.
 * В dev с LOG_PRETTY=true — включаем pino-pretty.
 */
export const loggerModule = LoggerModule.forRootAsync({
  useFactory: () => {
    const level = process.env.LOG_LEVEL ?? 'info';
    const pretty = process.env.LOG_PRETTY === 'true';
    return {
      pinoHttp: {
        level,
        genReqId: (req, res) => {
          const id = req.headers['x-request-id'];
          const requestId = typeof id === 'string' && id.length > 0 ? id : randomUUID();
          res.setHeader('x-request-id', requestId);
          return requestId;
        },
        redact: {
          paths: [
            'req.headers.authorization',
            'req.headers.cookie',
            'req.body.password',
            'req.body.newPassword',
            'req.body.accessToken',
            'req.body.refreshToken',
            'req.body.token',
            'req.body.idempotencyKey',
            'req.body.fcmPrivateKey',
          ],
          censor: '[redacted]',
        },
        transport: pretty
          ? {
              target: 'pino-pretty',
              options: { singleLine: true, translateTime: 'SYS:standard' },
            }
          : undefined,
        customProps: (req) => ({
          userId: (req as any).user?.userId,
        }),
      },
    };
  },
});
