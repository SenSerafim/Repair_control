import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

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
      <PageHelp
        storageKey="feedback"
        title="Обратная связь от пользователей"
        summary="Сообщения, отправленные пользователями через экран «Обратная связь» в мобайле. К каждому письму могут быть приложены файлы (скриншоты, фото) — они хранятся в S3 и здесь показываются только их количество."
        bullets={[
          'Статусы: new — новое (не прочитано); read — оператор открыл; archived — обработано/неактуально.',
          'Кнопка «Прочитано» переводит в read. «В архив» — финальный статус. Никаких ответов из админки нет — связь с пользователем оператор поддерживает по контактам поддержки.',
          'Поле «От» — UUID отправителя. По UUID можно перейти в раздел «Пользователи» и найти его карточку.',
          'Этот экран не отвечает в духе чата — это только триаж входящих писем.',
        ]}
      />
      <div className="row" style={{ marginBottom: 12 }}>
        <select value={filter} onChange={(e) => setFilter(e.target.value as any)}>
          <option value="">Все статусы</option>
          <option value="new">новые</option>
          <option value="read">прочитанные</option>
          <option value="archived">в архиве</option>
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
