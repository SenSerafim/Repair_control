import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E1a — Заявки 2.0. ТЗ NEWFIX §5.7 — флоу частичной приёмки.
 *
 * Сценарий: foreman создаёт заявку → customer подтверждает →
 *   master отмечает доставку → foreman принимает частично →
 *   master отмечает довоз → foreman принимает полностью.
 *
 * Также проверяем RBAC: master НЕ может accept-partial/accept-full.
 */
describe('E1a — Materials acceptance flow (e2e)', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-07-10T10:00:00Z'));
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

  /**
   * Создаёт минимальный проект с тремя ролями: customer-owner, foreman, master.
   * foreman добавлен через invitations API (полный путь). Делаем через прямой
   * insert в Membership, чтобы не плодить boilerplate.
   */
  async function setupProjectWithMembers() {
    const customer = await reg('+79990500001', 'customer');
    const foreman = await reg('+79990500002', 'contractor');
    const master = await reg('+79990500003', 'master');
    const cAuth = { Authorization: `Bearer ${customer.token}` };

    const projRes = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({
        title: 'E1a-test',
        plannedStart: '2026-07-15',
        plannedEnd: '2026-09-15',
        materialsBudget: 1_000_000,
      })
      .expect(201);
    const projectId = projRes.body.id as string;

    // Membership inserts напрямую в БД (минуя инвайт-флоу, который вне scope этого e2e).
    await ctx.prisma.membership.create({
      data: { projectId, userId: foreman.userId, role: 'foreman' },
    });
    await ctx.prisma.membership.create({
      data: { projectId, userId: master.userId, role: 'master' },
    });

    return { customer, foreman, master, projectId };
  }

  async function createOpenRequest(args: {
    projectId: string;
    foremanToken: string;
    customerToken: string;
    items: Array<{ name: string; qty: number; pricePerUnit?: number }>;
  }): Promise<string> {
    // Foreman создаёт → pending_approval + зеркальный Approval(material_purchase).
    const createRes = await request(server())
      .post(`/api/projects/${args.projectId}/materials`)
      .set('Authorization', `Bearer ${args.foremanToken}`)
      .send({
        title: 'Стяжка',
        recipient: 'foreman',
        items: args.items,
      })
      .expect(201);
    expect(createRes.body.status).toBe('pending_approval');
    const requestId = createRes.body.id as string;

    // Customer одобряет зеркальный Approval.
    const approvals = await ctx.prisma.approval.findMany({
      where: { scope: 'material_purchase' },
    });
    expect(approvals).toHaveLength(1);
    await request(server())
      .post(`/api/approvals/${approvals[0].id}/approve`)
      .set('Authorization', `Bearer ${args.customerToken}`)
      .send({})
      .expect(201);

    const after = await ctx.prisma.materialRequest.findUnique({ where: { id: requestId } });
    expect(after?.status).toBe('open');
    return requestId;
  }

  it('полный флоу: pending_approval → open → delivered → accepted_partial → delivered → accepted_full', async () => {
    const { customer, foreman, master, projectId } = await setupProjectWithMembers();

    const requestId = await createOpenRequest({
      projectId,
      foremanToken: foreman.token,
      customerToken: customer.token,
      items: [
        { name: 'Цемент', qty: 40, pricePerUnit: 100 },
        { name: 'Песок', qty: 10, pricePerUnit: 100 },
      ],
    });

    // 1) Master mark-delivered
    const deliveredRes = await request(server())
      .post(`/api/materials/${requestId}/mark-delivered`)
      .set('Authorization', `Bearer ${master.token}`)
      .send({})
      .expect(201);
    expect(deliveredRes.body.status).toBe('delivered');

    // 2) Foreman accept-partial
    const items = await ctx.prisma.materialItem.findMany({ where: { requestId } });
    const cement = items.find((i) => i.name === 'Цемент')!;
    const sand = items.find((i) => i.name === 'Песок')!;

    const partialRes = await request(server())
      .post(`/api/materials/${requestId}/accept-partial`)
      .set('Authorization', `Bearer ${foreman.token}`)
      .send({
        items: [
          { itemId: cement.id, actualQty: 20 },
          { itemId: sand.id, actualQty: 10 },
        ],
      })
      .expect(201);
    expect(partialRes.body.status).toBe('accepted_partial');
    const itemsAfterPartial = await ctx.prisma.materialItem.findMany({ where: { requestId } });
    const cementAfter = itemsAfterPartial.find((i) => i.name === 'Цемент')!;
    expect(cementAfter.actualQty?.toString()).toBe('20');

    // 3) Master mark-delivered (довоз)
    await request(server())
      .post(`/api/materials/${requestId}/mark-delivered`)
      .set('Authorization', `Bearer ${master.token}`)
      .send({})
      .expect(201);

    // 4) Foreman accept-full
    const fullRes = await request(server())
      .post(`/api/materials/${requestId}/accept-full`)
      .set('Authorization', `Bearer ${foreman.token}`)
      .send({})
      .expect(201);
    expect(fullRes.body.status).toBe('accepted_full');

    // 5) Все позиции должны иметь actualQty=qty после full-accept
    const itemsFinal = await ctx.prisma.materialItem.findMany({ where: { requestId } });
    for (const it of itemsFinal) {
      expect(it.actualQty?.toString()).toBe(it.qty.toString());
    }

    // 6) Feed: проверяем что нужные kinds эмитились
    const events = await ctx.prisma.feedEvent.findMany({
      where: {
        projectId,
        kind: {
          in: [
            'material_request_created',
            'material_delivered',
            'material_request_accepted_partial',
            'material_request_accepted_full',
          ],
        },
      },
    });
    const kindsEmitted = new Set(events.map((e) => e.kind));
    expect(kindsEmitted.has('material_request_created')).toBe(true);
    expect(kindsEmitted.has('material_delivered')).toBe(true);
    expect(kindsEmitted.has('material_request_accepted_partial')).toBe(true);
    expect(kindsEmitted.has('material_request_accepted_full')).toBe(true);
  });

  it('RBAC: master не может accept-partial (403)', async () => {
    const { customer, foreman, master, projectId } = await setupProjectWithMembers();
    const requestId = await createOpenRequest({
      projectId,
      foremanToken: foreman.token,
      customerToken: customer.token,
      items: [{ name: 'Цемент', qty: 10, pricePerUnit: 100 }],
    });

    // Доводим до delivered
    await request(server())
      .post(`/api/materials/${requestId}/mark-delivered`)
      .set('Authorization', `Bearer ${master.token}`)
      .send({})
      .expect(201);

    const item = (await ctx.prisma.materialItem.findFirst({ where: { requestId } }))!;

    // Master пробует accept-partial → 403
    await request(server())
      .post(`/api/materials/${requestId}/accept-partial`)
      .set('Authorization', `Bearer ${master.token}`)
      .send({ items: [{ itemId: item.id, actualQty: 5 }] })
      .expect(403);
  });

  it('RBAC: master не может accept-full (403)', async () => {
    const { customer, foreman, master, projectId } = await setupProjectWithMembers();
    const requestId = await createOpenRequest({
      projectId,
      foremanToken: foreman.token,
      customerToken: customer.token,
      items: [{ name: 'Цемент', qty: 5, pricePerUnit: 100 }],
    });
    await request(server())
      .post(`/api/materials/${requestId}/mark-delivered`)
      .set('Authorization', `Bearer ${master.token}`)
      .send({})
      .expect(201);

    await request(server())
      .post(`/api/materials/${requestId}/accept-full`)
      .set('Authorization', `Bearer ${master.token}`)
      .send({})
      .expect(403);
  });
});
