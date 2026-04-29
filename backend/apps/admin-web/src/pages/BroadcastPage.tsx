import { useEffect, useState } from 'react';
import { api } from '../api';

export function BroadcastPage() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [deepLink, setDeepLink] = useState('');
  const [roles, setRoles] = useState<string[]>([]);
  const [platform, setPlatform] = useState<'' | 'ios' | 'android'>('');
  const [projectIdsRaw, setProjectIdsRaw] = useState('');
  const [preview, setPreview] = useState<{ count: number; sample?: string[] } | null>(null);
  const [history, setHistory] = useState<any[]>([]);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reloadHistory = () =>
    api
      .listBroadcasts()
      .then(setHistory)
      .catch((e) => setError(e.message));

  useEffect(() => {
    reloadHistory();
  }, []);

  const toggleRole = (r: string) => {
    setRoles((rs) => (rs.includes(r) ? rs.filter((x) => x !== r) : [...rs, r]));
    setPreview(null);
  };

  const buildFilter = () => {
    const projectIds = projectIdsRaw
      .split(/[\s,;]+/)
      .map((s) => s.trim())
      .filter(Boolean);
    return {
      roles: roles.length > 0 ? roles : undefined,
      platform: platform || undefined,
      projectIds: projectIds.length > 0 ? projectIds : undefined,
    };
  };

  const doPreview = async () => {
    try {
      const r = await api.previewBroadcast(buildFilter() as any);
      setPreview({ count: r.count, sample: r.sampleUserIds });
      setError(null);
    } catch (e: any) {
      setError(e.message);
    }
  };

  const doSend = async () => {
    if (!title.trim() || !body.trim()) return alert('Заполните заголовок и текст');
    if (!confirm(`Отправить рассылку? Получатели: ${preview?.count ?? '?'}`)) return;
    setSending(true);
    try {
      await api.sendBroadcast({
        title,
        body,
        deepLink: deepLink || undefined,
        filter: buildFilter() as any,
      });
      alert('Отправлено');
      setTitle('');
      setBody('');
      setDeepLink('');
      setRoles([]);
      setPlatform('');
      setProjectIdsRaw('');
      setPreview(null);
      reloadHistory();
    } catch (e: any) {
      alert('Ошибка: ' + e.message);
    } finally {
      setSending(false);
    }
  };

  return (
    <div>
      <div className="card">
        <strong>Новая рассылка</strong>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Заголовок"
          style={{ marginTop: 8 }}
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Текст уведомления"
          rows={4}
          style={{ marginTop: 8 }}
        />
        <input
          value={deepLink}
          onChange={(e) => setDeepLink(e.target.value)}
          placeholder="Deep-link (опционально, например repair://projects/abc)"
          style={{ marginTop: 8 }}
        />

        <div className="muted" style={{ marginTop: 12 }}>
          Фильтр по ролям (если ничего не выбрано — все роли):
        </div>
        <div className="row" style={{ gap: 6, flexWrap: 'wrap', marginTop: 6 }}>
          {['customer', 'representative', 'contractor', 'master'].map((r) => (
            <button
              key={r}
              className={roles.includes(r) ? '' : 'secondary'}
              onClick={() => toggleRole(r)}
              style={{ flex: 0 }}
            >
              {r}
            </button>
          ))}
        </div>

        <div className="muted" style={{ marginTop: 12 }}>
          Фильтр по платформе:
        </div>
        <div className="row" style={{ gap: 6, flexWrap: 'wrap', marginTop: 6 }}>
          {(['', 'ios', 'android'] as const).map((p) => (
            <button
              key={p || 'all'}
              className={platform === p ? '' : 'secondary'}
              onClick={() => {
                setPlatform(p);
                setPreview(null);
              }}
              style={{ flex: 0 }}
            >
              {p === '' ? 'Все' : p}
            </button>
          ))}
        </div>

        <div className="muted" style={{ marginTop: 12 }}>
          Project IDs (опционально, через пробел/запятую — рассылка только участникам этих проектов):
        </div>
        <input
          value={projectIdsRaw}
          onChange={(e) => {
            setProjectIdsRaw(e.target.value);
            setPreview(null);
          }}
          placeholder="cl_abc123 cl_def456"
          style={{ marginTop: 6 }}
        />

        <div className="row" style={{ gap: 8, marginTop: 12 }}>
          <button className="secondary" onClick={doPreview}>
            Preview
          </button>
          <button onClick={doSend} disabled={sending || !preview}>
            {sending ? 'Отправка…' : 'Отправить'}
          </button>
        </div>

        {preview && (
          <div className="muted" style={{ marginTop: 8 }}>
            Получателей: <strong>{preview.count}</strong>
            {preview.sample && preview.sample.length > 0 && (
              <> · примеры: {preview.sample.slice(0, 3).join(', ')}</>
            )}
          </div>
        )}
        {error && (
          <div className="error" style={{ marginTop: 8 }}>
            {error}
          </div>
        )}
      </div>

      <h3 style={{ marginTop: 24 }}>История рассылок</h3>
      {history.map((c) => (
        <div key={c.id} className="card">
          <div className="row">
            <div className="grow">
              <strong>{c.title}</strong>{' '}
              <span className={`badge ${c.status === 'sent' ? 'read' : c.status}`}>{c.status}</span>
              <div className="muted" style={{ fontSize: 13 }}>
                {c.body}
              </div>
            </div>
            <div className="muted" style={{ flex: 0, textAlign: 'right', fontSize: 13 }}>
              Target: {c.targetCount}
              <br />
              Delivered: {c.deliveredCount}
              <br />
              {c.sentAt && new Date(c.sentAt).toLocaleString()}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
