import { useEffect, useState } from 'react';
import { api } from '../api';

export function AuditPage() {
  const [items, setItems] = useState<any[]>([]);
  const [action, setAction] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      setItems(await api.audit({ action: action || undefined, limit: 200 }));
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
      <div className="row" style={{ marginBottom: 12, gap: 8 }}>
        <input
          placeholder="Фильтр по action (user.ban, legal.published, ...)"
          value={action}
          onChange={(e) => setAction(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <button onClick={reload} style={{ flex: 0 }}>
          Применить
        </button>
      </div>

      {loading && <div>Загрузка…</div>}
      {error && <div className="error">{error}</div>}

      <div className="card">
        <div className="row" style={{ fontWeight: 700, fontSize: 13, color: '#667' }}>
          <div style={{ flex: 1 }}>Время</div>
          <div style={{ flex: 2 }}>Action</div>
          <div style={{ flex: 2 }}>Actor → Target</div>
          <div style={{ flex: 2 }}>Metadata</div>
        </div>
      </div>
      {items.map((a) => (
        <div key={a.id} className="card">
          <div className="row" style={{ fontSize: 13 }}>
            <div style={{ flex: 1 }} className="muted">
              {new Date(a.createdAt).toLocaleString()}
            </div>
            <div style={{ flex: 2 }}>
              <span className="badge">{a.action}</span>
            </div>
            <div style={{ flex: 2 }}>
              <code style={{ fontSize: 11 }}>{a.actorId}</code>
              {a.targetId && (
                <>
                  {' '}
                  →{' '}
                  <code style={{ fontSize: 11 }}>
                    {a.targetType}:{a.targetId}
                  </code>
                </>
              )}
            </div>
            <div style={{ flex: 2 }}>
              <code style={{ fontSize: 11 }}>{JSON.stringify(a.metadata)}</code>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
