import { useState, useEffect } from 'react';
import { api, getToken, setToken } from './api';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { UsersPage } from './pages/UsersPage';
import { ProjectsPage } from './pages/ProjectsPage';
import { LegalPage } from './pages/LegalPage';
import { BroadcastPage } from './pages/BroadcastPage';
import { AuditPage } from './pages/AuditPage';
import { FeedbackList } from './pages/FeedbackList';
import { FaqEditor } from './pages/FaqEditor';
import { SettingsPage } from './pages/Settings';

type Tab =
  | 'dashboard'
  | 'users'
  | 'projects'
  | 'feedback'
  | 'faq'
  | 'legal'
  | 'broadcast'
  | 'audit'
  | 'settings';

const TABS: { key: Tab; label: string }[] = [
  { key: 'dashboard', label: 'Обзор' },
  { key: 'users', label: 'Пользователи' },
  { key: 'projects', label: 'Проекты' },
  { key: 'feedback', label: 'Feedback' },
  { key: 'broadcast', label: 'Рассылки' },
  { key: 'legal', label: 'Юр. документы' },
  { key: 'faq', label: 'FAQ' },
  { key: 'audit', label: 'Audit log' },
  { key: 'settings', label: 'Настройки' },
];

export function App() {
  const [authed, setAuthed] = useState<boolean>(!!getToken());
  const [tab, setTab] = useState<Tab>('dashboard');
  const [me, setMe] = useState<any>(null);

  useEffect(() => {
    if (authed) {
      api
        .me()
        .then(setMe)
        .catch(() => {
          setToken(null);
          setAuthed(false);
        });
    }
  }, [authed]);

  if (!authed) {
    return <Login onSuccess={() => setAuthed(true)} />;
  }

  return (
    <div className="app">
      <header>
        <h1>Repair Control — Admin</h1>
        <div className="row" style={{ flex: 0 }}>
          <span className="muted">{me ? `${me.firstName} ${me.lastName}` : ''}</span>
          <button
            className="secondary"
            onClick={() => {
              setToken(null);
              setAuthed(false);
            }}
          >
            Выйти
          </button>
        </div>
      </header>
      <nav className="tabs" style={{ flexWrap: 'wrap' }}>
        {TABS.map((t) => (
          <button
            key={t.key}
            className={`tab ${tab === t.key ? 'active' : ''}`}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </nav>

      {tab === 'dashboard' && <Dashboard />}
      {tab === 'users' && <UsersPage />}
      {tab === 'projects' && <ProjectsPage />}
      {tab === 'feedback' && <FeedbackList />}
      {tab === 'broadcast' && <BroadcastPage />}
      {tab === 'legal' && <LegalPage />}
      {tab === 'faq' && <FaqEditor />}
      {tab === 'audit' && <AuditPage />}
      {tab === 'settings' && <SettingsPage />}
    </div>
  );
}
