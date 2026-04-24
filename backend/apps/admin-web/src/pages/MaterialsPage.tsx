import { useEffect, useState } from 'react';
import { api } from '../api';

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
      <div className="filters">
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">Все статусы</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <input
          placeholder="Project ID"
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
