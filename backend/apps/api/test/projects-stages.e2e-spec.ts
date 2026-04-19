import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

describe('Projects + Stages E2E (DoD §10: 3 шаблона → start → pause → resume → пересчёт дедлайна)', () => {
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

  async function registerAndLogin(phone: string, role = 'customer'): Promise<string> {
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
    return reg.body.accessToken as string;
  }

  it('Сквозной сценарий S2 DoD', async () => {
    const token = await registerAndLogin('+79991112233');
    const auth = { Authorization: `Bearer ${token}` };

    // 1. Создать проект
    const proj = await request(server())
      .post('/api/projects')
      .set(auth)
      .send({
        title: 'Квартира на Петровской',
        plannedStart: '2026-06-01',
        plannedEnd: '2026-12-31',
        workBudget: 500000,
        materialsBudget: 300000,
      })
      .expect(201);
    const projectId = proj.body.id as string;

    // 2. Забрать 8 платформенных шаблонов, взять первые 3 (Демонтаж, Электрика, Сантехника)
    const tpls = await request(server()).get('/api/templates/platform').set(auth).expect(200);
    expect(tpls.body.length).toBe(8);
    const firstThree = ['Демонтаж', 'Электрика', 'Сантехника']
      .map((title: string) => tpls.body.find((t: any) => t.title === title))
      .filter(Boolean);
    expect(firstThree).toHaveLength(3);

    // 3. Применить 3 шаблона к проекту
    for (let i = 0; i < 3; i++) {
      await request(server())
        .post(`/api/templates/${firstThree[i].id}/apply`)
        .set(auth)
        .send({ projectId, plannedEnd: '2026-07-01' })
        .expect(201);
    }

    // 4. Проверить 3 этапа с orderIndex 0/1/2
    const stages = await request(server())
      .get(`/api/projects/${projectId}/stages`)
      .set(auth)
      .expect(200);
    expect(stages.body).toHaveLength(3);
    expect(stages.body.map((s: any) => s.orderIndex)).toEqual([0, 1, 2]);
    expect(stages.body.map((s: any) => s.title)).toEqual(['Демонтаж', 'Электрика', 'Сантехника']);

    // 5. Запустить первый этап
    const firstStageId = stages.body[0].id;
    const started = await request(server())
      .post(`/api/projects/${projectId}/stages/${firstStageId}/start`)
      .set(auth)
      .expect(201);
    expect(started.body.status).toBe('active');
    expect(started.body.startedAt).toBeTruthy();

    // 6. Поставить на паузу с причиной
    const pausedAt = new Date('2026-06-10T10:00:00Z');
    ctx.clock.set(pausedAt);
    await request(server())
      .post(`/api/projects/${projectId}/stages/${firstStageId}/pause`)
      .set(auth)
      .send({ reason: 'materials', comment: 'ждём плитку' })
      .expect(201);

    // 7. Advance time by 2 дня и resume
    const TWO_DAYS_MS = 2 * 24 * 60 * 60 * 1000;
    ctx.clock.set(new Date(pausedAt.getTime() + TWO_DAYS_MS));
    const resumed = await request(server())
      .post(`/api/projects/${projectId}/stages/${firstStageId}/resume`)
      .set(auth)
      .expect(201);

    expect(resumed.body.status).toBe('active');
    // Пауза накоплена
    expect(Number(resumed.body.pauseDurationMs)).toBeGreaterThanOrEqual(TWO_DAYS_MS - 5000);
    expect(Number(resumed.body.pauseDurationMs)).toBeLessThanOrEqual(TWO_DAYS_MS + 5000);
    // Дедлайн сдвинулся
    const originalEnd = new Date('2026-07-01').getTime();
    const newEnd = new Date(resumed.body.plannedEnd).getTime();
    expect(newEnd).toBeGreaterThanOrEqual(originalEnd + TWO_DAYS_MS - 5000);

    // 8. Лента содержит нужные события
    const events = await ctx.prisma.feedEvent.findMany({
      where: { projectId },
      orderBy: { createdAt: 'asc' },
    });
    const kinds = events.map((e) => e.kind);
    expect(kinds).toEqual(
      expect.arrayContaining([
        'project_created',
        'stage_created',
        'stage_started',
        'stage_paused',
        'stage_resumed',
        'stage_deadline_recalculated',
      ]),
    );
  });

  it('запрет self-foreman: owner не может добавить себя бригадиром', async () => {
    const token = await registerAndLogin('+79992223344');
    const auth = { Authorization: `Bearer ${token}` };
    const me = await request(server()).get('/api/me').set(auth).expect(200);
    const proj = await request(server())
      .post('/api/projects')
      .set(auth)
      .send({ title: 'Свой проект' })
      .expect(201);
    const res = await request(server())
      .post(`/api/projects/${proj.body.id}/members`)
      .set(auth)
      .send({ userId: me.body.id, role: 'foreman' })
      .expect(400);
    expect(res.body).toMatchObject({ code: 'projects.self_foreman_forbidden' });
  });

  it('copy: копирует название и этапы, не копирует прогресс-кэш', async () => {
    const token = await registerAndLogin('+79993334455');
    const auth = { Authorization: `Bearer ${token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(auth)
      .send({ title: 'Оригинал', workBudget: 100000 })
      .expect(201);
    const tpls = await request(server()).get('/api/templates/platform').set(auth).expect(200);
    await request(server())
      .post(`/api/templates/${tpls.body[0].id}/apply`)
      .set(auth)
      .send({ projectId: proj.body.id })
      .expect(201);

    const copy = await request(server())
      .post(`/api/projects/${proj.body.id}/copy`)
      .set(auth)
      .send({ newTitle: 'Копия квартиры' })
      .expect(201);
    expect(copy.body.title).toBe('Копия квартиры');
    expect(copy.body.progressCache).toBe(0);
    expect(copy.body.workBudget).toBe(100000);

    const copiedStages = await request(server())
      .get(`/api/projects/${copy.body.id}/stages`)
      .set(auth)
      .expect(200);
    expect(copiedStages.body).toHaveLength(1);
  });

  it('pause без reason → валидация 400', async () => {
    const token = await registerAndLogin('+79994445566');
    const auth = { Authorization: `Bearer ${token}` };
    const proj = await request(server())
      .post('/api/projects')
      .set(auth)
      .send({ title: 'P' })
      .expect(201);
    const tpls = await request(server()).get('/api/templates/platform').set(auth).expect(200);
    const applied = await request(server())
      .post(`/api/templates/${tpls.body[0].id}/apply`)
      .set(auth)
      .send({ projectId: proj.body.id })
      .expect(201);
    await request(server())
      .post(`/api/projects/${proj.body.id}/stages/${applied.body.id}/start`)
      .set(auth)
      .expect(201);
    await request(server())
      .post(`/api/projects/${proj.body.id}/stages/${applied.body.id}/pause`)
      .set(auth)
      .send({})
      .expect(400);
  });
});
