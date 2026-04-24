import { useEffect, useState } from 'react';
import { api } from '../api';

const STATUSES = ['pending', 'confirmed', 'disputed', 'resolved', 'cancelled'];
const KINDS = ['advance', 'distribution', 'work'];

export function PaymentsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState('');
  const [kind, setKind] = useState('');
  const [projectId, setProjectId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listPayments({
        status: status || undefined,
        kind: kind || undefined,
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

  const money = (kop: string | number) => {
    const n = typeof kop === 'string' ? BigInt(kop) : BigInt(kop);
    const rub = Number(n / 100n);
    return `${rub.toLocaleString('ru-RU')} ₽`;
  };

  const statusBadge = (s: string) => {
    const cls =
      s === 'confirmed'
        ? 'green'
        : s === 'disputed'
          ? 'red'
          : s === 'resolved'
            ? 'blue'
            : s === 'cancelled'
              ? 'gray'
              : 'yellow';
    return <span className={`badge ${cls}`}>{s}</span>;
  };

  return (
    <div>
      <div className="filters">
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">Все статусы</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <select value={kind} onChange={(e) => setKind(e.target.value)}>
          <option value="">Все виды</option>
          {KINDS.map((k) => (
            <option key={k} value={k}>
              {k}
            </option>
          ))}
        </select>
        <input
          placeholder="Project ID"
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
              <th>Сумма</th>
              <th>Вид</th>
              <th>Статус</th>
              <th>От → Кому</th>
              <th>Проект</th>
              <th>Создан</th>
            </tr>
          </thead>
          <tbody>
            {items.map((p) => (
              <tr key={p.id}>
                <td>
                  <strong>{money(p.amount)}</strong>
                  {p.resolvedAmount && (
                    <div className="muted" style={{ fontSize: 11 }}>
                      → {money(p.resolvedAmount)}
                    </div>
                  )}
                </td>
                <td>
                  <span className="badge">{p.kind}</span>
                </td>
                <td>{statusBadge(p.status)}</td>
                <td>
                  <div>
                    {p.from
                      ? `${p.from.firstName} ${p.from.lastName}`
                      : p.fromUserId}
                  </div>
                  <div className="muted" style={{ fontSize: 11 }}>
                    →{' '}
                    {p.to
                      ? `${p.to.firstName} ${p.to.lastName}`
                      : p.toUserId}
                  </div>
                </td>
                <td>{p.project?.title ?? p.projectId}</td>
                <td className="muted">
                  {new Date(p.createdAt).toLocaleString()}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={6} className="muted" style={{ textAlign: 'center' }}>
                  Нет выплат
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
