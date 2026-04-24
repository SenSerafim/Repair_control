import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, from } from 'rxjs';
import { switchMap, tap, catchError } from 'rxjs/operators';
import { InvalidInputError, ErrorCodes } from '@app/common';
import { IdempotencyService } from './idempotency.service';

/**
 * Читает Idempotency-Key из заголовка; если есть запись в БД — возвращает сохранённый ответ,
 * иначе бронирует ключ и после успешного ответа записывает тело + status.
 * На исключении — сбрасывает stub, чтобы клиент мог повторить запрос.
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(private readonly service: IdempotencyService) {}

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = ctx.switchToHttp();
    const req = http.getRequest<any>();
    const res = http.getResponse<any>();
    const headerKey = (req.headers['idempotency-key'] as string | undefined)?.trim();
    if (!headerKey) {
      throw new InvalidInputError(
        'idempotency.header_required',
        'Idempotency-Key header is required',
      );
    }
    const user = req.user as { userId?: string } | undefined;
    if (!user?.userId) {
      throw new InvalidInputError(
        ErrorCodes.IDEMPOTENCY_MISSING_USER,
        'Idempotency requires authenticated user',
      );
    }

    const endpoint = `${req.method}:${req.route?.path ?? req.originalUrl}`;
    const composite = this.service.composeKey(user.userId, endpoint, headerKey);
    const requestHash = this.service.hashRequest(req.body);

    return from(
      this.service.reserve({
        key: composite,
        userId: user.userId,
        endpoint,
        requestHash,
      }),
    ).pipe(
      switchMap((result) => {
        if ('replay' in result) {
          res.status(result.statusCode);
          return from(Promise.resolve(result.response));
        }
        if ('inFlight' in result) {
          throw new InvalidInputError(
            'idempotency.in_flight',
            'request with this key is being processed',
          );
        }
        return next.handle().pipe(
          tap(async (body) => {
            const statusCode = res.statusCode ?? 200;
            await this.service.persistResponse(composite, statusCode, body);
          }),
          catchError(async (err) => {
            await this.service.releaseOnError(composite);
            throw err;
          }),
        );
      }),
    );
  }
}
