import { useEffect, useState } from 'react';
import { api } from '../api';

const STATUSES = ['pending', 'approved', 'rejected', 'cancelled'];
const SCOPES = ['plan', 'step', 'extra_work', 'deadline_change', 'stage_accept'];

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
      <div className="filters">
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">Все статусы</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <select value={scope} onChange={(e) => setScope(e.target.value)}>
          <option value="">Все типы</option>
          {SCOPES.map((s) => (
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
              <th>Scope</th>
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
