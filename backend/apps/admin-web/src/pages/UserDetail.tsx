import { useEffect, useState } from 'react';
import { api } from '../api';

export function UserDetail({ userId, onBack }: { userId: string; onBack(): void }) {
  const [u, setU] = useState<any>(null);
  const [audit, setAudit] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    try {
      const [user, a] = await Promise.all([api.getUser(userId), api.userAudit(userId)]);
      setU(user);
      setAudit(a);
    } catch (e: any) {
      setError(e.message);
    }
  };

  useEffect(() => {
    reload();
  }, [userId]);

  const doBan = async () => {
    const reason = prompt('Причина бана:');
    if (!reason) return;
    await api.banUser(userId, reason);
    await reload();
  };
  const doUnban = async () => {
    if (!confirm('Разбанить пользователя?')) return;
    await api.unbanUser(userId);
    await reload();
  };
  const doReset = async () => {
    if (!confirm('Сбросить пароль? Все активные сессии будут завершены.')) return;
    const r = await api.resetPassword(userId);
    alert(
      'Временный пароль:\n\n' +
        r.tempPassword +
        '\n\nПередайте пользователю через безопасный канал.',
    );
    await reload();
  };
  const doLogout = async () => {
    if (!confirm('Разлогинить со всех устройств?')) return;
    const r = await api.forceLogout(userId);
    alert(`Отозвано сессий: ${r.revokedSessions}`);
    await reload();
  };

  if (error) return <div className="error">{error}</div>;
  if (!u) return <div>Загрузка…</div>;

  return (
    <div>
      <button className="ghost" onClick={onBack} style={{ marginBottom: 12 }}>
        ← К списку
      </button>

      <div className="card">
        <div className="row">
          <div className="grow">
            <h3 style={{ margin: 0 }}>
              {u.firstName} {u.lastName}
            </h3>
            <div className="muted">
              {u.phone}
              {u.email ? ` · ${u.email}` : ''}
            </div>
            <div className="muted">Создан: {new Date(u.createdAt).toLocaleString()}</div>
            {u.lastSeenAt && (
              <div className="muted">
                Посл. активность: {new Date(u.lastSeenAt).toLocaleString()}
              </div>
            )}
          </div>
          <div style={{ flex: 0, textAlign: 'right' }}>
            <div style={{ marginBottom: 6 }}>
              {u.bannedAt ? (
                <span className="badge new">BANNED</span>
              ) : (
                <span className="badge read">ACTIVE</span>
              )}
            </div>
            <div className="muted" style={{ fontSize: 13 }}>
              Активная роль: <strong>{u.activeRole}</strong>
            </div>
          </div>
        </div>
        {u.bannedAt && (
          <div className="muted" style={{ marginTop: 8 }}>
            Забанен: {new Date(u.bannedAt).toLocaleString()} · Причина: {u.banReason ?? '—'}
          </div>
        )}
      </div>

      <div className="card">
        <strong>Роли</strong>
        <div className="row" style={{ gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
          {u.roles.map((r: any) => (
            <span key={r.role} className="badge">
              {r.role}
            </span>
          ))}
        </div>
      </div>

      <div className="card">
        <strong>Действия</strong>
        <div className="row" style={{ gap: 8, marginTop: 8 }}>
          {u.bannedAt ? (
            <button onClick={doUnban}>Разбанить</button>
          ) : (
            <button onClick={doBan}>Забанить</button>
          )}
          <button className="secondary" onClick={doReset}>
            Сбросить пароль
          </button>
          <button className="secondary" onClick={doLogout}>
            Force logout
          </button>
        </div>
      </div>

      <div className="card">
        <strong>Активные сессии: {u.sessions?.length ?? 0}</strong>
        {u.sessions?.slice(0, 5).map((s: any) => (
          <div key={s.id} className="muted" style={{ marginTop: 6, fontSize: 13 }}>
            device={s.deviceId} · IP fp: {s.ipFingerprint} · до{' '}
            {new Date(s.expiresAt).toLocaleString()}
          </div>
        ))}
      </div>

      <div className="card">
        <strong>Audit (последние действия над пользователем)</strong>
        {audit.length === 0 && (
          <div className="muted" style={{ marginTop: 8 }}>
            Записей нет.
          </div>
        )}
        {audit.slice(0, 10).map((a) => (
          <div key={a.id} style={{ marginTop: 8, fontSize: 13 }}>
            <span className="badge">{a.action}</span>{' '}
            <span className="muted">
              {new Date(a.createdAt).toLocaleString()} · actor: {a.actorId}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
