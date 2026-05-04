import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

export function UsersList({ onSelect }: { onSelect(id: string): void }) {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [q, setQ] = useState('');
  const [role, setRole] = useState('');
  const [banned, setBanned] = useState<'' | 'true' | 'false'>('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listUsers({
        q: q || undefined,
        role: role || undefined,
        banned: banned === '' ? undefined : banned === 'true',
        limit: 50,
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
        storageKey="users-list"
        title="Пользователи"
        summary="Список всех зарегистрированных пользователей. Поиск, фильтр по роли и статусу бана. Клик по строке открывает карточку пользователя с подробностями и действиями (бан / сброс пароля / разлогин)."
        bullets={[
          'Поиск ищет по телефону, имени и email одновременно. Нажмите Enter для применения.',
          'Активная роль — та, под которой пользователь сейчас работает в мобайле (одну учётку можно иметь в нескольких ролях, переключение через профиль).',
          'Бейдж BANNED означает, что пользователь не может войти. Снять бан можно в карточке.',
          'Цифры справа: сколько проектов он владеет (ownedProjects) + в скольких состоит (memberships); число активных сессий.',
        ]}
      />
      <div className="row" style={{ marginBottom: 12, gap: 8 }}>
        <input
          placeholder="Поиск по телефону / имени / email"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <select
          value={role}
          onChange={(e) => setRole(e.target.value)}
          style={{ flex: 0, minWidth: 140 }}
        >
          <option value="">Все роли</option>
          <option value="customer">Заказчик (customer)</option>
          <option value="representative">Представитель (representative)</option>
          <option value="contractor">Бригадир (contractor)</option>
          <option value="master">Мастер (master)</option>
          <option value="admin">Администратор (admin)</option>
        </select>
        <select
          value={banned}
          onChange={(e) => setBanned(e.target.value as any)}
          style={{ flex: 0, minWidth: 140 }}
        >
          <option value="">Все статусы</option>
          <option value="false">Активные</option>
          <option value="true">Забанены</option>
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

      {items.map((u) => (
        <div
          key={u.id}
          className="card"
          onClick={() => onSelect(u.id)}
          style={{ cursor: 'pointer' }}
        >
          <div className="row">
            <div className="grow">
              <strong>
                {u.firstName} {u.lastName}
              </strong>
              {u.bannedAt && (
                <span className="badge new" style={{ marginLeft: 8 }}>
                  ЗАБАНЕН
                </span>
              )}
              <div className="muted">
                {u.phone} · активная роль: {u.activeRole}
              </div>
            </div>
            <div className="muted" style={{ flex: 0, textAlign: 'right', fontSize: 13 }}>
              Проектов: {u._count?.ownedProjects ?? 0} + {u._count?.memberships ?? 0}
              <br />
              Сессий: {u._count?.sessions ?? 0}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
