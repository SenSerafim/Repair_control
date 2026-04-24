import { PrismaClient, StageStatus, SystemRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

/**
 * Staging-сид для демо-окружения.
 * Создаёт:
 *  - 5 тестовых пользователей (customer + rep + foreman + master + admin)
 *  - 2 демо-проекта (активный и архивный)
 *  - FAQ-секцию с 3 вопросами
 *  - AppSettings (support_telegram_url)
 *
 * ВАЖНО: запускать только на staging БД, не на prod.
 * Все пароли одинаковые: `staging-demo-12345` (только для демо).
 *
 * Usage: npm run prisma:seed:staging
 */
const DEMO_PASSWORD = 'staging-demo-12345';
const prisma = new PrismaClient();

async function hashPassword(pw: string): Promise<string> {
  const cost = Number(process.env.BCRYPT_COST ?? 10);
  return bcrypt.hash(pw, cost);
}

async function upsertUser(data: {
  phone: string;
  firstName: string;
  lastName: string;
  role: SystemRole;
  admin?: boolean;
}): Promise<string> {
  const passwordHash = await hashPassword(DEMO_PASSWORD);
  const u = await prisma.user.upsert({
    where: { phone: data.phone },
    create: {
      phone: data.phone,
      passwordHash,
      firstName: data.firstName,
      lastName: data.lastName,
      activeRole: data.admin ? 'admin' : data.role,
      language: 'ru',
    },
    update: {
      firstName: data.firstName,
      lastName: data.lastName,
      activeRole: data.admin ? 'admin' : data.role,
    },
  });

  // Роль (customer/representative/contractor/master/admin)
  await prisma.userRole.upsert({
    where: { userId_role: { userId: u.id, role: data.role } },
    create: { userId: u.id, role: data.role },
    update: {},
  });
  if (data.admin) {
    await prisma.userRole.upsert({
      where: { userId_role: { userId: u.id, role: 'admin' } },
      create: { userId: u.id, role: 'admin' },
      update: {},
    });
  }
  return u.id;
}

async function main(): Promise<void> {
  // --- Users ---
  const customerId = await upsertUser({
    phone: '+79990000001',
    firstName: 'Анна',
    lastName: 'Заказчик',
    role: 'customer',
  });
  const repId = await upsertUser({
    phone: '+79990000002',
    firstName: 'Ирина',
    lastName: 'Представитель',
    role: 'representative',
  });
  const foremanId = await upsertUser({
    phone: '+79990000003',
    firstName: 'Сергей',
    lastName: 'Бригадир',
    role: 'contractor',
  });
  const masterId = await upsertUser({
    phone: '+79990000004',
    firstName: 'Игорь',
    lastName: 'Мастер',
    role: 'master',
  });
  const adminId = await upsertUser({
    phone: '+79990000000',
    firstName: 'Admin',
    lastName: 'Root',
    role: 'customer', // user's membership role — но systemRole admin
    admin: true,
  });

  console.log('Seeded users:', { customerId, repId, foremanId, masterId, adminId });

  // --- Demo project 1 (активный) ---
  const activeProject = await prisma.project.upsert({
    where: { id: 'demo-project-active' },
    create: {
      id: 'demo-project-active',
      ownerId: customerId,
      title: 'Квартира на Тверской',
      address: 'г. Москва, ул. Тверская 10, кв. 42',
      plannedStart: new Date('2026-05-01T00:00:00Z'),
      plannedEnd: new Date('2026-09-30T00:00:00Z'),
      workBudget: BigInt(500_000_00),
      materialsBudget: BigInt(300_000_00),
      requiresPlanApproval: true,
      memberships: {
        create: [
          { userId: customerId, role: 'customer', permissions: {} },
          {
            userId: repId,
            role: 'representative',
            permissions: {
              canEditStages: true,
              canApprove: true,
              canSeeBudget: true,
              canCreatePayments: true,
              canManageMaterials: true,
            },
          },
          { userId: foremanId, role: 'foreman', permissions: {} },
          {
            userId: masterId,
            role: 'master',
            permissions: {},
            stageIds: [],
          },
        ],
      },
    },
    update: {},
  });

  // Stages
  const stage1 = await prisma.stage.upsert({
    where: { id: 'demo-stage-demolition' },
    create: {
      id: 'demo-stage-demolition',
      projectId: activeProject.id,
      title: 'Демонтаж',
      orderIndex: 0,
      status: StageStatus.done,
      plannedStart: new Date('2026-05-01T00:00:00Z'),
      plannedEnd: new Date('2026-05-15T00:00:00Z'),
      foremanIds: [foremanId],
      progressCache: 100,
      planApproved: true,
    },
    update: {},
  });
  const stage2 = await prisma.stage.upsert({
    where: { id: 'demo-stage-electrics' },
    create: {
      id: 'demo-stage-electrics',
      projectId: activeProject.id,
      title: 'Электрика',
      orderIndex: 1,
      status: StageStatus.active,
      plannedStart: new Date('2026-05-16T00:00:00Z'),
      plannedEnd: new Date('2026-06-30T00:00:00Z'),
      foremanIds: [foremanId],
      progressCache: 35,
      planApproved: true,
      startedAt: new Date('2026-05-16T10:00:00Z'),
    },
    update: {},
  });
  console.log('Seeded stages:', [stage1.id, stage2.id]);

  // --- Demo project 2 (архив) ---
  await prisma.project.upsert({
    where: { id: 'demo-project-archived' },
    create: {
      id: 'demo-project-archived',
      ownerId: customerId,
      title: 'Офис на Мясницкой (завершён)',
      address: 'г. Москва, ул. Мясницкая 5',
      status: 'archived',
      plannedStart: new Date('2025-01-10T00:00:00Z'),
      plannedEnd: new Date('2025-04-30T00:00:00Z'),
      archivedAt: new Date('2025-05-10T00:00:00Z'),
      workBudget: BigInt(800_000_00),
      materialsBudget: BigInt(600_000_00),
      memberships: {
        create: [{ userId: customerId, role: 'customer', permissions: {} }],
      },
    },
    update: {},
  });

  // --- FAQ section ---
  const faqSection = await prisma.faqSection.upsert({
    where: { id: 'faq-general' },
    create: { id: 'faq-general', title: 'Общие вопросы', orderIndex: 0 },
    update: {},
  });
  const faqItems = [
    {
      id: 'faq-start',
      question: 'Как начать работу с приложением?',
      answer:
        'Зарегистрируйтесь по телефону, выберите роль (заказчик / бригадир / мастер), создайте или присоединитесь к проекту.',
      orderIndex: 0,
    },
    {
      id: 'faq-plan-approval',
      question: 'Зачем согласование плана работ?',
      answer:
        'Бригадир составляет план этапов с датами и бюджетом. До согласования заказчиком бригадир не может нажать Старт.',
      orderIndex: 1,
    },
    {
      id: 'faq-tools',
      question: 'Как бригадир учитывает инструмент?',
      answer:
        'Инструмент привязан к профилю бригадира и переносится между проектами. Выдачу подтверждает мастер, возврат — бригадир.',
      orderIndex: 2,
    },
  ];
  for (const item of faqItems) {
    await prisma.faqItem.upsert({
      where: { id: item.id },
      create: { ...item, sectionId: faqSection.id },
      update: { question: item.question, answer: item.answer, orderIndex: item.orderIndex },
    });
  }

  // --- AppSettings ---
  await prisma.appSetting.upsert({
    where: { key: 'support_telegram_url' },
    create: {
      key: 'support_telegram_url',
      value: process.env.SUPPORT_TELEGRAM_URL ?? 'https://t.me/repaircontrol_support',
    },
    update: {},
  });
  await prisma.appSetting.upsert({
    where: { key: 'policy_version' },
    create: { key: 'policy_version', value: '1.0' },
    update: {},
  });
  await prisma.appSetting.upsert({
    where: { key: 'tos_version' },
    create: { key: 'tos_version', value: '1.0' },
    update: {},
  });

  console.log('Staging seed complete.');
  console.log('Demo credentials:');
  console.log('  admin:     +79990000000 / ' + DEMO_PASSWORD);
  console.log('  customer:  +79990000001 / ' + DEMO_PASSWORD);
  console.log('  rep:       +79990000002 / ' + DEMO_PASSWORD);
  console.log('  foreman:   +79990000003 / ' + DEMO_PASSWORD);
  console.log('  master:    +79990000004 / ' + DEMO_PASSWORD);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error('staging seed failed:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
