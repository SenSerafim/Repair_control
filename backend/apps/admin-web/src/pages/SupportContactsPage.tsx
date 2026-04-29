import { useEffect, useState } from 'react';
import { api } from '../api';

interface SupportContacts {
  support_max_url: string;
  support_vk_url: string;
  support_email: string;
  support_phone: string;
}

const KEYS: (keyof SupportContacts)[] = [
  'support_max_url',
  'support_vk_url',
  'support_email',
  'support_phone',
];

const FIELDS: {
  key: keyof SupportContacts;
  label: string;
  hint: string;
  placeholder: string;
  validate: (value: string) => string | null;
}[] = [
  {
    key: 'support_max_url',
    label: 'MAX (мессенджер) — ссылка',
    hint: 'Полный URL вида https://max.ru/... — мобильное приложение откроет его в браузере.',
    placeholder: 'https://max.ru/repaircontrol_support',
    validate: (v) => (v.length === 0 || /^https:\/\/.+/i.test(v) ? null : 'Должен быть https-URL'),
  },
  {
    key: 'support_vk_url',
    label: 'VK — ссылка',
    hint: 'https://vk.com/... либо https://vk.me/... для прямого диалога.',
    placeholder: 'https://vk.com/repaircontrol',
    validate: (v) => (v.length === 0 || /^https:\/\/.+/i.test(v) ? null : 'Должен быть https-URL'),
  },
  {
    key: 'support_email',
    label: 'Email',
    hint: 'На мобильном откроется штатный mailto:.',
    placeholder: 'support@repaircontrol.ru',
    validate: (v) => (v.length === 0 || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) ? null : 'Невалидный email'),
  },
  {
    key: 'support_phone',
    label: 'Телефон',
    hint: 'В международном формате (+7…). На мобильном откроется набор номера.',
    placeholder: '+78001234567',
    validate: (v) => (v.length === 0 || /^\+\d{7,15}$/.test(v) ? null : 'Формат +XXXXXXXXXXX'),
  },
];

export function SupportContactsPage() {
  const [values, setValues] = useState<SupportContacts>({
    support_max_url: '',
    support_vk_url: '',
    support_email: '',
    support_phone: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listSettings();
      const next: SupportContacts = {
        support_max_url: '',
        support_vk_url: '',
        support_email: '',
        support_phone: '',
      };
      for (const s of data) {
        if (KEYS.includes(s.key)) (next as any)[s.key] = s.value ?? '';
      }
      setValues(next);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const errors: Record<string, string | null> = {};
  for (const f of FIELDS) errors[f.key] = f.validate(values[f.key] ?? '');
  const hasErrors = Object.values(errors).some((e) => e !== null);

  const saveAll = async () => {
    if (hasErrors) return;
    setSaving(true);
    setError(null);
    setSuccess(null);
    try {
      for (const k of KEYS) {
        await api.putSetting(k, values[k] ?? '');
      }
      setSuccess('Сохранено. На мобильных приложение получит обновление при следующем входе.');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div>Загрузка…</div>;

  return (
    <div>
      <div className="muted" style={{ marginBottom: 16 }}>
        Контакты поддержки. Везде, где в мобильном приложении есть ссылка
        «Связаться с поддержкой», открывается единый экран с этими контактами.
        Пустые поля — скрываются. Изменения видны клиентам после перелогина или
        сразу при следующем открытии экрана.
      </div>

      {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}
      {success && <div className="card" style={{ marginBottom: 12, color: '#1b5e20' }}>{success}</div>}

      {FIELDS.map((f) => (
        <div className="card" key={f.key}>
          <label style={{ fontWeight: 700, display: 'block', marginBottom: 4 }}>{f.label}</label>
          <div className="muted" style={{ marginBottom: 8 }}>{f.hint}</div>
          <input
            className="grow"
            style={{ width: '100%' }}
            value={values[f.key] ?? ''}
            placeholder={f.placeholder}
            onChange={(e) => setValues({ ...values, [f.key]: e.target.value })}
          />
          {errors[f.key] && (
            <div className="error" style={{ marginTop: 6, fontSize: 13 }}>
              {errors[f.key]}
            </div>
          )}
        </div>
      ))}

      <div className="row" style={{ marginTop: 12 }}>
        <button onClick={saveAll} disabled={saving || hasErrors} style={{ flex: 0 }}>
          {saving ? 'Сохранение…' : 'Сохранить'}
        </button>
        <button className="secondary" onClick={reload} style={{ flex: 0 }}>
          Сбросить
        </button>
      </div>
    </div>
  );
}
