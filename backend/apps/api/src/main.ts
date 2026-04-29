import 'reflect-metadata';
import './bootstrap/bigint-serializer';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger } from 'nestjs-pino';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { AppModule } from './app.module';
import { initSentry } from './bootstrap/sentry';
import { RedisIoAdapter } from './modules/realtime/ws-adapter';

async function bootstrap(): Promise<void> {
  const sentryEnabled = initSentry();

  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));

  app.use(helmet());
  app.use(cookieParser());
  // exclude: только publicPDF-stream (legal/public/<slug>) + системные endpoints.
  // Раньше было exclude: 'legal/(.*)' — это исключало ВСЕ legal/* из /api prefix,
  // включая LegalPublicController.@Get('legal/:kind') (markdown-acceptance).
  // Mobile (auth_repository.dart) и OpenAPI клиент бьют '/api/legal/:kind' —
  // получали 404, пользователь застревал на legal-acceptance модале.
  app.setGlobalPrefix('api', {
    exclude: ['healthz', 'legal/public/(.*)', 'legal/public', 'metrics'],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const wsAdapter = new RedisIoAdapter(app);
  await wsAdapter.init();
  app.useWebSocketAdapter(wsAdapter);

  const swagger = new DocumentBuilder()
    .setTitle('Repair Control API')
    .setDescription(
      [
        'Backend для контроля ремонта — см. `Сводное_ТЗ_и_Спринты.md` и `backend/ARCHITECTURE.md`.',
        '',
        'API contract exceptions (backend/ARCHITECTURE.md#api-contract-exceptions):',
        '- `POST /stages/from-template/:templateId` из ТЗ реализован как `POST /api/templates/:id/apply`.',
        '- `POST /stages/:id/save-as-template` из ТЗ реализован как `POST /api/templates/from-stage/:stageId`.',
        '',
        'S5 additions: WebSocket namespace `/chats` (real-time сообщения), `POST /api/projects/:id/exports` (PDF/ZIP), FCM push через абстракцию NotificationProvider.',
        '',
        'OpenAPI (этот документ) — источник истины для генерации клиентов.',
      ].join('\n'),
    )
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swagger);
  SwaggerModule.setup('api/docs', app, document);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  const logger = app.get(Logger);
  logger.log(
    `API listening on ${port}, docs at /api/docs (sentry=${sentryEnabled ? 'on' : 'off'})`,
    'Bootstrap',
  );
}

bootstrap().catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Bootstrap failed', e);
  process.exit(1);
});
