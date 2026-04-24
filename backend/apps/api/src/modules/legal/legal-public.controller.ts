import { Controller, Get, Param, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { LegalKind } from '@prisma/client';
import { InvalidInputError } from '@app/common';
import { LegalService } from './legal.service';

/**
 * Публичные endpoints юр.документов — БЕЗ авторизации, прямые ссылки для браузера.
 * `/legal/privacy`, `/legal/tos`, `/legal/data_processing_consent` — HTML-страница или JSON по Accept.
 * Эти URL не имеют префикса `/api` — они для прямых ссылок из приложения или браузера.
 */
@ApiTags('legal-public')
@Controller('legal')
export class LegalPublicController {
  constructor(private readonly svc: LegalService) {}

  @Get(':kind')
  async render(@Param('kind') kindRaw: string, @Res() res: Response): Promise<void> {
    const kind = this.parseKind(kindRaw);
    const doc = await this.svc.renderPublic(kind);
    const accept = (res.req.headers.accept ?? '').toString();
    const wantsJson = accept.includes('application/json');

    if (wantsJson) {
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.send({
        kind,
        title: doc.title,
        version: doc.version,
        publishedAt: doc.publishedAt,
        bodyMd: doc.bodyMd,
      });
      return;
    }

    // Простая HTML-обёртка (без внешних зависимостей). Markdown → plain-text с <pre>.
    const safe = doc.bodyMd.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>${doc.title}</title>
  <style>
    body { font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif; max-width: 720px; margin: 40px auto; padding: 0 16px; color:#0D1229; line-height:1.55; }
    h1 { font-size: 28px; margin: 0 0 4px; }
    .meta { color: #667; font-size: 14px; margin-bottom: 24px; }
    pre { white-space: pre-wrap; word-wrap: break-word; font-family: inherit; font-size: 15px; }
  </style>
</head>
<body>
  <h1>${doc.title}</h1>
  <div class="meta">Версия ${doc.version}${doc.publishedAt ? ' · опубликовано ' + new Date(doc.publishedAt).toLocaleDateString('ru-RU') : ''}</div>
  <pre>${safe}</pre>
</body>
</html>`);
  }

  @Get(':kind/versions')
  listVersions(@Param('kind') kindRaw: string) {
    const kind = this.parseKind(kindRaw);
    return this.svc.listVersions(kind);
  }

  private parseKind(raw: string): LegalKind {
    const valid = ['privacy', 'tos', 'data_processing_consent'];
    if (!valid.includes(raw)) {
      throw new InvalidInputError('legal.invalid_kind', `invalid kind: ${raw}`);
    }
    return raw as LegalKind;
  }
}
