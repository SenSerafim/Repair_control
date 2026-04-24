import { useEffect, useState } from 'react';
import { api } from '../api';

const KINDS: Array<'privacy' | 'tos' | 'data_processing_consent'> = [
  'privacy',
  'tos',
  'data_processing_consent',
];

export function LegalPage() {
  const [kind, setKind] = useState<'privacy' | 'tos' | 'data_processing_consent'>('privacy');
  const [docs, setDocs] = useState<any[]>([]);
  const [editing, setEditing] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      setDocs(await api.listLegal(kind));
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, [kind]);

  const createNew = async () => {
    const title = prompt('Заголовок новой версии:');
    if (!title) return;
    const doc = await api.createLegal(kind, title, '# Новая версия\n\n(текст в Markdown)');
    setEditing(doc);
    reload();
  };

  const save = async () => {
    if (!editing) return;
    await api.updateLegal(editing.id, { title: editing.title, bodyMd: editing.bodyMd });
    alert('Сохранено');
    reload();
  };

  const publish = async () => {
    if (!editing) return;
    if (
      !confirm(
        'Опубликовать? Предыдущая активная версия будет деактивирована и пользователям потребуется пересогласие.',
      )
    )
      return;
    await api.publishLegal(editing.id);
    setEditing(null);
    reload();
  };

  return (
    <div>
      <div className="row" style={{ marginBottom: 12, gap: 8 }}>
        <select
          value={kind}
          onChange={(e) => {
            setEditing(null);
            setKind(e.target.value as any);
          }}
        >
          {KINDS.map((k) => (
            <option key={k} value={k}>
              {k}
            </option>
          ))}
        </select>
        <button onClick={createNew} style={{ flex: 0 }}>
          + Новая версия
        </button>
        <div className="grow" />
        <a
          href={`${(import.meta as any).env.VITE_API_BASE_URL}/legal/${kind}`}
          target="_blank"
          rel="noreferrer"
        >
          Открыть публичную ссылку ↗
        </a>
      </div>

      {loading && <div>Загрузка…</div>}
      {error && <div className="error">{error}</div>}

      {editing ? (
        <div className="card">
          <div className="row">
            <input
              value={editing.title}
              onChange={(e) => setEditing({ ...editing, title: e.target.value })}
              disabled={!!editing.publishedAt}
              style={{ flex: 1 }}
            />
            <div className="muted" style={{ flex: 0, marginLeft: 8 }}>
              v{editing.version}
            </div>
          </div>
          <textarea
            value={editing.bodyMd}
            onChange={(e) => setEditing({ ...editing, bodyMd: e.target.value })}
            disabled={!!editing.publishedAt}
            rows={20}
            style={{ marginTop: 8, fontFamily: 'Menlo, Consolas, monospace', fontSize: 13 }}
          />
          <div className="row" style={{ marginTop: 12, gap: 8 }}>
            <button className="ghost" onClick={() => setEditing(null)}>
              Закрыть
            </button>
            {editing.publishedAt ? (
              <span className="badge read">
                Опубликовано {new Date(editing.publishedAt).toLocaleString()}
              </span>
            ) : (
              <>
                <button className="secondary" onClick={save}>
                  Сохранить
                </button>
                <button onClick={publish}>Опубликовать</button>
              </>
            )}
          </div>
        </div>
      ) : (
        docs.map((d) => (
          <div
            key={d.id}
            className="card"
            style={{ cursor: 'pointer' }}
            onClick={() => setEditing(d)}
          >
            <div className="row">
              <div className="grow">
                <strong>
                  v{d.version} — {d.title}
                </strong>
                {d.isActive && (
                  <span className="badge read" style={{ marginLeft: 8 }}>
                    ACTIVE
                  </span>
                )}
                {!d.publishedAt && (
                  <span className="badge new" style={{ marginLeft: 8 }}>
                    DRAFT
                  </span>
                )}
              </div>
              <div className="muted" style={{ flex: 0, fontSize: 13 }}>
                {d.publishedAt
                  ? `опубликовано ${new Date(d.publishedAt).toLocaleString()}`
                  : `создан ${new Date(d.createdAt).toLocaleString()}`}
              </div>
            </div>
          </div>
        ))
      )}
    </div>
  );
}
