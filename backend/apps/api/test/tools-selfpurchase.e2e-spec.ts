import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Спринта 4 DoD (ТЗ §8 спринт 4 день 8):
 *  Сценарий 3 (инструмент): foreman createToolItem 10шт -> issue master 10 ->
 *    master confirm -> requestReturn 8 -> foreman confirmReturn -> issuedQty=2.
 *    customer GET /tool-issuances -> 403.
 *  Бонус (selfpurchase): foreman selfpurchase 8000 с фото -> customer approve ->
 *    budget.materials.spent увеличен на 8000.
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

  it('Сценарий 3: инструмент issue 10 → confirm → return 8 → issuedQty=2', async () => {
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

    // Foreman создаёт ToolItem на своём профиле
    const tool = await request(server())
      .post('/api/me/tools')
      .set(fAuth)
      .send({ name: 'Перфоратор Makita', totalQty: 10 })
      .expect(201);
    const toolId = tool.body.id as string;
    expect(tool.body.issuedQty).toBe(0);

    // Foreman выдаёт 10шт мастеру
    const iss = await request(server())
      .post(`/api/projects/${projectId}/tool-issuances`)
      .set(fAuth)
      .send({ toolItemId: toolId, toUserId: master.userId, qty: 10 })
      .expect(201);
    const issuanceId = iss.body.id as string;
    expect(iss.body.status).toBe('issued');

    // ToolItem.issuedQty = 10
    let toolDb = await ctx.prisma.toolItem.findUnique({ where: { id: toolId } });
    expect(toolDb!.issuedQty).toBe(10);

    // Мастер подтверждает приёмку
    await request(server())
      .post(`/api/tool-issuances/${issuanceId}/confirm`)
      .set(mAuth)
      .expect(200);

    // Мастер инициирует возврат 8шт
    const retReq = await request(server())
      .post(`/api/tool-issuances/${issuanceId}/return`)
      .set(mAuth)
      .send({ returnedQty: 8 })
      .expect(200);
    expect(retReq.body.status).toBe('return_requested');
    expect(retReq.body.returnedQty).toBe(8);

    // issuedQty ещё 10 (пока бригадир не подтвердил)
    toolDb = await ctx.prisma.toolItem.findUnique({ where: { id: toolId } });
    expect(toolDb!.issuedQty).toBe(10);

    // Бригадир подтверждает возврат
    const confirmedReturn = await request(server())
      .post(`/api/tool-issuances/${issuanceId}/return-confirm`)
      .set(fAuth)
      .expect(200);
    expect(confirmedReturn.body.status).toBe('returned');

    // issuedQty = 10 - 8 = 2 (2шт ещё у мастера)
    toolDb = await ctx.prisma.toolItem.findUnique({ where: { id: toolId } });
    expect(toolDb!.issuedQty).toBe(2);

    // customer GET /tool-issuances → 403 (ТЗ §1.4, инструмент невидим customer-у)
    await request(server()).get(`/api/projects/${projectId}/tool-issuances`).set(cAuth).expect(403);

    // feedEvent содержит tool_*
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('tool_issued');
    expect(kinds).toContain('tool_issuance_confirmed');
    expect(kinds).toContain('tool_return_requested');
    expect(kinds).toContain('tool_returned');
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
