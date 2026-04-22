import request from 'supertest';
import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * E2E Спринт 5 — Documents REST (минимум).
 *
 * Покрытие:
 *  - POST /presign-upload → получаем uploadUrl + documentId
 *  - GET list без stageId возвращает все документы (включая stage-level) — авто-дублирование (ТЗ §11)
 *  - Soft-delete: documents/:id DELETE → list больше не возвращает
 */
describe('S5 — Documents REST', () => {
  let ctx: E2EContext;

  beforeAll(async () => {
    ctx = await bootTestApp(new Date('2026-07-24T10:00:00Z'));
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

  it('presign-upload + list + soft-delete', async () => {
    const customer = await reg('+79990007001', 'customer');
    const cAuth = { Authorization: `Bearer ${customer.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'Ремонт', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);
    const projectId = proj.body.id;

    // Presign upload для PDF
    const up = await request(server())
      .post(`/api/projects/${projectId}/documents/presign-upload`)
      .set(cAuth)
      .send({
        title: 'Schema.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 10_000,
        category: 'blueprint',
      })
      .expect(201);
    expect(up.body.documentId).toBeTruthy();
    expect(up.body.uploadUrl).toContain('http');

    // Запись в БД существует в статусе pending
    const docRow = await ctx.prisma.document.findUnique({ where: { id: up.body.documentId } });
    expect(docRow).toBeTruthy();
    expect(docRow?.thumbStatus).toBe('pending');
    expect(docRow?.category).toBe('blueprint');

    // list — документ есть
    const list1 = await request(server())
      .get(`/api/projects/${projectId}/documents`)
      .set(cAuth)
      .expect(200);
    expect(list1.body.length).toBe(1);

    // filter по категории
    const listFiltered = await request(server())
      .get(`/api/projects/${projectId}/documents?category=contract`)
      .set(cAuth)
      .expect(200);
    expect(listFiltered.body.length).toBe(0);

    // soft-delete
    await request(server()).delete(`/api/documents/${up.body.documentId}`).set(cAuth).expect(200);

    const list2 = await request(server())
      .get(`/api/projects/${projectId}/documents`)
      .set(cAuth)
      .expect(200);
    expect(list2.body.length).toBe(0);
  });

  it('DocumentCategory mime-type validation — GIF не разрешён', async () => {
    const customer = await reg('+79990007101', 'customer');
    const cAuth = { Authorization: `Bearer ${customer.token}` };

    const proj = await request(server())
      .post('/api/projects')
      .set(cAuth)
      .send({ title: 'Ремонт', plannedStart: '2026-07-01', plannedEnd: '2026-12-31' })
      .expect(201);

    await request(server())
      .post(`/api/projects/${proj.body.id}/documents/presign-upload`)
      .set(cAuth)
      .send({
        title: 'photo.gif',
        mimeType: 'image/gif',
        sizeBytes: 100,
        category: 'photo',
      })
      .expect(400); // files.mime_not_allowed
  });
});
