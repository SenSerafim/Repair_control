import { useEffect, useState } from 'react';
import { api } from '../api';

export function FeedbackList() {
  const [items, setItems] = useState<any[]>([]);
  const [filter, setFilter] = useState<'' | 'new' | 'read' | 'archived'>('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listFeedback(filter || undefined);
      setItems(data);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, [filter]);

  const patch = async (id: string, status: 'read' | 'archived') => {
    await api.patchFeedback(id, status);
    reload();
  };

  if (loading) return <div>Загрузка…</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div>
      <div className="row" style={{ marginBottom: 12 }}>
        <select value={filter} onChange={(e) => setFilter(e.target.value as any)}>
          <option value="">Все статусы</option>
          <option value="new">new</option>
          <option value="read">read</option>
          <option value="archived">archived</option>
        </select>
        <button className="secondary" onClick={reload}>
          Обновить
        </button>
      </div>
      {items.length === 0 && <div className="muted">Сообщений нет</div>}
      {items.map((m) => (
        <div className="card" key={m.id}>
          <div className="row">
            <div className="grow">
              <div>
                <strong>От:</strong> {m.userId} ·{' '}
                <span className={`badge ${m.status}`}>{m.status}</span>
              </div>
              <div className="muted">{new Date(m.createdAt).toLocaleString()}</div>
            </div>
            <div style={{ flex: 0 }}>
              {m.status !== 'read' && (
                <button className="ghost" onClick={() => patch(m.id, 'read')}>
                  Прочитано
                </button>
              )}
              {m.status !== 'archived' && (
                <button className="ghost" onClick={() => patch(m.id, 'archived')}>
                  В архив
                </button>
              )}
            </div>
          </div>
          <div style={{ whiteSpace: 'pre-wrap', marginTop: 8 }}>{m.text}</div>
          {m.attachmentKeys?.length > 0 && (
            <div className="muted" style={{ marginTop: 8 }}>
              Вложений: {m.attachmentKeys.length}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
