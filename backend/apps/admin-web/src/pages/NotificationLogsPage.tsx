import { useEffect, useState } from 'react';
import { api } from '../api';

export function NotificationLogsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [userId, setUserId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.logs(userId || undefined);
      setItems(data);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const statusBadge = (s: string) => {
    const cls =
      s === 'delivered' ? 'green' : s === 'failed' ? 'red' : 'yellow';
    return <span className={`badge ${cls}`}>{s}</span>;
  };

  return (
    <div>
      <div className="filters">
        <input
          placeholder="User ID (опционально)"
          value={userId}
          onChange={(e) => setUserId(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <button onClick={reload}>Применить</button>
      </div>
      {error && <div className="error">{error}</div>}
      {loading ? (
        <div className="muted">Загрузка…</div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Время</th>
              <th>Пользователь</th>
              <th>Тип</th>
              <th>Провайдер</th>
              <th>Статус</th>
              <th>Ошибка</th>
            </tr>
          </thead>
          <tbody>
            {items.map((l, i) => (
              <tr key={l.id ?? i}>
                <td className="muted">
                  {new Date(l.createdAt).toLocaleString()}
                </td>
                <td>{l.userId}</td>
                <td>
                  <span className="badge">{l.kind ?? l.notificationKind ?? '—'}</span>
                </td>
                <td>{l.provider ?? '—'}</td>
                <td>{statusBadge(l.status)}</td>
                <td className="muted" style={{ fontSize: 11 }}>
                  {l.error ?? ''}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={6} className="muted" style={{ textAlign: 'center' }}>
                  Пусто
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
