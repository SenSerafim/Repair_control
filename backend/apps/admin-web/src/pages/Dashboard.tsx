import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

export function Dashboard() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .stats()
      .then(setStats)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div>Загрузка…</div>;
  if (error) return <div className="error">{error}</div>;
  if (!stats) return null;

  const tile = (title: string, value: string | number, sub?: string) => (
    <div className="card" style={{ flex: 1, minWidth: 180 }}>
      <div className="muted" style={{ fontSize: 12, textTransform: 'uppercase' }}>
        {title}
      </div>
      <div style={{ fontSize: 32, fontWeight: 800, marginTop: 4 }}>{value}</div>
      {sub && (
        <div className="muted" style={{ marginTop: 4, fontSize: 13 }}>
          {sub}
        </div>
      )}
    </div>
  );

  return (
    <div>
      <PageHelp
        storageKey="dashboard"
        title="Сводка по системе"
        summary="Обзорная страница админки. Показывает текущее состояние БД и активность за последние сутки. Цифры обновляются при каждом входе на страницу."
        bullets={[
          'Пользователи / Проекты / Чаты / Документы — всего записей в БД с разбивкой по статусу.',
          'Обратная связь — счётчики писем от пользователей по статусам (new/read/archived).',
          'Уведомления (24 ч) — push, отправленные за последние сутки: успешно/с ошибкой, плюс рассылки и экспорты.',
          'Распределение по ролям — сколько пользователей с какой системной ролью (customer / representative / contractor / master / admin).',
        ]}
      />
      <h2 style={{ marginTop: 0 }}>Обзор системы</h2>
      <div className="row" style={{ flexWrap: 'wrap', gap: 12 }}>
        {tile(
          'Пользователей',
          stats.users.total,
          `активных: ${stats.users.active}, забанено: ${stats.users.banned}`,
        )}
        {tile(
          'Проектов',
          stats.projects.total,
          `активных: ${stats.projects.active} · в архиве: ${stats.projects.archived}`,
        )}
        {tile('Чатов', stats.chats.total)}
        {tile('Документов', stats.documents.total)}
      </div>
      <h3 style={{ marginTop: 24 }}>Обратная связь</h3>
      <div className="row" style={{ flexWrap: 'wrap', gap: 12 }}>
        {tile('Новых', stats.feedback.new)}
        {tile('Прочитанных', stats.feedback.read)}
        {tile('В архиве', stats.feedback.archived)}
      </div>
      <h3 style={{ marginTop: 24 }}>Уведомления (за 24 часа)</h3>
      <div className="row" style={{ flexWrap: 'wrap', gap: 12 }}>
        {tile('Доставлено', stats.notifications.delivered_24h)}
        {tile('Ошибок', stats.notifications.failed_24h)}
        {tile('Рассылок', stats.broadcasts.sent_24h)}
        {tile('Отчётов готово', stats.exports.done, `ошибок: ${stats.exports.failed}`)}
      </div>
      <h3 style={{ marginTop: 24 }}>Распределение пользователей по ролям</h3>
      <div className="card">
        {Object.entries(stats.users.byRole as Record<string, number>).map(([role, count]) => (
          <div key={role} className="row" style={{ justifyContent: 'space-between' }}>
            <span>{role}</span>
            <strong>{count}</strong>
          </div>
        ))}
      </div>
    </div>
  );
}
