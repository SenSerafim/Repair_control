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

function qs(params?: Record<string, unknown>): string {
  if (!params) return '';
  const u = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null || v === '') continue;
    u.set(k, String(v));
  }
  const s = u.toString();
  return s ? `?${s}` : '';
}

export interface BroadcastFilter {
  roles?: string[];
  userIds?: string[];
  projectIds?: string[];
  platform?: 'ios' | 'android';
  bannedOnly?: boolean;
}

export const api = {
  // ────────── Auth ──────────
  login: (phone: string, password: string) =>
    request<{ accessToken: string; refreshToken: string; userId: string }>(
      '/api/auth/login',
      { method: 'POST', body: JSON.stringify({ phone, password }) },
      { authRequired: false },
    ),
  me: () => request<any>('/api/me'),

  // ────────── Dashboard / audit ──────────
  stats: () => request<Record<string, any>>('/api/admin/stats'),
  audit: (params?: {
    userId?: string;
    actorId?: string;
    action?: string;
    from?: string;
    to?: string;
    limit?: number;
    offset?: number;
  }) => request<any[]>(`/api/admin/audit${qs(params)}`),

  // ────────── Feedback ──────────
  listFeedback: (status?: string) =>
    request<any[]>(`/api/admin/feedback${status ? `?status=${status}` : ''}`),
  patchFeedback: (id: string, status: 'new' | 'read' | 'archived') =>
    request<any>(`/api/admin/feedback/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    }),

  // ────────── FAQ ──────────
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

  // ────────── Settings ──────────
  listSettings: () => request<any[]>(`/api/admin/settings`),
  putSetting: (key: string, value: string) =>
    request<any>(`/api/admin/settings`, {
      method: 'PUT',
      body: JSON.stringify({ key, value }),
    }),

  // ────────── Notification logs ──────────
  logs: (userId?: string) =>
    request<any[]>(`/api/admin/notification-logs${userId ? `?userId=${userId}` : ''}`),

  // ────────── Users (admin) ──────────
  listUsers: (params?: {
    q?: string;
    role?: string;
    banned?: boolean;
    limit?: number;
    offset?: number;
  }) => request<{ items: any[]; total: number }>(`/api/admin/users${qs(params)}`),
  getUser: (id: string) => request<any>(`/api/admin/users/${id}`),
  userAudit: (id: string) => request<any[]>(`/api/admin/users/${id}/audit`),
  banUser: (id: string, reason: string) =>
    request<any>(`/api/admin/users/${id}/ban`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    }),
  unbanUser: (id: string) => request<any>(`/api/admin/users/${id}/unban`, { method: 'POST' }),
  resetPassword: (id: string) =>
    request<{ id: string; tempPassword: string }>(`/api/admin/users/${id}/reset-password`, {
      method: 'POST',
    }),
  forceLogout: (id: string) =>
    request<{ revokedSessions: number }>(`/api/admin/users/${id}/sessions`, {
      method: 'DELETE',
    }),
  setUserRoles: (id: string, roles: string[]) =>
    request<any>(`/api/admin/users/${id}/roles`, {
      method: 'PATCH',
      body: JSON.stringify({ roles }),
    }),

  // ────────── Projects (admin) ──────────
  listProjects: (params?: {
    q?: string;
    status?: string;
    ownerId?: string;
    limit?: number;
    offset?: number;
  }) => request<{ items: any[]; total: number }>(`/api/admin/projects${qs(params)}`),
  getProject: (id: string) => request<any>(`/api/admin/projects/${id}`),
  forceArchive: (id: string, reason: string) =>
    request<any>(`/api/admin/projects/${id}/force-archive`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    }),

  // ────────── Legal documents ──────────
  listLegal: (kind?: string) =>
    request<any[]>(`/api/admin/legal/documents${kind ? `?kind=${kind}` : ''}`),
  getLegal: (id: string) => request<any>(`/api/admin/legal/documents/${id}`),
  createLegal: (kind: string, title: string, bodyMd: string) =>
    request<any>('/api/admin/legal/documents', {
      method: 'POST',
      body: JSON.stringify({ kind, title, bodyMd }),
    }),
  updateLegal: (id: string, data: { title?: string; bodyMd?: string }) =>
    request<any>(`/api/admin/legal/documents/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
  publishLegal: (id: string) =>
    request<any>(`/api/admin/legal/documents/${id}/publish`, { method: 'POST' }),

  // ────────── Broadcasts ──────────
  listBroadcasts: (status?: string) =>
    request<any[]>(`/api/admin/broadcasts${status ? `?status=${status}` : ''}`),
  getBroadcast: (id: string) => request<any>(`/api/admin/broadcasts/${id}`),
  previewBroadcast: (filter: BroadcastFilter) =>
    request<{ count: number; sampleUserIds: string[] }>('/api/admin/broadcasts/preview', {
      method: 'POST',
      body: JSON.stringify({ filter }),
    }),
  sendBroadcast: (data: {
    title: string;
    body: string;
    deepLink?: string;
    filter: BroadcastFilter;
  }) =>
    request<any>('/api/admin/broadcasts', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  // ────────── Global overview (всё в системе) ──────────
  listDocuments: (params?: { projectId?: string; q?: string; limit?: number; offset?: number }) =>
    request<{ items: any[]; total: number }>(`/api/admin/documents${qs(params)}`),
  listPayments: (params?: {
    projectId?: string;
    status?: string;
    kind?: string;
    limit?: number;
    offset?: number;
  }) => request<{ items: any[]; total: number }>(`/api/admin/payments${qs(params)}`),
  listMaterials: (params?: {
    projectId?: string;
    status?: string;
    limit?: number;
    offset?: number;
  }) => request<{ items: any[]; total: number }>(`/api/admin/materials${qs(params)}`),
  listApprovals: (params?: {
    projectId?: string;
    status?: string;
    scope?: string;
    limit?: number;
    offset?: number;
  }) => request<{ items: any[]; total: number }>(`/api/admin/approvals${qs(params)}`),
  listChats: (params?: { projectId?: string; type?: string; limit?: number; offset?: number }) =>
    request<{ items: any[]; total: number }>(`/api/admin/chats${qs(params)}`),
  listStages: (params?: { projectId?: string; status?: string; limit?: number; offset?: number }) =>
    request<{ items: any[]; total: number }>(`/api/admin/stages${qs(params)}`),

  // ────────── User sessions / devices / projects ──────────
  userSessions: (id: string) => request<any[]>(`/api/admin/users/${id}/sessions`),
  userDevices: (id: string) => request<any[]>(`/api/admin/users/${id}/devices`),
  userProjects: (id: string) => request<any[]>(`/api/admin/users/${id}/projects`),

  // ────────── Files (presigned upload) ──────────
  presignUpload: (data: {
    originalName: string;
    mimeType: string;
    sizeBytes: number;
    scope: string;
  }) =>
    request<{ key: string; uploadUrl: string; expiresAt: string }>('/api/files/presign-upload', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  // ────────── Legal Publications (PDF) ──────────
  listLegalPublications: (kind?: string) =>
    request<any[]>(`/api/admin/legal-publications${kind ? `?kind=${kind}` : ''}`),
  getLegalPublication: (id: string) => request<any>(`/api/admin/legal-publications/${id}`),
  createLegalPublication: (data: {
    kind: string;
    slug: string;
    title: string;
    fileKey: string;
    mimeType: string;
    sizeBytes: number;
  }) =>
    request<any>('/api/admin/legal-publications', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateLegalPublication: (
    id: string,
    data: { title?: string; fileKey?: string; mimeType?: string; sizeBytes?: number },
  ) =>
    request<any>(`/api/admin/legal-publications/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
  publishLegalPublication: (id: string) =>
    request<any>(`/api/admin/legal-publications/${id}/publish`, { method: 'POST' }),
  deactivateLegalPublication: (id: string) =>
    request<any>(`/api/admin/legal-publications/${id}`, { method: 'DELETE' }),

  // ────────── Knowledge Base ──────────
  listKnowledgeCategories: () => request<any[]>('/api/admin/knowledge/categories'),
  createKnowledgeCategory: (data: {
    title: string;
    description?: string;
    iconKey?: string;
    scope: 'global' | 'project_module';
    moduleSlug?: string;
    orderIndex?: number;
  }) =>
    request<any>('/api/admin/knowledge/categories', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateKnowledgeCategory: (
    id: string,
    data: {
      title?: string;
      description?: string;
      iconKey?: string;
      scope?: 'global' | 'project_module';
      moduleSlug?: string | null;
      orderIndex?: number;
      isPublished?: boolean;
    },
  ) =>
    request<any>(`/api/admin/knowledge/categories/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
  deleteKnowledgeCategory: (id: string) =>
    request<{ id: string }>(`/api/admin/knowledge/categories/${id}`, {
      method: 'DELETE',
    }),
  // Public read: список статей категории (admin токен подходит)
  getKnowledgeCategory: (id: string) => request<any>(`/api/knowledge/categories/${id}`),
  getKnowledgeArticle: (id: string) => request<any>(`/api/knowledge/articles/${id}`),
  createKnowledgeArticle: (data: {
    categoryId: string;
    title: string;
    body: string;
    orderIndex?: number;
    isPublished?: boolean;
  }) =>
    request<any>('/api/admin/knowledge/articles', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateKnowledgeArticle: (
    id: string,
    data: {
      title?: string;
      body?: string;
      orderIndex?: number;
      isPublished?: boolean;
      categoryId?: string;
    },
  ) =>
    request<any>(`/api/admin/knowledge/articles/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),
  deleteKnowledgeArticle: (id: string) =>
    request<{ id: string }>(`/api/admin/knowledge/articles/${id}`, {
      method: 'DELETE',
    }),
  confirmKnowledgeAsset: (
    articleId: string,
    data: {
      kind: 'image' | 'video' | 'file';
      fileKey: string;
      mimeType: string;
      sizeBytes: number;
      durationSec?: number;
      width?: number;
      height?: number;
      caption?: string;
      orderIndex?: number;
    },
  ) =>
    request<any>(`/api/admin/knowledge/articles/${articleId}/assets`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  setKnowledgeAssetThumbnail: (articleId: string, assetId: string, fileKey: string) =>
    request<any>(`/api/admin/knowledge/articles/${articleId}/assets/${assetId}/thumbnail`, {
      method: 'POST',
      body: JSON.stringify({ fileKey }),
    }),
  deleteKnowledgeAsset: (articleId: string, assetId: string) =>
    request<{ id: string }>(`/api/admin/knowledge/articles/${articleId}/assets/${assetId}`, {
      method: 'DELETE',
    }),
};
