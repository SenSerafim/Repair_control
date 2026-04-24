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
import { DocumentsPage } from './pages/DocumentsPage';
import { PaymentsPage } from './pages/PaymentsPage';
import { MaterialsPage } from './pages/MaterialsPage';
import { ApprovalsPage } from './pages/ApprovalsPage';
import { ChatsPage } from './pages/ChatsPage';
import { StagesPage } from './pages/StagesPage';
import { NotificationLogsPage } from './pages/NotificationLogsPage';

type Tab =
  | 'dashboard'
  | 'users'
  | 'projects'
  | 'stages'
  | 'approvals'
  | 'payments'
  | 'materials'
  | 'documents'
  | 'chats'
  | 'feedback'
  | 'faq'
  | 'legal'
  | 'broadcast'
  | 'notifications'
  | 'audit'
  | 'settings';

interface TabGroup {
  label: string;
  items: { key: Tab; label: string; icon: string }[];
}

const GROUPS: TabGroup[] = [
  {
    label: 'Обзор',
    items: [
      { key: 'dashboard', label: 'Dashboard', icon: '◐' },
      { key: 'audit', label: 'Audit log', icon: '⌘' },
      { key: 'notifications', label: 'Notifications', icon: '◈' },
    ],
  },
  {
    label: 'Пользователи',
    items: [{ key: 'users', label: 'Users', icon: '◇' }],
  },
  {
    label: 'Данные проектов',
    items: [
      { key: 'projects', label: 'Projects', icon: '⬡' },
      { key: 'stages', label: 'Stages', icon: '▤' },
      { key: 'approvals', label: 'Approvals', icon: '◉' },
      { key: 'payments', label: 'Payments', icon: '₽' },
      { key: 'materials', label: 'Materials', icon: '▣' },
      { key: 'documents', label: 'Documents', icon: '▧' },
      { key: 'chats', label: 'Chats', icon: '◗' },
    ],
  },
  {
    label: 'Контент',
    items: [
      { key: 'feedback', label: 'Feedback', icon: '✉' },
      { key: 'faq', label: 'FAQ', icon: '?' },
      { key: 'legal', label: 'Legal', icon: '§' },
      { key: 'broadcast', label: 'Broadcasts', icon: '⟸' },
    ],
  },
  {
    label: 'Система',
    items: [{ key: 'settings', label: 'Settings', icon: '⚙' }],
  },
];

export function App() {
  const [authed, setAuthed] = useState<boolean>(!!getToken());
  const [tab, setTab] = useState<Tab>('dashboard');
  const [me, setMe] = useState<any>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => {
    if (!authed) {
      setMe(null);
      return;
    }
    api
      .me()
      .then(setMe)
      .catch(() => {
        // 401 уже очищает токен в request() — просто молча.
      });
  }, [authed]);

  if (!authed) {
    return <Login onSuccess={() => setAuthed(true)} />;
  }

  const pageFor = (t: Tab) => {
    switch (t) {
      case 'dashboard':
        return <Dashboard />;
      case 'users':
        return <UsersPage />;
      case 'projects':
        return <ProjectsPage />;
      case 'stages':
        return <StagesPage />;
      case 'approvals':
        return <ApprovalsPage />;
      case 'payments':
        return <PaymentsPage />;
      case 'materials':
        return <MaterialsPage />;
      case 'documents':
        return <DocumentsPage />;
      case 'chats':
        return <ChatsPage />;
      case 'feedback':
        return <FeedbackList />;
      case 'faq':
        return <FaqEditor />;
      case 'legal':
        return <LegalPage />;
      case 'broadcast':
        return <BroadcastPage />;
      case 'notifications':
        return <NotificationLogsPage />;
      case 'audit':
        return <AuditPage />;
      case 'settings':
        return <SettingsPage />;
    }
  };

  const currentLabel =
    GROUPS.flatMap((g) => g.items).find((i) => i.key === tab)?.label ?? '';

  return (
    <div className="shell">
      <aside className={`sidebar ${sidebarOpen ? '' : 'collapsed'}`}>
        <div className="brand">
          <span className="logo">RC</span>
          {sidebarOpen && <span className="brand-text">Repair Control</span>}
        </div>
        <nav className="nav">
          {GROUPS.map((g) => (
            <div key={g.label} className="nav-group">
              {sidebarOpen && <div className="nav-group-title">{g.label}</div>}
              {g.items.map((it) => (
                <button
                  key={it.key}
                  className={`nav-item ${tab === it.key ? 'active' : ''}`}
                  onClick={() => setTab(it.key)}
                  title={it.label}
                >
                  <span className="nav-icon">{it.icon}</span>
                  {sidebarOpen && <span>{it.label}</span>}
                </button>
              ))}
            </div>
          ))}
        </nav>
        <div className="sidebar-footer">
          <button
            className="collapse-btn"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            title={sidebarOpen ? 'Свернуть' : 'Развернуть'}
          >
            {sidebarOpen ? '←' : '→'}
          </button>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="topbar-title">{currentLabel}</div>
          <div className="topbar-user">
            <span className="muted">
              {me
                ? `${me.firstName ?? ''} ${me.lastName ?? ''} · ${me.systemRole ?? 'admin'}`
                : '…'}
            </span>
            <button
              className="secondary"
              onClick={() => {
                if (!confirm('Выйти из админки?')) return;
                setToken(null);
                setAuthed(false);
              }}
            >
              Выход
            </button>
          </div>
        </header>
        <main className="content">{pageFor(tab)}</main>
      </div>
    </div>
  );
}
