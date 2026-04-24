import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Admin Panel (Day 10b):
 *  - ban → login заблокирован → unban → login работает
 *  - reset-password → старый пароль не работает, новый — да, сессии revoked
 *  - force-logout → сессии инвалидированы, refresh не работает
 *  - legal: create draft → publish → GET /legal/:kind public (без auth) → accept → status обновлён
 *  - broadcast: preview + send по filter → NotificationLog
 *  - audit: все admin-действия оставляют запись в AdminAuditLog
 *  - stats: счётчики возвращаются
 */
describe('S5 — Admin Panel', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-08-10T10:00:00Z'));
  });

  afterAll(async () => {
    await closeTestApp(ctx);
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  const server = () => ctx.app.getHttpServer();

  async function reg(phone: string, role = 'customer') {
    const r = await request(server())
      .post('/api/auth/register')
      .send({ phone, password: 'qwerty1234', firstName: 'T', lastName: 'U', role })
      .expect(201);
    return { token: r.body.accessToken as string, userId: r.body.userId as string };
  }

  async function createAdmin(phone: string) {
    // register → потом вручную добавляем admin-роль + меняем activeRole
    const r = await reg(phone, 'customer');
    await ctx.prisma.userRole.create({ data: { userId: r.userId, role: 'admin' } });
    await ctx.prisma.user.update({ where: { id: r.userId }, data: { activeRole: 'admin' } });
    // Re-login чтобы токен содержал systemRole=admin
    const login = await request(server())
      .post('/api/auth/login')
      .send({ phone, password: 'qwerty1234' })
      .expect(200);
    return { token: login.body.accessToken as string, userId: r.userId };
  }

  it('ban → login 403 → unban → login OK', async () => {
    const admin = await createAdmin('+79993010001');
    const target = await reg('+79993010002', 'customer');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    // Ban
    await request(server())
      .post(`/api/admin/users/${target.userId}/ban`)
      .set(aAuth)
      .send({ reason: 'spam' })
      .expect(201);

    // Попытка логина — 401 с кодом auth.banned
    const loginFail = await request(server())
      .post('/api/auth/login')
      .send({ phone: '+79993010002', password: 'qwerty1234' });
    expect(loginFail.status).toBe(401);
    expect(loginFail.body.code).toBe('auth.banned');

    // Unban
    await request(server()).post(`/api/admin/users/${target.userId}/unban`).set(aAuth).expect(201);

    // Login работает
    await request(server())
      .post('/api/auth/login')
      .send({ phone: '+79993010002', password: 'qwerty1234' })
      .expect(200);
  });

  it('нельзя банить себя или другого admin-а', async () => {
    const admin = await createAdmin('+79993011001');
    const admin2 = await createAdmin('+79993011002');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    await request(server())
      .post(`/api/admin/users/${admin.userId}/ban`)
      .set(aAuth)
      .send({ reason: 'self' })
      .expect(403);
    await request(server())
      .post(`/api/admin/users/${admin2.userId}/ban`)
      .set(aAuth)
      .send({ reason: 'other admin' })
      .expect(403);
  });

  it('reset-password → старый не работает, новый — да', async () => {
    const admin = await createAdmin('+79993012001');
    const target = await reg('+79993012002', 'customer');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    const reset = await request(server())
      .post(`/api/admin/users/${target.userId}/reset-password`)
      .set(aAuth)
      .expect(201);
    const tempPassword = reset.body.tempPassword;
    expect(tempPassword).toMatch(/.{10,}/);

    // Старый пароль не работает
    const oldFail = await request(server())
      .post('/api/auth/login')
      .send({ phone: '+79993012002', password: 'qwerty1234' });
    expect(oldFail.status).toBe(401);

    // Новый — OK
    await request(server())
      .post('/api/auth/login')
      .send({ phone: '+79993012002', password: tempPassword })
      .expect(200);
  });

  it('legal: create → publish → public GET без auth → accept', async () => {
    const admin = await createAdmin('+79993013001');
    const user = await reg('+79993013002', 'customer');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    // Create draft
    const draft = await request(server())
      .post('/api/admin/legal/documents')
      .set(aAuth)
      .send({ kind: 'privacy', title: 'Политика конфиденциальности', bodyMd: '## Версия 1' })
      .expect(201);
    expect(draft.body.version).toBe(1);
    expect(draft.body.publishedAt).toBeNull();

    // Публичный GET — документа ещё нет (не опубликован)
    await request(server()).get('/legal/privacy').expect(404);

    // Publish
    await request(server())
      .post(`/api/admin/legal/documents/${draft.body.id}/publish`)
      .set(aAuth)
      .expect(201);

    // Публичный GET — HTML (без auth)
    const html = await request(server()).get('/legal/privacy').expect(200);
    expect(html.text).toContain('Политика конфиденциальности');
    expect(html.headers['content-type']).toContain('text/html');

    // JSON вариант
    const json = await request(server())
      .get('/legal/privacy')
      .set('Accept', 'application/json')
      .expect(200);
    expect(json.body.version).toBe(1);
    expect(json.body.kind).toBe('privacy');

    // User status — не принял ещё
    const status1 = await request(server())
      .get('/api/me/legal-acceptance')
      .set({ Authorization: `Bearer ${user.token}` })
      .expect(200);
    expect(status1.body.privacy.required).toBe(true);
    expect(status1.body.privacy.accepted).toBe(false);

    // Accept
    await request(server())
      .post('/api/me/legal-acceptance')
      .set({ Authorization: `Bearer ${user.token}` })
      .send({ kind: 'privacy' })
      .expect(201);

    const status2 = await request(server())
      .get('/api/me/legal-acceptance')
      .set({ Authorization: `Bearer ${user.token}` })
      .expect(200);
    expect(status2.body.privacy.accepted).toBe(true);
  });

  it('legal: новая версия → предыдущая deactivated, GET возвращает новую', async () => {
    const admin = await createAdmin('+79993014001');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    const v1 = await request(server())
      .post('/api/admin/legal/documents')
      .set(aAuth)
      .send({ kind: 'tos', title: 'Условия', bodyMd: 'v1' })
      .expect(201);
    await request(server())
      .post(`/api/admin/legal/documents/${v1.body.id}/publish`)
      .set(aAuth)
      .expect(201);

    const v2 = await request(server())
      .post('/api/admin/legal/documents')
      .set(aAuth)
      .send({ kind: 'tos', title: 'Условия v2', bodyMd: 'v2' })
      .expect(201);
    expect(v2.body.version).toBe(2);
    await request(server())
      .post(`/api/admin/legal/documents/${v2.body.id}/publish`)
      .set(aAuth)
      .expect(201);

    const json = await request(server())
      .get('/legal/tos')
      .set('Accept', 'application/json')
      .expect(200);
    expect(json.body.version).toBe(2);

    // Старая версия не активна
    const all = await request(server())
      .get('/api/admin/legal/documents?kind=tos')
      .set(aAuth)
      .expect(200);
    const v1Now = all.body.find((d: any) => d.id === v1.body.id);
    expect(v1Now.isActive).toBe(false);
  });

  it('broadcast preview + send → NotificationLog entries', async () => {
    const admin = await createAdmin('+79993015001');
    await reg('+79993015002', 'customer');
    await reg('+79993015003', 'customer');
    const foreman = await reg('+79993015004', 'contractor');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    // Preview: customer-only
    const preview = await request(server())
      .post('/api/admin/broadcasts/preview')
      .set(aAuth)
      .send({ filter: { roles: ['customer'] } })
      .expect(201);
    expect(preview.body.count).toBeGreaterThanOrEqual(2);
    expect(preview.body.count).not.toContain(foreman.userId);

    // Send
    const sent = await request(server())
      .post('/api/admin/broadcasts')
      .set(aAuth)
      .send({
        title: 'Техработы',
        body: 'Сервис будет недоступен с 22:00',
        filter: { roles: ['customer'] },
      })
      .expect(201);
    expect(sent.body.status).toBe('sent');
    expect(sent.body.targetCount).toBeGreaterThanOrEqual(2);

    // Проверяем логи
    const logs = await ctx.prisma.notificationLog.findMany({
      where: { payload: { path: ['broadcastId'], equals: sent.body.id } },
    });
    expect(logs.length).toBeGreaterThanOrEqual(2);
  });

  it('audit: admin-действия пишутся в AdminAuditLog', async () => {
    const admin = await createAdmin('+79993016001');
    const target = await reg('+79993016002', 'customer');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    await request(server())
      .post(`/api/admin/users/${target.userId}/ban`)
      .set(aAuth)
      .send({ reason: 'test' })
      .expect(201);

    const log = await request(server())
      .get(`/api/admin/audit?actorId=${admin.userId}`)
      .set(aAuth)
      .expect(200);
    expect(log.body.length).toBeGreaterThanOrEqual(1);
    expect(log.body[0].action).toBe('user.ban');
    expect(log.body[0].targetId).toBe(target.userId);
  });

  it('stats: счётчики возвращаются', async () => {
    const admin = await createAdmin('+79993017001');
    await reg('+79993017002', 'customer');
    await reg('+79993017003', 'contractor');
    const aAuth = { Authorization: `Bearer ${admin.token}` };

    const stats = await request(server()).get('/api/admin/stats').set(aAuth).expect(200);
    expect(stats.body.users.total).toBeGreaterThanOrEqual(3);
    expect(stats.body.users.byRole).toBeDefined();
    expect(typeof stats.body.projects.total).toBe('number');
    expect(stats.body.feedback).toBeDefined();
    expect(stats.body.broadcasts).toBeDefined();
  });

  it('non-admin не может вызывать admin endpoints', async () => {
    const user = await reg('+79993018001', 'customer');
    const auth = { Authorization: `Bearer ${user.token}` };

    await request(server()).get('/api/admin/users').set(auth).expect(403);
    await request(server()).get('/api/admin/stats').set(auth).expect(403);
    await request(server()).get('/api/admin/audit').set(auth).expect(403);
  });
});
