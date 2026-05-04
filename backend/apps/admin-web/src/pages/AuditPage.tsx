import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

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
      <PageHelp
        storageKey="audit"
        title="Журнал аудита"
        summary="Иммутабельный лог всех значимых действий в системе: административных (бан, сброс пароля), бизнес-событий (публикация юр. документа, рассылка), системных (forceArchive проекта). Используется для разбора инцидентов и для соответствия 152-ФЗ."
        bullets={[
          'Запись в audit делает только бекенд — стереть/изменить запись из админки нельзя.',
          'Поле «Action» — машинный код события (user.ban, legal.published, project.force_archive…). Фильтр работает по точному совпадению или подстроке.',
          'Actor — тот, кто действие совершил (UUID администратора). Target — над кем/чем (тип:UUID).',
          'Metadata — JSON с произвольным контекстом (причина бана, версия документа и т. п.).',
        ]}
      />
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
          <div style={{ flex: 2 }}>Действие</div>
          <div style={{ flex: 2 }}>Кто → над кем</div>
          <div style={{ flex: 2 }}>Подробности</div>
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
