import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

const TYPES = ['project', 'stage', 'personal', 'group'];
const TYPE_LABELS: Record<string, string> = {
  project: 'project — общий чат проекта',
  stage: 'stage — чат отдельного этапа',
  personal: 'personal — личный диалог двух пользователей',
  group: 'group — произвольная групповая беседа',
};

export function ChatsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [type, setType] = useState('');
  const [projectId, setProjectId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listChats({
        type: type || undefined,
        projectId: projectId || undefined,
        limit: 100,
      });
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

  return (
    <div>
      <PageHelp
        storageKey="chats"
        title="Чаты"
        summary="Список всех чатов в системе с разбивкой по типам. Реальный обмен сообщениями идёт через WebSocket Gateway /chats. Содержимое сообщений видно только участникам — здесь отображается только метаинформация."
        bullets={[
          '4 типа: project (общий по проекту), stage (по конкретному этапу), personal (1-на-1), group (произвольная группа).',
          '«Видим заказчику» — флаг visibleToCustomer. Если выключен — чат скрыт от роли customer (используется для внутренней координации мастеров и бригадира).',
          'Сообщения — общее число MessagesEntry в чате. Включает удалённые (soft-delete) и отредактированные.',
          'Эта страница не показывает контент сообщений — только сводку. Открыть переписку можно только через мобайл, имея доступ к проекту.',
        ]}
      />
      <div className="filters">
        <select value={type} onChange={(e) => setType(e.target.value)}>
          <option value="">Все типы</option>
          {TYPES.map((t) => (
            <option key={t} value={t}>
              {TYPE_LABELS[t] ?? t}
            </option>
          ))}
        </select>
        <input
          placeholder="UUID проекта"
          value={projectId}
          onChange={(e) => setProjectId(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <button onClick={reload}>Применить</button>
        <span className="muted">Всего: {total}</span>
      </div>
      {error && <div className="error">{error}</div>}
      {loading ? (
        <div className="muted">Загрузка…</div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Название</th>
              <th>Тип</th>
              <th>Участники</th>
              <th>Сообщения</th>
              <th>Видим заказчику</th>
              <th>Проект</th>
              <th>Создан</th>
            </tr>
          </thead>
          <tbody>
            {items.map((c) => (
              <tr key={c.id}>
                <td>
                  <strong>{c.title ?? c.type}</strong>
                </td>
                <td>
                  <span className="badge">{c.type}</span>
                </td>
                <td>{c._count?.participants ?? 0}</td>
                <td>{c._count?.messages ?? 0}</td>
                <td>
                  {c.visibleToCustomer ? (
                    <span className="badge green">да</span>
                  ) : (
                    <span className="badge gray">нет</span>
                  )}
                </td>
                <td>{c.project?.title ?? c.projectId ?? '—'}</td>
                <td className="muted">
                  {new Date(c.createdAt).toLocaleString()}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="muted" style={{ textAlign: 'center' }}>
                  Нет чатов
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
