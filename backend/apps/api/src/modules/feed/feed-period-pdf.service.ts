import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@app/common';
import { FeedService, FeedViewer } from './feed.service';
import { PdfRendererService } from '../exports/pdf-renderer.service';

/**
 * ТЗ NEWFIX §12.4: «отчёт за период» по ленте проекта. Сервис
 * собирает FeedEvent[] за [from..to], резолвит actor'ов одним
 * batched-запросом и рендерит A4 HTML через общий PdfRendererService.
 * Названия событий — глагольные (см. _verbFor), это первый шаг
 * §12.3; полная переработка producer'ов остаётся в backlog.
 */
@Injectable()
export class FeedPeriodPdfService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly renderer: PdfRendererService,
  ) {}

  async render(
    projectId: string,
    viewer: FeedViewer,
    range: { from: Date; to: Date },
  ): Promise<Buffer> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, title: true, address: true },
    });
    if (!project) throw new NotFoundException('project_not_found');

    const events = await this.feed.listForProject(projectId, viewer, {
      from: range.from,
      to: range.to,
      limit: 5000,
    });
    const actorIds = Array.from(
      new Set(events.map((e) => e.actorId).filter((x): x is string => !!x)),
    );
    const actors = actorIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: actorIds } },
          select: { id: true, firstName: true, lastName: true },
        })
      : [];
    const actorMap = new Map(actors.map((a) => [a.id, a]));

    const html = this.buildHtml(project, events, actorMap, range);
    const pdf = await this.renderer.renderHtmlToPdf(html);
    return pdf ?? Buffer.from(html, 'utf8');
  }

  private buildHtml(
    project: { title: string; address: string | null },
    events: Array<{
      createdAt: Date;
      kind: string;
      actorId: string | null;
      payload: unknown;
    }>,
    actors: Map<string, { firstName: string; lastName: string }>,
    range: { from: Date; to: Date },
  ): string {
    const rows =
      events.length === 0
        ? '<tr><td colspan="4" style="text-align:center;color:#94A3B8">Событий за период нет</td></tr>'
        : events
            .map((ev) => {
              const ts = formatDateTime(ev.createdAt);
              const actor = ev.actorId ? actors.get(ev.actorId) : null;
              const actorName = actor
                ? escapeHtml(`${actor.firstName} ${actor.lastName}`.trim())
                : '<span style="color:#94A3B8">—</span>';
              return `<tr>
              <td style="white-space:nowrap">${ts}</td>
              <td>${escapeHtml(verbFor(ev.kind))}</td>
              <td style="white-space:nowrap">${actorName}</td>
              <td style="font-family:monospace;font-size:10px;color:#64748B">${escapeHtml(ev.kind)}</td>
            </tr>`;
            })
            .join('');
    return `<!doctype html>
<html><head><meta charset="utf-8"><title>Лента событий</title>
<style>
  body{font-family:Manrope,Arial,sans-serif;color:#0D1229;font-size:12px;margin:0;padding:0}
  h1{font-size:22px;margin:0 0 4px}
  h2{font-size:14px;margin:0 0 4px;color:#475569}
  .meta{color:#64748B;margin-bottom:18px;font-size:11px}
  table{width:100%;border-collapse:collapse;margin-top:8px}
  td,th{border-bottom:1px solid #E2E8F0;padding:6px 8px;vertical-align:top;text-align:left}
  th{background:#F1F5F9;font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:#475569}
</style></head>
<body>
  <h1>Лента событий</h1>
  <h2>${escapeHtml(project.title)}${project.address ? ` · ${escapeHtml(project.address)}` : ''}</h2>
  <div class="meta">Период: ${formatDate(range.from)} — ${formatDate(range.to)} · всего событий: ${events.length}</div>
  <table>
    <thead><tr><th>Время</th><th>Событие</th><th>Кто</th><th>kind</th></tr></thead>
    <tbody>${rows}</tbody>
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

function formatDateTime(d: Date): string {
  const date = formatDate(d);
  const hh = String(d.getUTCHours()).padStart(2, '0');
  const mn = String(d.getUTCMinutes()).padStart(2, '0');
  return `${date} ${hh}:${mn}`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * ТЗ NEWFIX §12.3: глагольная формулировка для kind'а. Сейчас покрываем
 * только частые события — остальные показываем как «Событие <kind>».
 * Расширим, когда заказчик пройдёт первую итерацию PDF.
 */
function verbFor(kind: string): string {
  const map: Record<string, string> = {
    project_created: 'Проект создан',
    project_archived: 'Проект архивирован',
    project_restored: 'Проект восстановлен',
    project_copied: 'Проект скопирован',
    membership_added: 'Добавлен участник',
    membership_removed: 'Удалён участник',
    membership_left: 'Участник покинул проект',
    stage_created: 'Создан этап',
    stage_started: 'Этап начат',
    stage_paused: 'Этап поставлен на паузу',
    stage_resumed: 'Этап возобновлён',
    stage_sent_to_review: 'Этап отправлен на проверку',
    stage_deadline_recalculated: 'Дедлайн этапа пересчитан',
    stage_deadline_exceeds_project: 'Дедлайн этапа превышает проект',
    stages_reordered: 'Порядок этапов изменён',
    stage_accepted: 'Этап принят заказчиком',
    stage_rejected_by_customer: 'Этап отправлен на доработку',
    stage_pending_approval: 'Этап ожидает согласования',
    step_created: 'Создан шаг',
    step_updated: 'Шаг обновлён',
    step_completed: 'Шаг выполнен',
    step_uncompleted: 'Шаг снят с готовности',
    step_deleted: 'Шаг удалён',
    steps_reordered: 'Порядок шагов изменён',
    extra_work_requested: 'Запрошена доп.работа',
    note_created: 'Создана заметка',
    note_updated: 'Заметка обновлена',
    note_deleted: 'Заметка удалена',
    photo_attached: 'Прикреплено фото',
    photo_deleted: 'Фото удалено',
    approval_requested: 'Запрошено согласование',
    approval_approved: 'Согласование одобрено',
    approval_rejected: 'Согласование отклонено',
    approval_cancelled: 'Согласование отменено',
    approval_resubmitted: 'Согласование повторно отправлено',
    plan_approved: 'План этапов согласован',
    deadline_changed: 'Изменён дедлайн',
    payment_created: 'Создана выплата',
    payment_distributed: 'Выплата распределена',
    material_request_created: 'Создана заявка',
    material_request_sent: 'Заявка отправлена',
    material_request_approved: 'Заявка согласована',
    material_request_cancelled: 'Заявка отменена',
    material_request_accepted_partial: 'Заявка принята частично',
    material_request_accepted_full: 'Заявка принята полностью',
    material_request_overdue: 'Заявка просрочена',
    material_delivered: 'Материал доставлен',
    material_disputed: 'По материалу открыт спор',
    material_resolved: 'Спор по материалу разрешён',
    selfpurchase_created: 'Самозакуп создан',
    selfpurchase_approved: 'Самозакуп согласован',
    selfpurchase_rejected: 'Самозакуп отклонён',
    tool_issued: 'Выдан инструмент',
    tool_returned: 'Инструмент возвращён',
    tool_added_to_project: 'Инструмент добавлен на проект',
    tool_removed_from_project: 'Инструмент снят с проекта',
    tool_custody_changed: 'Передан инструмент',
    chat_message_sent: 'Отправлено сообщение в чат',
    document_uploaded: 'Загружен документ',
    document_deleted: 'Удалён документ',
    budget_updated: 'Обновлён бюджет',
    budget_changed_by_customer: 'Заказчик изменил бюджет',
  };
  return map[kind] ?? `Событие · ${kind}`;
}
