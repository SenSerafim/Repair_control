/**
 * Тонкий REST-клиент к backend /api/*. Хранит access token в localStorage.
 * БЕЗ refresh-флоу (если токен истёк — login заново). Для staging-админки хватает.
 */
const BASE = (import.meta as any).env.VITE_API_BASE_URL ?? 'http://localhost:3000';
const TOKEN_KEY = 'rc_admin_access_token';

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string | null): void {
  if (t) localStorage.setItem(TOKEN_KEY, t);
  else localStorage.removeItem(TOKEN_KEY);
}

async function request<T>(
  path: string,
  init: RequestInit = {},
  opts: { authRequired?: boolean } = { authRequired: true },
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(init.headers as Record<string, string> | undefined),
  };
  const token = getToken();
  if (opts.authRequired && token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${BASE}${path}`, { ...init, headers });
  if (res.status === 401) {
    setToken(null);
    throw new Error('unauthorized');
  }
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`${res.status}: ${body}`);
  }
  if (res.status === 204) return undefined as unknown as T;
  return (await res.json()) as T;
}

export const api = {
  login: (phone: string, password: string) =>
    request<{ accessToken: string; refreshToken: string; userId: string }>(
      '/api/auth/login',
      { method: 'POST', body: JSON.stringify({ phone, password }) },
      { authRequired: false },
    ),
  me: () => request<any>('/api/auth/me'),

  // Feedback
  listFeedback: (status?: string) =>
    request<any[]>(`/api/admin/feedback${status ? `?status=${status}` : ''}`),
  patchFeedback: (id: string, status: 'new' | 'read' | 'archived') =>
    request<any>(`/api/admin/feedback/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    }),

  // FAQ
  listFaq: () => request<any[]>(`/api/admin/faq-sections`),
  createSection: (title: string, orderIndex: number) =>
    request<any>(`/api/admin/faq-sections`, {
      method: 'POST',
      body: JSON.stringify({ title, orderIndex }),
    }),
  createItem: (sectionId: string, question: string, answer: string, orderIndex: number) =>
    request<any>(`/api/admin/faq-items`, {
      method: 'POST',
      body: JSON.stringify({ sectionId, question, answer, orderIndex }),
    }),
  updateItem: (id: string, data: { question?: string; answer?: string; orderIndex?: number }) =>
    request<any>(`/api/admin/faq-items/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
  deleteItem: (id: string) => request<void>(`/api/admin/faq-items/${id}`, { method: 'DELETE' }),

  // Settings
  listSettings: () => request<any[]>(`/api/admin/settings`),
  putSetting: (key: string, value: string) =>
    request<any>(`/api/admin/settings`, {
      method: 'PUT',
      body: JSON.stringify({ key, value }),
    }),

  // Notification logs
  logs: (userId?: string) =>
    request<any[]>(`/api/admin/notification-logs${userId ? `?userId=${userId}` : ''}`),
};
