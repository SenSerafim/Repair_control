import { Controller, Get, Headers, Param, Query, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { ConfigService } from '@nestjs/config';
import { FilesService } from '@app/files';
import { InvalidInputError } from '@app/common';
import { LegalPublicationsService } from './legal-publications.service';

const SLUG_PATTERN = /^[a-z0-9][a-z0-9-]{1,79}$/;

/**
 * Публичные PDF-публикации без авторизации. URL вида
 *   https://api.<host>/legal/public/privacy-policy
 *   https://api.<host>/legal/public/privacy-policy.pdf  (тот же контент, для красивого шаринга)
 *
 * Защита от DoS — Cache-Control + ETag/304 (повторные запросы дают 304 без чтения файла из MinIO).
 * Дополнительный rate-limit имеет смысл вынести на nginx (`limit_req_zone`) при production-deploy —
 * на application-level Throttler сейчас не подключён.
 */
@ApiTags('legal-publications-public')
@Controller('legal/public')
export class LegalPublicationsPublicController {
  constructor(
    private readonly svc: LegalPublicationsService,
    private readonly files: FilesService,
    private readonly config: ConfigService,
  ) {}

  @Get(':slug')
  async stream(
    @Param('slug') rawSlug: string,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Query('download') download: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const slug = this.normalizeSlug(rawSlug);
    const pub = await this.svc.getActiveBySlug(slug);

    const ttl = this.config.get<number>('LEGAL_PUBLIC_CACHE_TTL_SECONDS', 3600);
    const etagHeader = `"${pub.etag}"`;

    res.setHeader('ETag', etagHeader);
    res.setHeader('Cache-Control', `public, max-age=${ttl}, stale-while-revalidate=86400`);
    res.setHeader('X-Content-Type-Options', 'nosniff');

    if (ifNoneMatch && ifNoneMatch.replace(/^W\//, '').trim() === etagHeader) {
      res.status(304).end();
      return;
    }

    res.setHeader('Content-Type', pub.mimeType || 'application/pdf');
    res.setHeader('Content-Length', String(pub.sizeBytes));
    const filename = `${pub.slug}.pdf`;
    const dispositionType = download === '1' ? 'attachment' : 'inline';
    res.setHeader('Content-Disposition', `${dispositionType}; filename="${filename}"`);

    const stream = await this.files.streamObject(pub.fileKey);
    stream.on('error', (err) => {
      res.destroy(err);
    });
    stream.pipe(res);
  }

  private normalizeSlug(raw: string): string {
    const trimmed = raw.toLowerCase().replace(/\.pdf$/, '');
    if (!SLUG_PATTERN.test(trimmed)) {
      throw new InvalidInputError('legal_publications.invalid_slug', `invalid slug: ${raw}`);
    }
    return trimmed;
  }
}
