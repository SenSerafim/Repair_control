import 'reflect-metadata';
import '../apps/api/src/bootstrap/bigint-serializer';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { AppModule } from '../apps/api/src/app.module';

/**
 * Экспорт OpenAPI v2.0-draft в backend/docs/openapi.v2-draft.json.
 *
 * NEWFIX (S19+): breaking — расширение MaterialRequestStatus до 6 значений
 * (+accepted_partial/_full), новые эндпоинты /materials/:id/{mark-delivered,
 * accept-partial,accept-full,export-pdf}, новые FeedEventKind / NotificationKind
 * для частичной приёмки и просрочек.
 *
 * Старый openapi.v1.json остаётся как исторический снимок 1.2.0
 * (S18 freeze, без NEWFIX-изменений).
 *
 * Usage: npm run openapi:export
 */
async function main(): Promise<void> {
  process.env.NODE_ENV = process.env.NODE_ENV ?? 'development';
  process.env.REDIS_URL = process.env.REDIS_URL ?? 'redis://localhost:6379';
  process.env.DATABASE_URL =
    process.env.DATABASE_URL ??
    'postgresql://postgres:postgres@localhost:5435/repair_control?schema=public';

  const app = await NestFactory.create(AppModule, { logger: ['warn', 'error'] });
  app.setGlobalPrefix('api', { exclude: ['healthz'] });

  const swagger = new DocumentBuilder()
    .setTitle('Repair Control API')
    .setDescription(
      'OpenAPI v2.x-draft контракт. Источник истины для Flutter retrofit-клиентов. ' +
        'S19+ (NEWFIX, роль «Заказчик»): расширение FSM заявок (частичная/полная ' +
        'приёмка), фото и дедлайн позиций, PDF-экспорт заявки, cron для overdue. ' +
        'E11 (2.1.0): заметки проекта с аудио — поля kind/audioKey/audioMimeType/' +
        'audioDurationMs + transcript-задел для варианта B (фоновый STT).',
    )
    .setVersion('2.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swagger);

  const outPath = path.resolve(__dirname, '..', 'docs', 'openapi.v2-draft.json');
  fs.writeFileSync(outPath, JSON.stringify(document, null, 2), 'utf-8');
  const endpointCount = Object.values(document.paths).reduce(
    (acc, item: any) =>
      acc +
      Object.keys(item).filter((k) => ['get', 'post', 'put', 'patch', 'delete'].includes(k)).length,
    0,
  );
  console.log(`OpenAPI v1.0 exported to ${outPath}`);
  console.log(`Total endpoints: ${endpointCount}`);

  await app.close();
}

main().catch((e) => {
  console.error('export-openapi failed:', e);
  process.exit(1);
});
