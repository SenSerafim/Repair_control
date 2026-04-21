import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Спринта 3 DoD (ТЗ §8 спринт 3):
 *  Сценарий 1 (план): бригадир → план → reject → fix → approve → foreman нажимает Start.
 *  Сценарий 2 (extra_work): бригадир → добавил extra step 12000 ₽ → заказчик approve → stage.workBudget = 12000 ₽.
 */
describe('Sprint 3 DoD — Approvals + Steps extra_work', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-06-01T10:00:00Z'));
  });

  afterAll(async () => {
    await closeTestApp(ctx);
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
  });

  const server = () => ctx.app.getHttpServer();

  async function registerAndLogin(phone: string, role = 'customer') {
    const reg = await request(server())
      .post('/api/auth/register')
      .send({
        phone,
        password: 'qwerty1234',
        firstName: 'T',
        lastName: 'U',
        role,
      })
      .expect(201);
    return { token: reg.body.accessToken as string, userId: reg.body.userId as string };
  }

  it('Сценарий 1: план работ — reject → resubmit → approve → Start работает', async () => {
    const customer = await registerAndLogin('+79990000001', 'customer');
    const foreman = await registerAndLogin('+79990000002', 'contractor');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    // Проект
    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({
        title: 'Ремонт под ключ',
        plannedStart: '2026-06-01',
        plannedEnd: '2026-12-31',
      })
      .expect(201);
    const projectId = proj.body.id as string;

    // Добавить бригадира — это включит requiresPlanApproval=true
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);

    // Заказчик создаёт этап (2026-06-10..06-20)
    const stg = await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Демонтаж',
        plannedStart: '2026-06-10',
        plannedEnd: '2026-06-20',
        foremanIds: [foreman.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;

    // Старт до approve плана должен быть заблокирован (gaps §3.2)
    await request(server())
      .post(`/api/projects/${projectId}/stages/${stageId}/start`)
      .set(fAuth)
      .expect(409);

    // Бригадир подаёт план работ на согласование
    const approval1 = await request(server())
      .post(`/api/projects/${projectId}/approvals`)
      .set(fAuth)
      .send({
        scope: 'plan',
        addresseeId: customer.userId,
        payload: { stages: [{ stageId, plannedEnd: '2026-06-20', workBudget: 100000 }] },
      })
      .expect(201);
    const approvalId = approval1.body.id as string;

    // Заказчик отклоняет
    await request(server())
      .post(`/api/approvals/${approvalId}/reject`)
      .set(cAuth)
      .send({ comment: 'Пересмотрите бюджет' })
      .expect(201);

    // Бригадир resubmit
    const resub = await request(server())
      .post(`/api/approvals/${approvalId}/resubmit`)
      .set(fAuth)
      .send({ payload: { stages: [{ stageId, plannedEnd: '2026-06-20', workBudget: 120000 }] } })
      .expect(201);
    expect(resub.body.attemptNumber).toBe(2);
    expect(resub.body.status).toBe('pending');

    // Заказчик одобряет
    const approved = await request(server())
      .post(`/api/approvals/${approvalId}/approve`)
      .set(cAuth)
      .expect(201);
    expect(approved.body.status).toBe('approved');

    // Теперь проект.planApproved = true → foreman может стартануть этап
    const started = await request(server())
      .post(`/api/projects/${projectId}/stages/${stageId}/start`)
      .set(fAuth)
      .expect(201);
    expect(started.body.status).toBe('active');

    // Проверка в БД: project.planApproved=true
    const project = await ctx.prisma.project.findUnique({ where: { id: projectId } });
    expect(project?.planApproved).toBe(true);
    expect(project?.requiresPlanApproval).toBe(true);

    // В ленте есть plan_approved и stage_started
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('plan_approved');
    expect(kinds).toContain('stage_started');
  });

  it('Сценарий 2: extra_work 12000 ₽ → approve → workBudget увеличился на 12000', async () => {
    const customer = await registerAndLogin('+79990000003', 'customer');
    const foreman = await registerAndLogin('+79990000004', 'contractor');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    // Проект
    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({
        title: 'Электромонтаж',
        plannedStart: '2026-06-01',
        plannedEnd: '2026-12-31',
      })
      .expect(201);
    const projectId = proj.body.id as string;
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman.userId, role: 'foreman' })
      .expect(201);

    // Этап с workBudget = 100000
    const stg = await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Электрика',
        plannedStart: '2026-06-02',
        plannedEnd: '2026-06-30',
        workBudget: 100000,
        foremanIds: [foreman.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;

    // Бригадир создаёт extra step (создаст Approval scope=extra_work автоматически)
    const step = await request(server())
      .post(`/api/stages/${stageId}/steps`)
      .set(fAuth)
      .send({
        title: 'Ревизия розеток',
        type: 'extra',
        price: 12000,
      })
      .expect(201);
    expect(step.body.status).toBe('pending_approval');

    // Проверка: бюджет этапа ещё не увеличен (ТЗ §4.3)
    const stageBefore = await ctx.prisma.stage.findUnique({ where: { id: stageId } });
    expect(Number(stageBefore!.workBudget)).toBe(100000);

    // Находим созданный Approval
    const approvals = await request(server())
      .get(`/api/projects/${projectId}/approvals?scope=extra_work&status=pending`)
      .set(cAuth)
      .expect(200);
    expect(approvals.body).toHaveLength(1);
    const approvalId = approvals.body[0].id as string;

    // Заказчик одобряет
    await request(server()).post(`/api/approvals/${approvalId}/approve`).set(cAuth).expect(201);

    // Теперь workBudget увеличен на 12000; step.status = pending (в работу)
    const stageAfter = await ctx.prisma.stage.findUnique({ where: { id: stageId } });
    expect(Number(stageAfter!.workBudget)).toBe(112000);

    const stepAfter = await ctx.prisma.step.findUnique({ where: { id: step.body.id } });
    expect(stepAfter!.status).toBe('pending');

    // Событие budget_updated в ленте
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('extra_work_requested');
    expect(kinds).toContain('approval_approved');
    expect(kinds).toContain('budget_updated');
  });

  it('Сценарий 2b: extra_work rejected → step.status=rejected, бюджет не меняется', async () => {
    const customer = await registerAndLogin('+79990000005', 'customer');
    const foreman = await registerAndLogin('+79990000006', 'contractor');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'X', plannedStart: '2026-06-01', plannedEnd: '2026-12-31' })
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
        title: 'Этап',
        plannedStart: '2026-06-02',
        plannedEnd: '2026-06-30',
        workBudget: 50000,
        foremanIds: [foreman.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;

    const step = await request(server())
      .post(`/api/stages/${stageId}/steps`)
      .set(fAuth)
      .send({ title: 'доп.работа', type: 'extra', price: 5000 })
      .expect(201);

    const approvals = await request(server())
      .get(`/api/projects/${projectId}/approvals?scope=extra_work`)
      .set(cAuth)
      .expect(200);
    const approvalId = approvals.body[0].id as string;

    await request(server())
      .post(`/api/approvals/${approvalId}/reject`)
      .set(cAuth)
      .send({ comment: 'не требуется' })
      .expect(201);

    const stageAfter = await ctx.prisma.stage.findUnique({ where: { id: stageId } });
    expect(Number(stageAfter!.workBudget)).toBe(50000);
    const stepAfter = await ctx.prisma.step.findUnique({ where: { id: step.body.id } });
    expect(stepAfter!.status).toBe('rejected');
  });
});
