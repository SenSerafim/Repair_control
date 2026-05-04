import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

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
      <PageHelp
        storageKey="settings"
        title="Системные настройки (key-value)"
        summary="Произвольный реестр настроек приложения в виде ключ→значение. Хранятся в таблице AppSetting. Часть ключей публикуется на мобильные клиенты через GET /me/app-settings."
        bullets={[
          'Каждая запись — одна строка с ключом (snake_case) и строковым значением. Значение можно править на месте и сохранять кнопкой «Сохранить».',
          'Кнопка «+ Ключ» создаёт новую запись (через два prompt-окна: ключ → значение).',
          'Контакты поддержки лучше править на странице «Контакты поддержки» — там валидация и подсказки.',
          'Изменения применяются сразу. Мобильные клиенты подхватят их при следующем входе или открытии экрана, который читает app-settings.',
        ]}
      />
      <div className="row" style={{ marginBottom: 12 }}>
        <div className="muted grow">
          Ключи приложения (URL поддержки, версии политик и т. п.). Публичные значения отдаются
          мобайлу через <code>GET /me/app-settings</code>.
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
            {s.updatedBy ? ` · кем: ${s.updatedBy}` : ''}
          </div>
        </div>
      ))}
    </div>
  );
}
