import { Injectable, Logger } from '@nestjs/common';

/**
 * Рендер PDF ленты через puppeteer-core + @sparticuz/chromium.
 * В тестах перекрывается через mock (renderFeedPdf возвращает простой Buffer).
 */
@Injectable()
export class PdfRendererService {
  private readonly logger = new Logger(PdfRendererService.name);

  async renderFeedPdf(data: {
    projectTitle: string;
    projectAddress: string | null;
    ownerName: string;
    events: Array<{
      createdAt: Date;
      kind: string;
      actorId: string | null;
      payload: Record<string, unknown>;
    }>;
    pdfLogoUrl?: string;
  }): Promise<Buffer> {
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const chromium = require('@sparticuz/chromium');
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const puppeteer = require('puppeteer-core');
      const html = this.buildHtml(data);
      const browser = await puppeteer.launch({
        args: chromium.args,
        defaultViewport: chromium.defaultViewport,
        executablePath: await chromium.executablePath(),
        headless: true,
      });
      try {
        const page = await browser.newPage();
        await page.setContent(html, { waitUntil: 'networkidle0' });
        const buffer = (await page.pdf({
          format: 'A4',
          printBackground: true,
          margin: { top: '12mm', bottom: '12mm', left: '12mm', right: '12mm' },
        })) as Buffer;
        return buffer;
      } finally {
        await browser.close();
      }
    } catch (e) {
      this.logger.warn(
        `puppeteer unavailable, falling back to plain text: ${(e as Error).message}`,
      );
      return this.fallbackText(data);
    }
  }

  private buildHtml(data: Parameters<PdfRendererService['renderFeedPdf']>[0]): string {
    const title = `Отчёт: ${escapeHtml(data.projectTitle)}`;
    const rows = data.events
      .map((ev) => {
        const ts = ev.createdAt.toISOString().replace('T', ' ').slice(0, 19);
        const kind = escapeHtml(ev.kind);
        const payloadJson = escapeHtml(JSON.stringify(ev.payload));
        return `<tr><td style="white-space:nowrap">${ts}</td><td>${kind}</td><td><pre style="white-space:pre-wrap;margin:0;font-size:10px">${payloadJson}</pre></td></tr>`;
      })
      .join('');
    return `<!doctype html>
<html><head><meta charset="utf-8"><title>${title}</title>
<style>
  body{font-family:Manrope,Arial,sans-serif;color:#0D1229;font-size:12px}
  h1{font-size:20px;margin:0 0 4px}
  .meta{color:#556;margin-bottom:16px}
  table{width:100%;border-collapse:collapse}
  td,th{border-bottom:1px solid #E3E8F1;padding:6px 8px;vertical-align:top;text-align:left}
  th{background:#EEF2FF}
</style></head>
<body>
  <h1>${title}</h1>
  <div class="meta">Адрес: ${escapeHtml(data.projectAddress ?? '—')} · Владелец: ${escapeHtml(data.ownerName)}</div>
  <table><thead><tr><th>Время (UTC)</th><th>Событие</th><th>Payload</th></tr></thead>
  <tbody>${rows || '<tr><td colspan="3">Событий нет</td></tr>'}</tbody></table>
</body></html>`;
  }

  private fallbackText(data: Parameters<PdfRendererService['renderFeedPdf']>[0]): Buffer {
    const lines: string[] = [];
    lines.push(`# ${data.projectTitle}`);
    lines.push(`Адрес: ${data.projectAddress ?? '—'}`);
    lines.push(`Владелец: ${data.ownerName}`);
    lines.push('');
    for (const ev of data.events) {
      const ts = ev.createdAt.toISOString();
      lines.push(`${ts}  ${ev.kind}  ${JSON.stringify(ev.payload)}`);
    }
    return Buffer.from(lines.join('\n'), 'utf-8');
  }
}

function escapeHtml(s: string): string {
  return s.replace(
    /[&<>"']/g,
    (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c] as string,
  );
}
