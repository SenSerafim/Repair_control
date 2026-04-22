import { useEffect, useState } from 'react';
import { api } from '../api';

export function SettingsPage() {
  const [settings, setSettings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<Record<string, string>>({});

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listSettings();
      setSettings(data);
      const draft: Record<string, string> = {};
      for (const s of data) draft[s.key] = s.value;
      setEditing(draft);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const save = async (key: string) => {
    await api.putSetting(key, editing[key] ?? '');
    reload();
  };

  const createNew = async () => {
    const key = prompt('Ключ настройки (например, support_telegram_url):');
    if (!key) return;
    const value = prompt('Значение:');
    if (value === null) return;
    await api.putSetting(key, value);
    reload();
  };

  if (loading) return <div>Загрузка…</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div>
      <div className="row" style={{ marginBottom: 12 }}>
        <div className="muted grow">
          Ключи приложения (support URL, версии политик). Публичные — через{' '}
          <code>GET /me/app-settings</code>.
        </div>
        <button onClick={createNew} style={{ flex: 0 }}>
          + Ключ
        </button>
      </div>
      {settings.length === 0 && <div className="muted">Настроек пока нет.</div>}
      {settings.map((s) => (
        <div className="card" key={s.key}>
          <div style={{ fontWeight: 700, marginBottom: 8 }}>{s.key}</div>
          <div className="row">
            <input
              className="grow"
              value={editing[s.key] ?? ''}
              onChange={(e) => setEditing({ ...editing, [s.key]: e.target.value })}
            />
            <button onClick={() => save(s.key)} style={{ flex: 0 }}>
              Сохранить
            </button>
          </div>
          <div className="muted" style={{ marginTop: 6 }}>
            Обновлено: {new Date(s.updatedAt).toLocaleString()}
            {s.updatedBy ? ` · by ${s.updatedBy}` : ''}
          </div>
        </div>
      ))}
    </div>
  );
}
