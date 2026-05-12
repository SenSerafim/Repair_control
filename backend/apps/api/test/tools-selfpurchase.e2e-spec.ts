import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Tools (self-custody модель, 2026-05-12) + SelfPurchase:
 *  Сценарий «инструмент»: любой member project-а создаёт инструмент в проекте,
 *    другой member self-claim-ит его, owner получает custody history,
 *    customer тоже видит реестр (self-custody — для всех ролей).
 *  Бонус: foreman selfpurchase 8000 → customer approve → budget.materials.spent += 8000.
 */
describe('Sprint 4 DoD — Tools + SelfPurchase', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-07-21T10:00:00Z'));
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

  const idem = (n: string) => ({ 'Idempotency-Key': n });

  it('Сценарий self-custody: создаём в проекте → master self-claim → history фиксируется', async () => {
    const customer = await reg('+79990003001', 'customer');
    const foreman = await reg('+79990003002', 'contractor');
    const master = await reg('+79990003003', 'master');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };
    const mAuth = { Authorization: `Bearer ${master.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'Ремонт', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);
    const projectId = proj.body.id as string;
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: master.userId, role: 'master' })
      .expect(201);

    // Foreman создаёт инструмент сразу в проекте — owner=foreman, holder=foreman
    const tool = await request(server())
      .post(`/api/projects/${projectId}/tools`)
      .set(fAuth)
      .send({ name: 'Перфоратор Makita' })
      .expect(201);
    const toolId = tool.body.id as string;
    expect(tool.body.ownerId).toBe(foreman.userId);
    expect(tool.body.currentHolderId).toBe(foreman.userId);

    // Master видит инструмент в списке проекта
    const projectTools = await request(server())
      .get(`/api/projects/${projectId}/tools`)
      .set(mAuth)
      .expect(200);
    expect(projectTools.body).toHaveLength(1);
    expect(projectTools.body[0].currentHolderId).toBe(foreman.userId);

    // Master self-claim → holder теперь master
    const claimed = await request(server())
      .post(`/api/tools/${toolId}/claim`)
      .set(mAuth)
      .send({ note: 'забрал на 3 этаж' })
      .expect(200);
    expect(claimed.body.currentHolderId).toBe(master.userId);

    // Повторный self-claim того же мастера — 409
    await request(server()).post(`/api/tools/${toolId}/claim`).set(mAuth).send({}).expect(409);

    // Customer тоже видит реестр (self-custody модель — для всех ролей)
    const customerTools = await request(server())
      .get(`/api/projects/${projectId}/tools`)
      .set(cAuth)
      .expect(200);
    expect(customerTools.body[0].currentHolderId).toBe(master.userId);

    // История передач: 2 события (initial owner + claim by master)
    const history = await request(server())
      .get(`/api/tools/${toolId}/custody-history`)
      .set(fAuth)
      .expect(200);
    expect(history.body).toHaveLength(2);
    expect(history.body[0].holderId).toBe(master.userId);
    expect(history.body[0].previousHolderId).toBe(foreman.userId);
    expect(history.body[1].previousHolderId).toBeNull();

    // Feed event
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('tool_added_to_project');
    expect(kinds).toContain('tool_custody_changed');
  });

  it('SelfPurchase foreman 8000 → customer approve → budget.materials.spent += 8000', async () => {
    const customer = await reg('+79990004001', 'customer');
    const foreman = await reg('+79990004002', 'contractor');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'X', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);
    const projectId = proj.body.id as string;
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);
    await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Этап',
        plannedStart: '2026-07-01',
        plannedEnd: '2026-07-31',
        materialsBudget: 50_000_00,
        foremanIds: [foreman.userId],
      })
      .expect(201);

    // Foreman делает самозакуп 8000₽
    const sp = await request(server())
      .post(`/api/projects/${projectId}/selfpurchases`)
      .set(fAuth)
      .set(idem('sp-1'))
      .send({ amount: 8_000_00, comment: 'Крепёж', photoKeys: ['scope/a.jpg'] })
      .expect(201);
    expect(sp.body.status).toBe('pending');
    expect(sp.body.addresseeId).toBe(customer.userId);
    expect(sp.body.byRole).toBe('foreman');

    // Customer approve
    await request(server()).post(`/api/selfpurchases/${sp.body.id}/approve`).set(cAuth).expect(200);

    // Budget.materials.spent = 8000₽
    const budget = await request(server())
      .get(`/api/projects/${projectId}/budget`)
      .set(cAuth)
      .expect(200);
    expect(budget.body.materials.spent).toBe(8_000_00);
    expect(budget.body.materials.planned).toBe(50_000_00);
    expect(budget.body.materials.remaining).toBe(50_000_00 - 8_000_00);

    // Лента содержит selfpurchase_*
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('selfpurchase_created');
    expect(kinds).toContain('selfpurchase_approved');
    expect(kinds).toContain('budget_updated');
  });

  it('SelfPurchase reject без comment → 400, а с comment → rejected без budget_updated', async () => {
    const customer = await reg('+79990005001', 'customer');
    const foreman = await reg('+79990005002', 'contractor');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'X', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);
    const projectId = proj.body.id as string;
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);

    const sp = await request(server())
      .post(`/api/projects/${projectId}/selfpurchases`)
      .set(fAuth)
      .set(idem('sp-rej'))
      .send({ amount: 1_000_00 })
      .expect(201);

    await request(server()).post(`/api/selfpurchases/${sp.body.id}/reject`).set(cAuth).expect(400);

    await request(server())
      .post(`/api/selfpurchases/${sp.body.id}/reject`)
      .set(cAuth)
      .send({ comment: 'не нужно' })
      .expect(200);

    const fresh = await ctx.prisma.selfPurchase.findUnique({ where: { id: sp.body.id } });
    expect(fresh!.status).toBe('rejected');
  });
});
