import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Спринт 5 — Notification settings REST.
 *
 * Покрытие (оффлайн, без реального FCM — FCM_ENABLED=false):
 *  - GET /me/notification-settings возвращает все kind + priority + дефолт pushEnabled=true
 *  - PATCH на critical (approval_requested) с pushEnabled=false → 400
 *  - PATCH на high (chat_message_new) с pushEnabled=false → OK, повторный GET показывает false
 */
describe('S5 — Notification settings', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-07-23T10:00:00Z'));
  });

  afterAll(async () => {
    await closeTestApp(ctx);
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  const server = () => ctx.app.getHttpServer();

  async function reg(phone: string) {
    const r = await request(server())
      .post('/api/auth/register')
      .send({ phone, password: 'qwerty1234', firstName: 'T', lastName: 'U', role: 'customer' })
      .expect(201);
    return { token: r.body.accessToken as string, userId: r.body.userId as string };
  }

  it('settings — критичные нельзя отключить, высокие можно', async () => {
    const me = await reg('+79990006001');
    const auth = { Authorization: `Bearer ${me.token}` };

    const r = await request(server()).get('/api/me/notification-settings').set(auth).expect(200);
    expect(Array.isArray(r.body)).toBe(true);
    // Все — pushEnabled: true по умолчанию
    expect(r.body.every((s: any) => s.pushEnabled === true)).toBe(true);
    // Есть хотя бы один critical и один high
    expect(r.body.some((s: any) => s.critical)).toBe(true);
    expect(r.body.some((s: any) => !s.critical)).toBe(true);

    // Critical нельзя отключить
    await request(server())
      .patch('/api/me/notification-settings')
      .set(auth)
      .send({ kind: 'approval_requested', pushEnabled: false })
      .expect(400);

    // High можно
    await request(server())
      .patch('/api/me/notification-settings')
      .set(auth)
      .send({ kind: 'chat_message_new', pushEnabled: false })
      .expect(200);

    const r2 = await request(server()).get('/api/me/notification-settings').set(auth).expect(200);
    const chatSetting = r2.body.find((s: any) => s.kind === 'chat_message_new');
    expect(chatSetting?.pushEnabled).toBe(false);
  });
});
