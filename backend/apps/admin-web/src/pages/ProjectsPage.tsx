import { useEffect, useState } from 'react';
import { api } from '../api';

export function ProjectsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [selected, setSelected] = useState<any | null>(null);
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listProjects({ q: q || undefined, status: status || undefined });
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

  const openDetail = async (id: string) => {
    const d = await api.getProject(id);
    setSelected(d);
  };

  const forceArchive = async () => {
    if (!selected) return;
    const reason = prompt('Причина принудительной архивации:');
    if (!reason) return;
    await api.forceArchive(selected.id, reason);
    const d = await api.getProject(selected.id);
    setSelected(d);
    reload();
  };

  if (selected) {
    return (
      <div>
        <button className="ghost" onClick={() => setSelected(null)} style={{ marginBottom: 12 }}>
          ← К списку
        </button>
        <div className="card">
          <h3 style={{ margin: 0 }}>{selected.title}</h3>
          <div className="muted">{selected.address ?? '—'}</div>
          <div style={{ marginTop: 8 }}>
            <span className="badge">{selected.status}</span>{' '}
            <span className="muted">
              Owner: {selected.owner.firstName} {selected.owner.lastName} ({selected.owner.phone})
            </span>
          </div>
          <div className="muted" style={{ marginTop: 8 }}>
            Создан: {new Date(selected.createdAt).toLocaleString()}{' '}
            {selected.archivedAt &&
              `· Архивирован: ${new Date(selected.archivedAt).toLocaleString()}`}
          </div>
        </div>

        <div className="card">
          <strong>Команда ({selected.memberships.length})</strong>
          {selected.memberships.map((m: any) => (
            <div key={m.id} style={{ marginTop: 6, fontSize: 13 }}>
              <span className="badge">{m.role}</span> {m.user.firstName} {m.user.lastName} ·{' '}
              {m.user.phone}
            </div>
          ))}
        </div>

        <div className="card">
          <strong>Этапы ({selected.stages.length})</strong>
          {selected.stages.map((s: any) => (
            <div key={s.id} style={{ marginTop: 6 }}>
              <span className="badge">{s.status}</span> {s.title} · прогресс {s.progressCache}%
            </div>
          ))}
        </div>

        <div className="card">
          <strong>Активность</strong>
          <div className="muted" style={{ marginTop: 6 }}>
            Платежи: {selected._count.payments} · Материалы: {selected._count.materialRequests} ·
            Самозакупы: {selected._count.selfPurchases} · Чатов: {selected._count.chats} ·
            Документов: {selected._count.documents} · Экспортов: {selected._count.exportJobs}
          </div>
        </div>

        {selected.status !== 'archived' && (
          <div className="card">
            <strong>Модерация</strong>
            <div style={{ marginTop: 8 }}>
              <button onClick={forceArchive}>Force archive</button>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div>
      <div className="row" style={{ marginBottom: 12, gap: 8 }}>
        <input
          placeholder="Поиск по названию / адресу"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          style={{ flex: 0, minWidth: 140 }}
        >
          <option value="">Все статусы</option>
          <option value="active">active</option>
          <option value="archived">archived</option>
        </select>
        <button onClick={reload} style={{ flex: 0 }}>
          Применить
        </button>
      </div>

      {loading && <div>Загрузка…</div>}
      {error && <div className="error">{error}</div>}
      <div className="muted" style={{ marginBottom: 8 }}>
        Всего: {total}
      </div>

      {items.map((p) => (
        <div
          key={p.id}
          className="card"
          onClick={() => openDetail(p.id)}
          style={{ cursor: 'pointer' }}
        >
          <div className="row">
            <div className="grow">
              <strong>{p.title}</strong> <span className="badge">{p.status}</span>
              <div className="muted">{p.address ?? '—'}</div>
              <div className="muted">
                Owner: {p.owner.firstName} {p.owner.lastName} · {p.owner.phone}
              </div>
            </div>
            <div className="muted" style={{ flex: 0, textAlign: 'right', fontSize: 13 }}>
              Команда: {p._count.memberships}
              <br />
              Этапов: {p._count.stages}
              <br />
              Платежей: {p._count.payments}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
