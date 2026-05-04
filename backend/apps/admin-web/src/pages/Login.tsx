import { useState } from 'react';
import { api, setToken } from '../api';

interface LoginProps {
  onSuccess(): void;
}

export function Login({ onSuccess }: LoginProps) {
  const [phone, setPhone] = useState('+79990000000');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const r = await api.login(phone, password);
      setToken(r.accessToken);
      onSuccess();
    } catch (e: any) {
      setError(e.message ?? 'не удалось войти');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form className="login" onSubmit={submit}>
      <h1>Вход в админ-панель</h1>
      <div className="muted" style={{ marginBottom: 12, fontSize: 13, lineHeight: 1.5 }}>
        Введите телефон и пароль учётной записи с ролью <code>admin</code>.
        Доступ к админке закрыт RBAC: обычные пользователи получат 403.
      </div>
      <label>Телефон администратора</label>
      <input value={phone} onChange={(e) => setPhone(e.target.value)} autoFocus />
      <label>Пароль</label>
      <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      {error && (
        <div className="error" style={{ marginTop: 12 }}>
          {error}
        </div>
      )}
      <button disabled={loading}>{loading ? 'Вход…' : 'Войти'}</button>
      <div className="muted" style={{ marginTop: 16 }}>
        Демо для staging-стенда: <code>+79990000000</code> / <code>staging-demo-12345</code>.
        В production эти креды не работают.
      </div>
    </form>
  );
}
