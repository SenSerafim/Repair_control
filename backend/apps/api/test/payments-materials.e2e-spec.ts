import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Спринта 4 DoD (ТЗ §8 спринт 4 день 7):
 *  Сценарий 1 (финансы): customer → выплата 500 000 ₽ → foreman confirm →
 *    distribute 3 мастерам по 100 000 ₽ → каждый confirm → бюджет показывает
 *    корректные planned/spent/remaining.
 *  Сценарий 2 (материалы): заявка 5 позиций Электрика → foreman купил 4 →
 *    finalize → budget.materials.spent = сумма купленных.
 */
describe('Sprint 4 DoD — Payments + Materials', () => {
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

  const idem = (n: string) => ({ 'Idempotency-Key': n });

  it('Сценарий 1: 500k advance → 3×100k distribution → бюджет корректен', async () => {
    const customer = await reg('+79990001001', 'customer');
    const foreman = await reg('+79990001002', 'contractor');
    const m1 = await reg('+79990001003', 'master');
    const m2 = await reg('+79990001004', 'master');
    const m3 = await reg('+79990001005', 'master');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({
        title: 'Электромонтаж',
        plannedStart: '2026-07-01',
        plannedEnd: '2026-12-31',
      })
      .expect(201);
    const projectId = proj.body.id as string;

    // Добавить foreman + 3 master'ов
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);
    for (const m of [m1, m2, m3]) {
      await request(server())
        .post(`/api/projects/${projectId}/members`)
        .set(cAuth)
        .send({ userId: m.userId, role: 'master' })
        .expect(201);
    }

    // Создать этап с бюджетом работ 500k
    const stg = await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Электрика',
        plannedStart: '2026-07-01',
        plannedEnd: '2026-08-31',
        workBudget: 500_000_00,
        foremanIds: [foreman.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;

    // Customer создаёт advance 500k foreman'у
    const advance = await request(server())
      .post(`/api/projects/${projectId}/payments`)
      .set(cAuth)
      .set(idem('adv-500k'))
      .send({
        toUserId: foreman.userId,
        amount: 500_000_00,
        stageId,
        comment: 'Аванс на электрику',
      })
      .expect(201);
    const advanceId = advance.body.id as string;
    expect(advance.body.status).toBe('pending');

    // Идемпотентность: повторный запрос с тем же ключом → тот же ответ
    const replay = await request(server())
      .post(`/api/projects/${projectId}/payments`)
      .set(cAuth)
      .set(idem('adv-500k'))
      .send({
        toUserId: foreman.userId,
        amount: 500_000_00,
        stageId,
        comment: 'Аванс на электрику',
      })
      .expect(201);
    expect(replay.body.id).toBe(advanceId);

    // Foreman подтверждает
    await request(server())
      .post(`/api/payments/${advanceId}/confirm`)
      .set(fAuth)
      .set(idem('adv-500k-confirm'))
      .expect(200);

    // Распределение 3×100k
    for (const [idx, master] of [m1, m2, m3].entries()) {
      await request(server())
        .post(`/api/payments/${advanceId}/distribute`)
        .set(fAuth)
        .set(idem(`dist-${idx}`))
        .send({ toUserId: master.userId, amount: 100_000_00 })
        .expect(201);
    }

    // Мастера подтверждают
    const all = await ctx.prisma.payment.findMany({
      where: { projectId, kind: 'distribution' },
      orderBy: { createdAt: 'asc' },
    });
    expect(all).toHaveLength(3);
    const masterTokens = [m1, m2, m3].map((m) => m.token);
    for (let i = 0; i < 3; i++) {
      await request(server())
        .post(`/api/payments/${all[i].id}/confirm`)
        .set({ Authorization: `Bearer ${masterTokens[i]}` })
        .set(idem(`confirm-${i}`))
        .expect(200);
    }

    // Проверяем бюджет со стороны customer (owner видит всё)
    const budget = await request(server())
      .get(`/api/projects/${projectId}/budget`)
      .set(cAuth)
      .expect(200);
    expect(budget.body.work.planned).toBe(500_000_00);
    expect(budget.body.work.spent).toBe(500_000_00);
    expect(budget.body.work.remaining).toBe(0);

    // В ленте должны быть budget_updated события
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('payment_created');
    expect(kinds).toContain('payment_confirmed');
    expect(kinds).toContain('payment_distributed');
    expect(kinds).toContain('budget_updated');
  });

  it('Сценарий 2: 5 материалов → куплено 4 → finalize → бюджет учитывает купленное', async () => {
    const customer = await reg('+79990002001', 'customer');
    const foreman = await reg('+79990002002', 'contractor');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'Э2', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);
    const projectId = proj.body.id as string;
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);
    const stg = await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Электрика',
        plannedStart: '2026-07-01',
        plannedEnd: '2026-07-31',
        workBudget: 100_000_00,
        materialsBudget: 50_000_00,
        foremanIds: [foreman.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;

    // Foreman создаёт заявку на 5 позиций
    const req0 = await request(server())
      .post(`/api/projects/${projectId}/materials`)
      .set(fAuth)
      .send({
        recipient: 'foreman',
        title: 'Электрика (список)',
        stageId,
        items: [
          { name: 'Кабель', qty: 100, unit: 'м', pricePerUnit: 50_00 }, // 5k
          { name: 'Розетки', qty: 20, unit: 'шт', pricePerUnit: 300_00 }, // 6k
          { name: 'Выключатели', qty: 10, unit: 'шт', pricePerUnit: 250_00 }, // 2.5k
          { name: 'Коробки', qty: 15, unit: 'шт', pricePerUnit: 100_00 }, // 1.5k
          { name: 'Клеммы', qty: 50, unit: 'шт', pricePerUnit: 20_00 }, // 1k
        ],
      })
      .expect(201);
    const requestId = req0.body.id as string;
    expect(req0.body.status).toBe('draft');

    await request(server()).post(`/api/materials/${requestId}/send`).set(fAuth).expect(200);

    // Покупаем 4 из 5 позиций (все кроме последней, Клеммы)
    const full = await ctx.prisma.materialItem.findMany({
      where: { requestId },
      orderBy: { createdAt: 'asc' },
    });
    for (let i = 0; i < 4; i++) {
      await request(server())
        .post(`/api/materials/${requestId}/items/${full[i].id}/bought`)
        .set(fAuth)
        .send({ pricePerUnit: Number(full[i].pricePerUnit!) })
        .expect(200);
    }

    // Статус заявки — partially_bought
    const partial = await ctx.prisma.materialRequest.findUnique({ where: { id: requestId } });
    expect(partial!.status).toBe('partially_bought');

    // Finalize частично
    await request(server())
      .post(`/api/materials/${requestId}/finalize`)
      .set(fAuth)
      .set(idem('fin-1'))
      .expect(200);

    // Бюджет: materials.spent = 5000+6000+2500+1500 = 15000 (в рублях) = 15_000_00 копеек
    const budget = await request(server())
      .get(`/api/projects/${projectId}/budget`)
      .set(cAuth)
      .expect(200);
    const expectedSpent = 5_000_00 + 6_000_00 + 2_500_00 + 1_500_00;
    expect(budget.body.materials.spent).toBe(expectedSpent);
    expect(budget.body.materials.planned).toBe(50_000_00);
    expect(budget.body.materials.remaining).toBe(50_000_00 - expectedSpent);
  });
});
