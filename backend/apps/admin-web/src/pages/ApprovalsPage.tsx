import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

const STATUSES = ['pending', 'approved', 'rejected', 'cancelled'];
const STATUS_LABELS: Record<string, string> = {
  pending: 'pending — ждёт ответа',
  approved: 'approved — согласовано',
  rejected: 'rejected — отклонено',
  cancelled: 'cancelled — отменено инициатором',
};

const SCOPES = ['plan', 'step', 'extra_work', 'deadline_change', 'stage_accept'];
const SCOPE_LABELS: Record<string, string> = {
  plan: 'plan — утверждение плана этапа',
  step: 'step — приёмка отдельного шага',
  extra_work: 'extra_work — доп.работа (увеличение бюджета)',
  deadline_change: 'deadline_change — перенос дедлайна',
  stage_accept: 'stage_accept — приёмка этапа целиком',
};

export function ApprovalsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState('');
  const [scope, setScope] = useState('');
  const [projectId, setProjectId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listApprovals({
        status: status || undefined,
        scope: scope || undefined,
        projectId: projectId || undefined,
        limit: 100,
      });
      setItems(r.items);
      setTotal(r.total);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const statusBadge = (s: string) =>
    s === 'approved'
      ? 'green'
      : s === 'rejected'
        ? 'red'
        : s === 'cancelled'
          ? 'gray'
          : 'yellow';

  return (
    <div>
      <PageHelp
        storageKey="approvals"
        title="Согласования"
        summary="Все запросы на согласование между ролями. FSM: pending → approved/rejected/cancelled. Если запрос отклонили, бригадир может пересоздать его — счётчик попыток (attemptNumber) увеличится."
        bullets={[
          '5 типов (scope): plan — утверждение плана этапа; step — приёмка шага; extra_work — доп.работа (бюджет растёт только после approved); deadline_change — перенос дедлайна; stage_accept — приёмка этапа целиком.',
          'Заказчик не может одобрять напрямую то, что должен сначала проверить бригадир (правило из gaps §3.3) — backend это валидирует на уровне FSM.',
          'Поле «Попытка» — это attemptNumber: сколько раз ту же сущность отправляли на согласование (увеличивается после rejected → пересоздание).',
          'Эта страница read-only: модерация согласований происходит в мобайле. Здесь — для разбора инцидентов и аналитики.',
        ]}
      />
      <div className="filters">
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">Все статусы</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {STATUS_LABELS[s] ?? s}
            </option>
          ))}
        </select>
        <select value={scope} onChange={(e) => setScope(e.target.value)}>
          <option value="">Все типы</option>
          {SCOPES.map((s) => (
            <option key={s} value={s}>
              {SCOPE_LABELS[s] ?? s}
            </option>
          ))}
        </select>
        <input
          placeholder="UUID проекта"
          value={projectId}
          onChange={(e) => setProjectId(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <button onClick={reload}>Применить</button>
        <span className="muted">Всего: {total}</span>
      </div>
      {error && <div className="error">{error}</div>}
      {loading ? (
        <div className="muted">Загрузка…</div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Тип</th>
              <th>Статус</th>
              <th>Попытка</th>
              <th>От кого</th>
              <th>Кому</th>
              <th>Проект</th>
              <th>Создано</th>
            </tr>
          </thead>
          <tbody>
            {items.map((a) => (
              <tr key={a.id}>
                <td>
                  <span className="badge blue">{a.scope}</span>
                </td>
                <td>
                  <span className={`badge ${statusBadge(a.status)}`}>
                    {a.status}
                  </span>
                </td>
                <td>#{a.attemptNumber}</td>
                <td>
                  {a.requestedBy
                    ? `${a.requestedBy.firstName} ${a.requestedBy.lastName}`
                    : a.requestedById}
                </td>
                <td>
                  {a.addressee
                    ? `${a.addressee.firstName} ${a.addressee.lastName}`
                    : a.addresseeId}
                </td>
                <td>{a.project?.title ?? a.projectId}</td>
                <td className="muted">
                  {new Date(a.createdAt).toLocaleString()}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="muted" style={{ textAlign: 'center' }}>
                  Нет согласований
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
