import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

const STATUSES = [
  'pending',
  'active',
  'paused',
  'review',
  'done',
  'rejected',
  'overdue',
];

const STATUS_LABELS: Record<string, string> = {
  pending: 'pending — ожидает старта',
  active: 'active — в работе',
  paused: 'paused — на паузе',
  review: 'review — на согласовании заказчика',
  done: 'done — принят',
  rejected: 'rejected — заказчик отклонил',
  overdue: 'overdue — просрочен',
};

export function StagesPage() {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState('');
  const [projectId, setProjectId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listStages({
        status: status || undefined,
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
    s === 'done'
      ? 'green'
      : s === 'rejected' || s === 'overdue'
        ? 'red'
        : s === 'review'
          ? 'blue'
          : s === 'paused'
            ? 'yellow'
            : 'gray';

  return (
    <div>
      <PageHelp
        storageKey="stages"
        title="Этапы проектов"
        summary="Список этапов (Stage) по всем проектам. Этап — это блок работ внутри проекта (например, «Демонтаж»). Имеет собственный прогресс и статус из 7 состояний."
        bullets={[
          'Статусы: pending → active → review → done. Из active можно уйти в paused (с обязательной причиной), из review — в rejected (заказчик отклонил приёмку), любое незакрытое состояние при просрочке дедлайна — overdue.',
          'Прогресс (progressCache) — материализованный показатель, считается фоновым cron каждые 15 минут плюс при изменении шагов/паузы/дедлайна.',
          'Шагов — количество дочерних Step внутри этапа. Шаги — самый мелкий уровень декомпозиции работ.',
          'Фильтр Project ID — UUID проекта; без фильтра показываются этапы всех проектов.',
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
              <th>Название</th>
              <th>Статус</th>
              <th>Прогресс</th>
              <th>Шагов</th>
              <th>Проект</th>
              <th>Старт</th>
              <th>Дедлайн</th>
            </tr>
          </thead>
          <tbody>
            {items.map((s) => (
              <tr key={s.id}>
                <td>
                  <strong>{s.title}</strong>
                </td>
                <td>
                  <span className={`badge ${statusBadge(s.status)}`}>
                    {s.status}
                  </span>
                </td>
                <td>{s.progressCache}%</td>
                <td>{s._count?.steps ?? 0}</td>
                <td>{s.project?.title ?? s.projectId}</td>
                <td className="muted">
                  {s.plannedStart
                    ? new Date(s.plannedStart).toLocaleDateString()
                    : '—'}
                </td>
                <td className="muted">
                  {s.plannedEnd
                    ? new Date(s.plannedEnd).toLocaleDateString()
                    : '—'}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="muted" style={{ textAlign: 'center' }}>
                  Нет этапов
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
