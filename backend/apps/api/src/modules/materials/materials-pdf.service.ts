import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@app/common';
import { PdfRendererService } from '../exports/pdf-renderer.service';

/**
 * ТЗ NEWFIX §5.3 — «Сформировать PDF» по заявке. Бригадир/заказчик
 * собрал список, нажал кнопку, получил A4-документ для магазина:
 * шапка проекта, заголовок заявки, таблица позиций (Название / Кол-во /
 * Срок поставки / Цена / Сумма), итог. HTML-шаблон — inline, без
 * внешних ассетов: puppeteer-launch в staging без интернета.
 */
@Injectable()
export class MaterialsPdfService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly renderer: PdfRendererService,
  ) {}

  async renderForRequest(
    requestId: string,
  ): Promise<{ buffer: Buffer; mime: string; ext: string }> {
    const request = await this.prisma.materialRequest.findUnique({
      where: { id: requestId },
      include: {
        items: { orderBy: { createdAt: 'asc' } },
        project: { select: { title: true, address: true } },
        stage: { select: { title: true, orderIndex: true } },
      },
    });
    if (!request) throw new NotFoundException('material_request not found');
    const html = this.buildHtml(request);
    const pdf = await this.renderer.renderHtmlToPdf(html);
    if (pdf) return { buffer: pdf, mime: 'application/pdf', ext: 'pdf' };
    // Серафим 08.06.2026: если puppeteer недоступен (staging без интернета),
    // отдаём HTML с честным mime. Раньше отдавали HTML под видом PDF —
    // получался «кривой» файл, мобилка не могла открыть.
    return { buffer: Buffer.from(html, 'utf8'), mime: 'text/html; charset=utf-8', ext: 'html' };
  }

  private buildHtml(req: {
    title: string;
    createdAt: Date;
    status: string;
    project: { title: string; address: string | null };
    stage: { title: string; orderIndex: number } | null;
    items: Array<{
      name: string;
      qty: { toString(): string };
      unit: string | null;
      dueDate: Date | null;
      pricePerUnit: bigint | null;
      totalPrice: bigint | null;
    }>;
  }): string {
    const rows = req.items
      .map((it) => {
        const qty = `${it.qty} ${escapeHtml(it.unit ?? 'шт')}`;
        const due = it.dueDate ? formatDate(it.dueDate) : '<span style="color:#94A3B8">—</span>';
        const price = it.pricePerUnit
          ? formatRub(it.pricePerUnit)
          : '<span style="color:#94A3B8">—</span>';
        const sum = it.totalPrice
          ? formatRub(it.totalPrice)
          : '<span style="color:#94A3B8">—</span>';
        return `<tr>
        <td>${escapeHtml(it.name)}</td>
        <td style="white-space:nowrap">${qty}</td>
        <td style="white-space:nowrap">${due}</td>
        <td style="text-align:right;white-space:nowrap">${price}</td>
        <td style="text-align:right;white-space:nowrap">${sum}</td>
      </tr>`;
      })
      .join('');
    const totalSum = req.items.reduce((acc, it) => acc + (it.totalPrice ?? 0n), 0n);
    const stageLabel = req.stage
      ? `Этап ${req.stage.orderIndex + 1} · ${escapeHtml(req.stage.title)}`
      : 'Общая заявка проекта';
    return `<!doctype html>
<html><head><meta charset="utf-8"><title>${escapeHtml(req.title)}</title>
<style>
  body{font-family:Manrope,Arial,sans-serif;color:#0D1229;font-size:12px;margin:0;padding:0}
  h1{font-size:22px;margin:0 0 4px}
  h2{font-size:14px;margin:0 0 4px;color:#475569}
  .meta{color:#64748B;margin-bottom:18px;font-size:11px}
  .meta span{margin-right:14px}
  table{width:100%;border-collapse:collapse;margin-top:8px}
  td,th{border-bottom:1px solid #E2E8F0;padding:8px 10px;vertical-align:top;text-align:left}
  th{background:#F1F5F9;font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:#475569}
  tfoot td{border:none;border-top:2px solid #0D1229;font-weight:800;padding-top:10px}
</style></head>
<body>
  <h1>${escapeHtml(req.title)}</h1>
  <h2>${escapeHtml(req.project.title)}${req.project.address ? ` · ${escapeHtml(req.project.address)}` : ''}</h2>
  <div class="meta">
    <span>${stageLabel}</span>
    <span>Создана: ${formatDate(req.createdAt)}</span>
    <span>Статус: ${escapeHtml(req.status)}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th>Позиция</th>
        <th>Кол-во</th>
        <th>Срок</th>
        <th style="text-align:right">Цена</th>
        <th style="text-align:right">Сумма</th>
      </tr>
    </thead>
    <tbody>${rows || '<tr><td colspan="5" style="text-align:center;color:#94A3B8">Позиций нет</td></tr>'}</tbody>
    <tfoot>
      <tr>
        <td colspan="4" style="text-align:right">Итого</td>
        <td style="text-align:right">${formatRub(totalSum)}</td>
      </tr>
    </tfoot>
  </table>
</body></html>`;
  }
}

function formatDate(d: Date): string {
  const dd = String(d.getUTCDate()).padStart(2, '0');
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
  const yyyy = d.getUTCFullYear();
  return `${dd}.${mm}.${yyyy}`;
}

function formatRub(kop: bigint): string {
  const sign = kop < 0n ? '-' : '';
  const abs = kop < 0n ? -kop : kop;
  const rub = abs / 100n;
  const cents = abs % 100n;
  const rubStr = rub.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  const centsStr = cents.toString().padStart(2, '0');
  return `${sign}${rubStr},${centsStr} ₽`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
