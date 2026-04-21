import 'reflect-metadata';
import './bootstrap/bigint-serializer';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  app.use(helmet());
  app.use(cookieParser());
  app.setGlobalPrefix('api', { exclude: ['healthz'] });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

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
        'OpenAPI (этот документ) — источник истины для генерации клиентов.',
      ].join('\n'),
    )
    .setVersion('0.3.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swagger);
  SwaggerModule.setup('api/docs', app, document);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  Logger.log(`API listening on ${port}, docs at /api/docs`, 'Bootstrap');
}

bootstrap().catch((e) => {
  // eslint-disable-next-line no-console
  console.error('Bootstrap failed', e);
  process.exit(1);
});
