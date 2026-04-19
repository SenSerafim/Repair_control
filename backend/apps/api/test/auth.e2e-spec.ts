import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

describe('Auth E2E (DoD §10: register → login → /me → switch role)', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp();
  });

  afterAll(async () => {
    await closeTestApp(ctx);
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  const server = () => ctx.app.getHttpServer();

  const registerPayload = {
    phone: '+79991112233',
    password: 'qwerty1234',
    firstName: 'Иван',
    lastName: 'Петров',
    role: 'customer' as const,
  };

  it('happy-path: регистрация → логин → /me → добавить роль → переключить → /me отражает изменения', async () => {
    // 1. Register
    const reg = await request(server())
      .post('/api/auth/register')
      .send(registerPayload)
      .expect(201);
    expect(reg.body).toMatchObject({
      userId: expect.any(String),
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
    });

    // 2. Login (новой парой токенов)
    const login = await request(server())
      .post('/api/auth/login')
      .send({ phone: registerPayload.phone, password: registerPayload.password, deviceId: 'd1' })
      .expect(200);
    const token = login.body.accessToken as string;
    expect(login.body.systemRole).toBe('customer');

    // 3. GET /me
    const me1 = await request(server())
      .get('/api/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(me1.body).toMatchObject({
      phone: registerPayload.phone,
      activeRole: 'customer',
      roles: expect.arrayContaining([expect.objectContaining({ role: 'customer' })]),
    });

    // 4. Добавить роль contractor
    await request(server())
      .post('/api/me/roles')
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'contractor' })
      .expect(201);

    // 5. Переключить active role
    await request(server())
      .put('/api/me/active-role')
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'contractor' })
      .expect(200);

    // 6. /me показывает новую activeRole
    const me2 = await request(server())
      .get('/api/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(me2.body.activeRole).toBe('contractor');
    expect(me2.body.roles).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ role: 'customer' }),
        expect.objectContaining({ role: 'contractor' }),
      ]),
    );
  });

  it('отклоняет повторную регистрацию с тем же телефоном', async () => {
    await request(server()).post('/api/auth/register').send(registerPayload).expect(201);
    const res = await request(server())
      .post('/api/auth/register')
      .send(registerPayload)
      .expect(409);
    expect(res.body).toMatchObject({ code: 'auth.phone_in_use' });
  });

  it('неверный пароль → 401 INVALID_CREDENTIALS', async () => {
    await request(server()).post('/api/auth/register').send(registerPayload).expect(201);
    const res = await request(server())
      .post('/api/auth/login')
      .send({ phone: registerPayload.phone, password: 'wrong', deviceId: 'd1' })
      .expect(401);
    expect(res.body).toMatchObject({ code: 'auth.invalid_credentials' });
  });

  it('rate-limit: после 5 неуспешных попыток 6-я блокируется', async () => {
    await request(server()).post('/api/auth/register').send(registerPayload).expect(201);

    for (let i = 0; i < 5; i++) {
      await request(server())
        .post('/api/auth/login')
        .send({ phone: registerPayload.phone, password: 'wrong', deviceId: 'd1' })
        .expect(401);
    }

    // 6-я попытка — даже с правильным паролем — заблокирована
    const blocked = await request(server())
      .post('/api/auth/login')
      .send({ phone: registerPayload.phone, password: registerPayload.password, deviceId: 'd1' })
      .expect(401);
    expect(blocked.body).toMatchObject({ code: 'auth.login_blocked' });
  });

  it('/me без токена → 401', async () => {
    await request(server()).get('/api/me').expect(401);
  });

  it('refresh-token: выдаёт новую пару и инвалидирует старую', async () => {
    await request(server()).post('/api/auth/register').send(registerPayload).expect(201);
    const login = await request(server())
      .post('/api/auth/login')
      .send({ phone: registerPayload.phone, password: registerPayload.password, deviceId: 'd1' })
      .expect(200);
    const refreshed = await request(server())
      .post('/api/auth/refresh')
      .send({ refreshToken: login.body.refreshToken, deviceId: 'd1' })
      .expect(200);
    expect(refreshed.body).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
    });
    expect(refreshed.body.refreshToken).not.toBe(login.body.refreshToken);

    // Старый refresh больше не принимается
    await request(server())
      .post('/api/auth/refresh')
      .send({ refreshToken: login.body.refreshToken, deviceId: 'd1' })
      .expect(401);
  });

  it('нельзя удалить последнюю роль', async () => {
    const reg = await request(server())
      .post('/api/auth/register')
      .send(registerPayload)
      .expect(201);
    const res = await request(server())
      .delete('/api/me/roles/customer')
      .set('Authorization', `Bearer ${reg.body.accessToken}`)
      .expect(400);
    expect(res.body).toMatchObject({ code: 'users.role_cannot_remove_last' });
  });
});
