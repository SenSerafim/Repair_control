import { ProjectReportPdfService, ReportViewer } from './project-report-pdf.service';

type Prisma = ConstructorParameters<typeof ProjectReportPdfService>[0];
type Files = ConstructorParameters<typeof ProjectReportPdfService>[1];

const PROJECT_ID = 'p1';
const OWNER_ID = 'u-owner';
const REP_ID = 'u-rep';
const FOREMAN_A_ID = 'u-foreman-A';
const FOREMAN_B_ID = 'u-foreman-B';
const MASTER_A_ID = 'u-master-A';
const MASTER_OWN_ID = 'u-master-direct';
const MASTER_B_ID = 'u-master-B';

const STAGE_A = 'st-A';
const STAGE_B = 'st-B';

const USERS = {
  [OWNER_ID]: { firstName: 'Иван', lastName: 'Заказчиков', phone: '+79000000001' },
  [REP_ID]: { firstName: 'Анна', lastName: 'Помощникова', phone: '+79000000002' },
  [FOREMAN_A_ID]: { firstName: 'Пётр', lastName: 'Бригадиров-А', phone: '+79000000003' },
  [FOREMAN_B_ID]: { firstName: 'Олег', lastName: 'Бригадиров-Б', phone: '+79000000004' },
  [MASTER_A_ID]: { firstName: 'Сергей', lastName: 'Мастеров-А', phone: '+79000000005' },
  [MASTER_OWN_ID]: { firstName: 'Дмитрий', lastName: 'ПрямойМастер', phone: '+79000000006' },
  [MASTER_B_ID]: { firstName: 'Виктор', lastName: 'Мастеров-Б', phone: '+79000000007' },
} as const;

function makePrisma(): Prisma {
  const project = {
    id: PROJECT_ID,
    ownerId: OWNER_ID,
    title: 'Ремонт квартиры',
    address: 'СПб, Невский 1',
    description: 'Капитальный ремонт двухкомнатной квартиры',
    status: 'active',
    workBudget: 2_000_000_00n,
    materialsBudget: 4_000_000_00n,
    progressCache: 40,
    semaphoreCache: 'green',
    plannedStart: new Date(Date.UTC(2026, 0, 15)),
    plannedEnd: new Date(Date.UTC(2026, 5, 30)),
    archivedAt: null,
    createdAt: new Date(Date.UTC(2026, 0, 1)),
    owner: USERS[OWNER_ID],
  };
  const memberships = [
    {
      userId: OWNER_ID,
      role: 'customer',
      stageIds: [],
      invitedById: null,
      user: USERS[OWNER_ID],
      createdAt: new Date(0),
    },
    {
      userId: REP_ID,
      role: 'representative',
      stageIds: [],
      invitedById: OWNER_ID,
      user: USERS[REP_ID],
      createdAt: new Date(0),
    },
    {
      userId: FOREMAN_A_ID,
      role: 'foreman',
      stageIds: [STAGE_A],
      invitedById: OWNER_ID,
      user: USERS[FOREMAN_A_ID],
      createdAt: new Date(0),
    },
    {
      userId: FOREMAN_B_ID,
      role: 'foreman',
      stageIds: [STAGE_B],
      invitedById: OWNER_ID,
      user: USERS[FOREMAN_B_ID],
      createdAt: new Date(0),
    },
    {
      userId: MASTER_A_ID,
      role: 'master',
      stageIds: [STAGE_A],
      invitedById: FOREMAN_A_ID,
      user: USERS[MASTER_A_ID],
      createdAt: new Date(0),
    },
    {
      userId: MASTER_OWN_ID,
      role: 'master',
      stageIds: [],
      invitedById: OWNER_ID,
      user: USERS[MASTER_OWN_ID],
      createdAt: new Date(0),
    },
    {
      userId: MASTER_B_ID,
      role: 'master',
      stageIds: [STAGE_B],
      invitedById: FOREMAN_B_ID,
      user: USERS[MASTER_B_ID],
      createdAt: new Date(0),
    },
  ];
  const stages = [
    {
      id: STAGE_A,
      title: 'Демонтаж',
      orderIndex: 0,
      status: 'active',
      pendingApproval: false,
      plannedStart: new Date(Date.UTC(2026, 0, 20)),
      plannedEnd: new Date(Date.UTC(2026, 1, 20)),
      startedAt: new Date(Date.UTC(2026, 0, 21)),
      doneAt: null,
      progressCache: 50,
      foremanIds: [FOREMAN_A_ID],
      masterId: MASTER_A_ID,
      workBudget: 400_000_00n,
      materialsBudget: 100_000_00n,
      pauses: [
        {
          startedAt: new Date(Date.UTC(2026, 0, 25)),
          endedAt: new Date(Date.UTC(2026, 0, 27)),
          reason: 'waiting_materials',
          comment: 'Ждём поставку плитки',
        },
      ],
      steps: [
        {
          id: 'step-A-1',
          title: 'Снять обои',
          orderIndex: 0,
          status: 'done',
          description: 'Снять все обои в спальне',
          whatDid: 'Снято полностью',
          howDid: 'Шпателем + пар',
          price: 15_000_00n,
          doneAt: new Date(Date.UTC(2026, 0, 22)),
          doneById: MASTER_A_ID,
          photos: [
            {
              id: 'ph1',
              fileKey: 'photos/A1.jpg',
              mimeType: 'image/jpeg',
              sizeBytes: 100,
              uploadedBy: MASTER_A_ID,
              exifCleared: true,
              createdAt: new Date(0),
            },
          ],
          substeps: [
            { text: 'Левая стена', isDone: true, doneAt: new Date(Date.UTC(2026, 0, 21)) },
            { text: 'Правая стена', isDone: true, doneAt: new Date(Date.UTC(2026, 0, 22)) },
          ],
          questions: [
            {
              text: 'Утилизировать или вынести?',
              authorId: MASTER_A_ID,
              addresseeId: FOREMAN_A_ID,
              status: 'closed',
              answer: 'Утилизировать',
              answeredAt: new Date(Date.UTC(2026, 0, 22)),
            },
          ],
        },
      ],
    },
    {
      id: STAGE_B,
      title: 'Электрика',
      orderIndex: 1,
      status: 'active',
      pendingApproval: false,
      plannedStart: new Date(Date.UTC(2026, 1, 1)),
      plannedEnd: new Date(Date.UTC(2026, 2, 30)),
      startedAt: null,
      doneAt: null,
      progressCache: 0,
      foremanIds: [FOREMAN_B_ID],
      masterId: MASTER_B_ID,
      workBudget: 700_000_00n,
      materialsBudget: 200_000_00n,
      pauses: [],
      steps: [
        {
          id: 'step-B-1',
          title: 'Развести кабели',
          orderIndex: 0,
          status: 'pending',
          description: null,
          whatDid: null,
          howDid: null,
          price: null,
          doneAt: null,
          doneById: null,
          photos: [],
          substeps: [],
          questions: [],
        },
      ],
    },
  ];

  const documents = [
    {
      id: 'd-proj',
      title: 'Договор подряда',
      category: 'contract',
      stageId: null,
      fileKey: 'docs/contract.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 102_400,
      uploadedById: OWNER_ID,
      createdAt: new Date(Date.UTC(2026, 0, 5)),
    },
    {
      id: 'd-A',
      title: 'План этапа A',
      category: 'blueprint',
      stageId: STAGE_A,
      fileKey: 'docs/plan-A.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 51_200,
      uploadedById: FOREMAN_A_ID,
      createdAt: new Date(Date.UTC(2026, 0, 18)),
    },
  ];

  const payments = [
    {
      id: 'pay-1',
      stageId: STAGE_A,
      kind: 'advance',
      status: 'confirmed',
      amount: 300_000_00n,
      fromUserId: OWNER_ID,
      toUserId: FOREMAN_A_ID,
      photoKey: null,
      comment: 'Аванс бригадиру А',
      createdAt: new Date(Date.UTC(2026, 0, 22)),
    },
    {
      id: 'pay-2',
      stageId: STAGE_A,
      kind: 'distribution',
      status: 'confirmed',
      amount: 150_000_00n,
      fromUserId: FOREMAN_A_ID,
      toUserId: MASTER_A_ID,
      photoKey: null,
      comment: 'Распределение мастеру А',
      createdAt: new Date(Date.UTC(2026, 0, 25)),
    },
    {
      id: 'pay-3',
      stageId: STAGE_B,
      kind: 'advance',
      status: 'pending',
      amount: 500_000_00n,
      fromUserId: OWNER_ID,
      toUserId: FOREMAN_B_ID,
      photoKey: null,
      comment: 'Аванс бригадиру Б',
      createdAt: new Date(Date.UTC(2026, 1, 2)),
    },
  ];

  const materialRequests = [
    {
      id: 'mat-1',
      stageId: STAGE_A,
      title: 'Шпаклёвка и грунт',
      status: 'delivered',
      recipient: 'foreman',
      comment: 'Принято полностью',
      createdAt: new Date(Date.UTC(2026, 0, 24)),
      deliveredAt: new Date(Date.UTC(2026, 0, 26)),
      items: [
        {
          name: 'Шпаклёвка финишная',
          qty: '5',
          unit: 'мешок',
          pricePerUnit: 1500_00n,
          totalPrice: 7500_00n,
          isBought: true,
        },
        {
          name: 'Грунтовка',
          qty: '2',
          unit: 'канистра',
          pricePerUnit: null,
          totalPrice: null,
          isBought: false,
        },
      ],
    },
  ];

  const selfPurchases = [
    {
      id: 'sp-1',
      stageId: STAGE_A,
      byUserId: MASTER_A_ID,
      byRole: 'master',
      addresseeId: FOREMAN_A_ID,
      amount: 8_000_00n,
      status: 'approved',
      comment: 'Доехал в Леруа',
      photoKeys: ['receipts/sp1.jpg'],
      createdAt: new Date(Date.UTC(2026, 0, 26)),
    },
  ];

  const toolIssuances = [
    {
      id: 'ti-1',
      toolItemId: 'tool-1',
      stageId: STAGE_A,
      toUserId: MASTER_A_ID,
      issuedById: FOREMAN_A_ID,
      qty: 1,
      status: 'confirmed',
      issuedAt: new Date(Date.UTC(2026, 0, 21)),
      confirmedAt: new Date(Date.UTC(2026, 0, 22)),
      returnedAt: null,
    },
  ];

  const toolItems = [
    {
      id: 'tool-1',
      name: 'Перфоратор Bosch',
      serial: 'B-12345',
    },
  ];

  const feedEvents = [
    {
      kind: 'project_created',
      actorId: OWNER_ID,
      stageId: null,
      payload: {},
      createdAt: new Date(Date.UTC(2026, 0, 1)),
    },
    {
      kind: 'stage_started',
      actorId: FOREMAN_A_ID,
      stageId: STAGE_A,
      payload: {},
      createdAt: new Date(Date.UTC(2026, 0, 21)),
    },
    {
      kind: 'step_completed',
      actorId: MASTER_A_ID,
      stageId: STAGE_A,
      payload: { title: 'Снять обои' },
      createdAt: new Date(Date.UTC(2026, 0, 22)),
    },
    {
      kind: 'payment_created',
      actorId: OWNER_ID,
      stageId: STAGE_A,
      payload: { amount: 30000000 },
      createdAt: new Date(Date.UTC(2026, 0, 22)),
    },
  ];

  return {
    project: {
      findUnique: jest.fn(async ({ where }: any) => (where.id === PROJECT_ID ? project : null)),
    },
    membership: {
      findMany: jest.fn(async () => memberships),
    },
    stage: {
      findMany: jest.fn(async ({ where }: any) => {
        if (where.id?.in) {
          const set = new Set(where.id.in);
          return stages.filter((s) => set.has(s.id));
        }
        return stages;
      }),
    },
    document: {
      findMany: jest.fn(async ({ where }: any) => {
        if (where.OR) {
          const ids: string[] = where.OR[1]?.stageId?.in ?? [];
          const set = new Set<string>(ids);
          return documents.filter((d) => d.stageId === null || set.has(d.stageId));
        }
        return documents;
      }),
    },
    payment: {
      findMany: jest.fn(async ({ where }: any) => {
        if (!where.OR) return payments;
        const visibleStageIds: string[] | undefined = where.OR[0]?.stageId?.in;
        return payments.filter((p) => {
          if (visibleStageIds && p.stageId && visibleStageIds.includes(p.stageId)) return true;
          if (where.OR.some((cond: any) => cond.fromUserId === p.fromUserId)) return true;
          if (where.OR.some((cond: any) => cond.toUserId === p.toUserId)) return true;
          return false;
        });
      }),
    },
    materialRequest: {
      findMany: jest.fn(async () => materialRequests),
    },
    selfPurchase: {
      findMany: jest.fn(async ({ where }: any) => {
        if (!where.OR) return selfPurchases;
        return selfPurchases.filter((s) => {
          if (where.OR.some((c: any) => c.stageId?.in?.includes(s.stageId))) return true;
          if (where.OR.some((c: any) => c.byUserId === s.byUserId)) return true;
          if (where.OR.some((c: any) => c.addresseeId === s.addresseeId)) return true;
          return false;
        });
      }),
    },
    toolCustodyEvent: {
      findMany: jest.fn(async () =>
        toolIssuances.map((t) => ({
          id: t.id,
          toolItemId: t.toolItemId,
          holderId: t.toUserId,
          previousHolderId: t.issuedById,
          createdAt: t.issuedAt,
        })),
      ),
    },
    toolItem: {
      findMany: jest.fn(async ({ where }: any) =>
        toolItems.filter((t) => (where.id.in as string[]).includes(t.id)),
      ),
    },
    feedEvent: {
      findMany: jest.fn(async () => feedEvents),
    },
    user: {
      findMany: jest.fn(async ({ where }: any) => {
        const ids: string[] = where.id.in;
        return ids.map((id) => ({
          id,
          firstName: USERS[id as keyof typeof USERS]?.firstName ?? 'Unknown',
          lastName: USERS[id as keyof typeof USERS]?.lastName ?? id,
          phone: USERS[id as keyof typeof USERS]?.phone ?? null,
        }));
      }),
    },
  } as unknown as Prisma;
}

function makeFiles(opts?: { photoBuffer?: Buffer; fail?: boolean }): Files {
  const buf = opts?.photoBuffer ?? Buffer.from('fakejpeg');
  return {
    getObjectBuffer: jest.fn(async () => {
      if (opts?.fail) throw new Error('s3 unavailable');
      return buf;
    }),
    createPresignedDownload: jest.fn(async (key: string) => ({
      url: `https://signed.example/${key}?sig=xyz`,
      expiresAt: new Date(Date.now() + 60_000),
    })),
  } as unknown as Files;
}

const ownerViewer: ReportViewer = {
  userId: OWNER_ID,
  isOwner: true,
  membershipRole: 'customer',
  assignedStageIds: [],
  foremanStageIds: [],
  canSeeProjectBudget: true,
  canSeeStageBudget: true,
  canSeeAllPayments: true,
};

const foremanAViewer: ReportViewer = {
  userId: FOREMAN_A_ID,
  isOwner: false,
  membershipRole: 'foreman',
  assignedStageIds: [],
  foremanStageIds: [STAGE_A],
  canSeeProjectBudget: false,
  canSeeStageBudget: true,
  canSeeAllPayments: false,
};

const masterAViewer: ReportViewer = {
  userId: MASTER_A_ID,
  isOwner: false,
  membershipRole: 'master',
  assignedStageIds: [STAGE_A],
  foremanStageIds: [],
  canSeeProjectBudget: false,
  canSeeStageBudget: false,
  canSeeAllPayments: false,
};

describe('ProjectReportPdfService', () => {
  describe('collect() — данные отчёта', () => {
    it('owner: все этапы, бюджет, команда, движения средств, фид', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const data = await svc.collect(PROJECT_ID, ownerViewer);
      expect(data).not.toBeNull();
      const d = data!;
      expect(d.project.title).toBe('Ремонт квартиры');
      expect(d.stages).toHaveLength(2);
      expect(d.stages[0].steps).toHaveLength(1);
      expect(d.stages[0].steps[0].photos).toHaveLength(1);
      expect(d.stages[0].steps[0].photos[0].dataUrl).toMatch(/^data:image\//);
      // фото шага — base64-инлайн (юридическая фиксация без зависимости от сети)
      expect(d.payments).toHaveLength(3);
      expect(d.materials).toHaveLength(1);
      expect(d.tools).toHaveLength(1);
      expect(d.documents).toHaveLength(2);
      expect(d.documents[0].downloadUrl).toMatch(/^https:\/\/signed\.example/);
      expect(d.feed).toHaveLength(4);
      expect(d.budgetSummary.canSeeProjectBudget).toBe(true);
      expect(d.budgetSummary.byStage).toHaveLength(2);
    });

    it('foreman A: только свой этап, бюджет этапа, только свои платежи', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const d = (await svc.collect(PROJECT_ID, foremanAViewer))!;
      expect(d.stages.map((s) => s.title)).toEqual(['Демонтаж']);
      expect(d.budgetSummary.canSeeProjectBudget).toBe(false);
      expect(d.budgetSummary.canSeeStageBudget).toBe(true);
      // platежи: только этап A (виден stageId=STAGE_A) — оба платежа A
      const paymentStages = d.payments.map((p) => p.stageName);
      expect(paymentStages).toEqual(expect.arrayContaining(['Демонтаж']));
      expect(paymentStages).not.toContain('Электрика');
    });

    it('master A: видит только свой этап без бюджета и только свои выплаты', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const d = (await svc.collect(PROJECT_ID, masterAViewer))!;
      expect(d.stages.map((s) => s.title)).toEqual(['Демонтаж']);
      expect(d.budgetSummary.canSeeProjectBudget).toBe(false);
      expect(d.budgetSummary.canSeeStageBudget).toBe(false);
      // мастеру виден только distribution в его адрес
      expect(d.payments).toHaveLength(1);
      expect(d.payments[0].toName).toContain('Мастеров');
    });

    it('owner НЕ видит имена мастеров, нанятых бригадирами (§1.4)', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const d = (await svc.collect(PROJECT_ID, ownerViewer))!;
      const stageA = d.stages.find((s) => s.title === 'Демонтаж')!;
      expect(stageA.masterName).toContain('Субподрядчик бригадира (скрыт)');
      const stageB = d.stages.find((s) => s.title === 'Электрика')!;
      expect(stageB.masterName).toContain('Субподрядчик бригадира (скрыт)');
      // mastersовый платёж — имя получателя тоже скрыто
      const distribution = d.payments.find((p) => p.fromName.includes('Бригадиров-А'));
      expect(distribution?.toName).toContain('скрыт');
    });

    it('возвращает null для несуществующего проекта', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      expect(await svc.collect('missing', ownerViewer)).toBeNull();
    });

    it('фото не доступно в S3 → dataUrl=null, отчёт всё равно собирается', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles({ fail: true }));
      const d = (await svc.collect(PROJECT_ID, ownerViewer))!;
      expect(d.stages[0].steps[0].photos[0].dataUrl).toBeNull();
    });
  });

  describe('buildHtml() — HTML-вывод', () => {
    let data: Awaited<ReturnType<ProjectReportPdfService['collect']>>;
    let svc: ProjectReportPdfService;
    beforeAll(async () => {
      svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      data = await svc.collect(PROJECT_ID, ownerViewer);
    });

    it('содержит брендинг Repair Control и шапку проекта', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('Repair Control');
      expect(html).toContain('Создано в Repair Control');
      expect(html).toContain('Ремонт квартиры');
      expect(html).toContain('СПб, Невский 1');
    });

    it('форматирует даты ДД.ММ.ГГГГ и деньги без копеек', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('15.01.2026'); // plannedStart
      expect(html).toContain('2 000 000 ₽'); // workBudget
      expect(html).toContain('4 000 000 ₽'); // materialsBudget
      expect(html).toContain('6 000 000 ₽'); // total
      expect(html).not.toMatch(/\d{4}-\d{2}-\d{2}/); // ISO дат нет
    });

    it('содержит секции: бюджет, движения средств, команда, этапы, материалы, инструменты, документы, лента', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('<h2>Бюджет</h2>');
      expect(html).toContain('Движение средств');
      expect(html).toContain('Команда');
      expect(html).toContain('Этапы');
      expect(html).toContain('Материалы');
      expect(html).toContain('Инструменты');
      expect(html).toContain('Документы');
      expect(html).toContain('Лента событий');
    });

    it('встраивает фото шага через data:image base64', () => {
      const html = svc.buildHtml(data!);
      expect(html).toMatch(/<img src="data:image\/jpeg;base64,[A-Za-z0-9+/=]+"/);
    });

    it('документы — presigned URL как кликабельная ссылка + s3 fallback', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('https://signed.example/docs/contract.pdf');
      expect(html).toContain('s3://docs/contract.pdf');
    });

    it('секция платежей содержит описание и сумму', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('Аванс бригадиру А');
      expect(html).toContain('300 000 ₽');
    });

    it('материалы — позиции с количеством и ценами', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('Шпаклёвка финишная');
      expect(html).toContain('7 500 ₽');
    });

    it('инструменты — серийный номер и статус', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('Перфоратор Bosch');
      expect(html).toContain('B-12345');
    });

    it('лента событий — переведённые описания', () => {
      const html = svc.buildHtml(data!);
      expect(html).toContain('Проект создан');
      expect(html).toContain('Этап запущен');
      expect(html).toContain('Шаг закрыт');
    });

    it('бригадир видит «Общий бюджет проекта скрыт» вместо итоговой таблицы', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const d = (await svc.collect(PROJECT_ID, foremanAViewer))!;
      const html = svc.buildHtml(d);
      expect(html).toContain('Общий бюджет проекта скрыт');
      expect(html).not.toMatch(/<tr class="total">[^<]*<th>Итого<\/th><td>6 000 000 ₽/);
    });

    it('мастер видит «Бюджет скрыт — нет права»', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const d = (await svc.collect(PROJECT_ID, masterAViewer))!;
      const html = svc.buildHtml(d);
      expect(html).toContain('Бюджет скрыт');
    });

    it('escapes HTML в пользовательских строках (защита от XSS-в-PDF)', async () => {
      const prisma = makePrisma();
      const project = await (prisma.project.findUnique as jest.Mock)({ where: { id: PROJECT_ID } });
      project.title = '<script>alert(1)</script>';
      const svc = new ProjectReportPdfService(prisma, makeFiles());
      const d = (await svc.collect(PROJECT_ID, ownerViewer))!;
      const html = svc.buildHtml(d);
      expect(html).not.toContain('<script>alert(1)</script>');
      expect(html).toContain('&lt;script&gt;alert(1)&lt;/script&gt;');
    });
  });

  describe('renderPdf() — fallback', () => {
    it('если puppeteer недоступен — возвращает HTML как UTF-8 буфер', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const buf = await svc.renderPdf('<html><body>Hi</body></html>');
      expect(Buffer.isBuffer(buf)).toBe(true);
      // На CI/локально puppeteer-core+chromium обычно недоступен — fallback возвращает HTML.
      const text = buf.toString('utf-8');
      expect(text.length).toBeGreaterThan(0);
    });
  });

  describe('build() — интеграция', () => {
    it('собирает данные и формирует Buffer без ошибок', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const buf = await svc.build(PROJECT_ID, ownerViewer);
      expect(Buffer.isBuffer(buf)).toBe(true);
      expect(buf.length).toBeGreaterThan(0);
    });

    it('для отсутствующего проекта — fallback с текстом ошибки', async () => {
      const svc = new ProjectReportPdfService(makePrisma(), makeFiles());
      const buf = await svc.build('missing', ownerViewer);
      expect(buf.toString('utf-8')).toContain('не найден');
    });
  });
});
