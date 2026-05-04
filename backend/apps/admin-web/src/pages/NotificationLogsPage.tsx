import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

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

  const statusLabel = (s: string) =>
    s === 'delivered'
      ? 'доставлено'
      : s === 'failed'
        ? 'ошибка'
        : s === 'pending'
          ? 'в очереди'
          : s;

  return (
    <div>
      <PageHelp
        storageKey="notifications"
        title="Логи push-уведомлений"
        summary="Журнал отправок push-уведомлений через провайдера (FCM по умолчанию). Каждая попытка отправки на конкретное устройство = одна строка. Полезно для отладки «почему пользователь не получил пуш»."
        bullets={[
          'Тип — это NotificationKind (например stage_started, approval_pending, payment_disputed). Соответствует шаблону из ТЗ v3 §15.2.',
          'Провайдер — какая абстракция отправляла (fcm / mind_push на случай санкционного failover).',
          'Статус: «доставлено» — провайдер принял; «ошибка» — отказ (см. колонку «Ошибка»); «в очереди» — ещё не дошло до провайдера.',
          'Фильтр User ID — UUID пользователя из таблицы User. Без фильтра показываются последние записи по всем.',
        ]}
      />
      <div className="filters">
        <input
          placeholder="UUID пользователя (опционально)"
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
              <th>Тип уведомления</th>
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
                <td title={l.status}>{statusBadge(statusLabel(l.status))}</td>
                <td className="muted" style={{ fontSize: 11 }}>
                  {l.error ?? ''}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={6} className="muted" style={{ textAlign: 'center' }}>
                  Записей нет
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
