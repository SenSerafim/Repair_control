import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

const STATUSES = [
  'draft',
  'open',
  'partiallyBought',
  'bought',
  'delivered',
  'disputed',
  'resolved',
  'cancelled',
];

const STATUS_LABELS: Record<string, string> = {
  draft: 'draft — черновик',
  open: 'open — заявка отправлена',
  partiallyBought: 'partiallyBought — куплено частично',
  bought: 'bought — всё куплено',
  delivered: 'delivered — доставлено на объект',
  disputed: 'disputed — оспорено',
  resolved: 'resolved — спор разрешён',
  cancelled: 'cancelled — отменено',
};

export function MaterialsPage() {
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
      const r = await api.listMaterials({
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

  return (
    <div>
      <PageHelp
        storageKey="materials"
        title="Заявки на материалы"
        summary="Список MaterialRequest — заявки на закупку материалов внутри проектов. Каждая заявка имеет статус из FSM на 8 состояний и набор позиций (items) с галочкой «куплено / доставлено»."
        bullets={[
          'Получатель — тот, кто закупает (recipient): обычно бригадир или мастер. Чек-лист позиций ведётся в мобайле.',
          'partiallyBought — часть позиций отмечена как куплена, часть ещё нет. После закрытия всех позиций статус автоматически становится bought.',
          'disputed → resolved — спор по ассортименту/ценам. Разрешение приводит к перерасчёту бюджета.',
          'Эта страница read-only: заявки создаются и закрываются в мобайле. Здесь — для аналитики и разбора инцидентов.',
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
              <th>Получатель</th>
              <th>Позиций</th>
              <th>Проект</th>
              <th>Создан</th>
            </tr>
          </thead>
          <tbody>
            {items.map((m) => (
              <tr key={m.id}>
                <td>
                  <strong>{m.title}</strong>
                </td>
                <td>
                  <span className="badge">{m.status}</span>
                </td>
                <td className="muted">{m.recipient}</td>
                <td>{m._count?.items ?? 0}</td>
                <td>{m.project?.title ?? m.projectId}</td>
                <td className="muted">
                  {new Date(m.createdAt).toLocaleString()}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={6} className="muted" style={{ textAlign: 'center' }}>
                  Нет заявок
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
