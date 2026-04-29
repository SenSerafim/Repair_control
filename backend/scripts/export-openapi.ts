import 'reflect-metadata';
import '../apps/api/src/bootstrap/bigint-serializer';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { AppModule } from '../apps/api/src/app.module';

/**
 * Экспорт OpenAPI v1.0 в backend/docs/openapi.v1.json.
 * Используется мобильной командой для retrofit-codegen + ручной импорт в Postman.
 *
 * Usage: npm run openapi:export
 */
async function main(): Promise<void> {
  process.env.NODE_ENV = process.env.NODE_ENV ?? 'development';
  process.env.REDIS_URL = process.env.REDIS_URL ?? 'redis://localhost:6379';
  process.env.DATABASE_URL =
    process.env.DATABASE_URL ??
    'postgresql://postgres:postgres@localhost:5432/repair_control?schema=public';

  const app = await NestFactory.create(AppModule, { logger: ['warn', 'error'] });
  app.setGlobalPrefix('api', { exclude: ['healthz'] });

  const swagger = new DocumentBuilder()
    .setTitle('Repair Control API')
    .setDescription(
      'OpenAPI v1.x контракт. Источник истины для Flutter retrofit-клиентов. ' +
        'S18 (1.2.0): Knowledge Base, Legal PDFs, broadcast платформа, поддержка-контакты.',
    )
    .setVersion('1.2.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swagger);

  const outPath = path.resolve(__dirname, '..', 'docs', 'openapi.v1.json');
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
