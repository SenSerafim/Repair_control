import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E дополнительные сценарии: edge cases H.1/H.2 (ТЗ §8 спринт 4 день 8,
 * gaps §2.4, §2.5) и методичка (ТЗ §8 спринт 3 день 6 DoD).
 */
describe('Edge cases + Methodology', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-07-25T10:00:00Z'));
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

  // ---- H.1: budget edit after start (gaps §2.5) ----

  it('H.1: customer меняет workBudget после старта стадии → emit stage_budget_edit_after_start', async () => {
    const customer = await reg('+79991110001', 'customer');
    const foreman = await reg('+79991110002', 'contractor');
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
    // Без требования plan approval (упрощаем — устанавливаем напрямую в БД)
    await ctx.prisma.project.update({
      where: { id: projectId },
      data: { requiresPlanApproval: false },
    });
    const stg = await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Этап',
        plannedStart: '2026-07-01',
        plannedEnd: '2026-07-31',
        workBudget: 100_000_00,
        foremanIds: [foreman.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;

    // Запускаем стадию
    await request(server())
      .post(`/api/projects/${projectId}/stages/${stageId}/start`)
      .set(fAuth)
      .expect(201);

    // Customer меняет workBudget с 100 000 ₽ на 150 000 ₽ после старта
    await request(server())
      .patch(`/api/projects/${projectId}/stages/${stageId}`)
      .set(cAuth)
      .send({ workBudget: 150_000_00 })
      .expect(200);

    // В ленте должно быть событие stage_budget_edit_after_start с diff и notifyUserIds
    const events = await ctx.prisma.feedEvent.findMany({
      where: { projectId, kind: 'stage_budget_edit_after_start' },
    });
    expect(events).toHaveLength(1);
    const payload = events[0].payload as any;
    expect(payload.oldWork).toBe(100_000_00);
    expect(payload.newWork).toBe(150_000_00);
    expect(payload.notifyUserIds).toContain(foreman.userId);
  });

  // ---- H.2: foreman removal on active stage (gaps §2.4) ----

  it('H.2: удаление foreman активной стадии → его pending approvals requiresReassign + foreman убран из foremanIds', async () => {
    const customer = await reg('+79992220001', 'customer');
    const foreman1 = await reg('+79992220002', 'contractor');
    const master = await reg('+79992220003', 'master');
    const cAuth = { Authorization: `Bearer ${customer.token}` };
    const fAuth = { Authorization: `Bearer ${foreman1.token}` };
    const mAuth = { Authorization: `Bearer ${master.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'X', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);
    const projectId = proj.body.id as string;
    const fMembership = await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: foreman1.userId, role: 'foreman' })
      .expect(201);
    await request(server())
      .post(`/api/projects/${projectId}/members`)
      .set(cAuth)
      .send({ userId: master.userId, role: 'master' })
      .expect(201);
    // Снимаем требование plan approval для простоты
    await ctx.prisma.project.update({
      where: { id: projectId },
      data: { requiresPlanApproval: false },
    });
    const stg = await request(server())
      .post(`/api/projects/${projectId}/stages`)
      .set(cAuth)
      .send({
        title: 'Этап',
        plannedStart: '2026-07-01',
        plannedEnd: '2026-07-31',
        foremanIds: [foreman1.userId],
      })
      .expect(201);
    const stageId = stg.body.id as string;
    await request(server())
      .post(`/api/projects/${projectId}/stages/${stageId}/start`)
      .set(fAuth)
      .expect(201);

    // master создаёт extra step — открывается Approval с addressee=customer.
    // Создаём также approval scope=step на foreman (через API — маппится через request).
    const stepReq = await request(server())
      .post(`/api/projects/${projectId}/approvals`)
      .set(mAuth)
      .send({
        scope: 'step',
        stageId,
        stepId: (
          await request(server())
            .post(`/api/stages/${stageId}/steps`)
            .set(fAuth)
            .send({ title: 'Шаг' })
            .expect(201)
        ).body.id,
        addresseeId: foreman1.userId,
      })
      .expect(201);
    const approvalId = stepReq.body.id as string;
    expect(stepReq.body.status).toBe('pending');

    // Customer удаляет foreman
    await request(server())
      .delete(`/api/projects/${projectId}/members/${fMembership.body.id}`)
      .set(cAuth)
      .expect(200);

    // Approval должен быть помечен requiresReassign=true
    const approvalAfter = await ctx.prisma.approval.findUnique({ where: { id: approvalId } });
    expect(approvalAfter!.requiresReassign).toBe(true);
    expect(approvalAfter!.status).toBe('pending');

    // foremanIds стадии очищен
    const stageAfter = await ctx.prisma.stage.findUnique({ where: { id: stageId } });
    expect(stageAfter!.foremanIds).not.toContain(foreman1.userId);

    // Master membership НЕ удалено (foreman removal не трогает мастеров)
    const masterMembership = await ctx.prisma.membership.findFirst({
      where: { projectId, userId: master.userId },
    });
    expect(masterMembership).toBeTruthy();

    // Лента содержит foreman_removed + membership_removed
    const kinds = (
      await ctx.prisma.feedEvent.findMany({ where: { projectId }, orderBy: { createdAt: 'asc' } })
    ).map((e) => e.kind);
    expect(kinds).toContain('foreman_removed');
    expect(kinds).toContain('membership_removed');
  });

  // ---- Methodology: FTS search + ETag (ТЗ §8 спринт 3 день 6 DoD) ----

  it('Methodology search + ETag: seed статьи находятся FTS, ETag выдаётся, If-None-Match → 304', async () => {
    // Методичка засидена glob. setup'ом (seed.ts). Читаем существующие данные.
    const user = await reg('+79993330001', 'customer');
    const uAuth = { Authorization: `Bearer ${user.token}` };

    // Search по «шпатлёвка» — должен найти seed-статью (русская морфология)
    const searchShpat = await request(server())
      .get('/api/methodology/search?q=шпатлёвка')
      .set(uAuth)
      .expect(200);
    expect(searchShpat.body.hits.length).toBeGreaterThan(0);
    expect(searchShpat.body.hits[0].title).toMatch(/Шпатл|швов/i);

    // Search по «кабеля» — найдёт «Прокладка силового кабеля» через русскую лемматизацию
    const searchKabel = await request(server())
      .get('/api/methodology/search?q=кабеля')
      .set(uAuth)
      .expect(200);
    expect(searchKabel.body.hits.length).toBeGreaterThan(0);

    // Найдём первую статью и проверим ETag flow
    const sections = await request(server())
      .get('/api/methodology/sections')
      .set(uAuth)
      .expect(200);
    expect(sections.body.length).toBeGreaterThanOrEqual(2);
    const firstArticleId = sections.body[0].articles[0].id;

    const firstGet = await request(server())
      .get(`/api/methodology/articles/${firstArticleId}`)
      .set(uAuth)
      .expect(200);
    const etag = firstGet.headers['etag'];
    expect(etag).toBeTruthy();

    // Второй GET с If-None-Match → 304
    await request(server())
      .get(`/api/methodology/articles/${firstArticleId}`)
      .set(uAuth)
      .set({ 'If-None-Match': etag })
      .expect(304);
  });

  it('Methodology: non-admin не может создать раздел', async () => {
    const user = await reg('+79994440001', 'customer');
    const uAuth = { Authorization: `Bearer ${user.token}` };
    await request(server())
      .post('/api/admin/methodology/sections')
      .set(uAuth)
      .send({ title: 'X', orderIndex: 99 })
      .expect(403);
  });
});
