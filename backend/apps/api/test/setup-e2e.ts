import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModuleBuilder } from '@nestjs/testing';
import '../src/bootstrap/bigint-serializer';
import { AppModule } from '../src/app.module';
import { Clock, FixedClock, PrismaService } from '@app/common';

export interface E2EContext {
  app: INestApplication;
  prisma: PrismaService;
  clock: FixedClock;
}

/**
 * Boot Nest-приложения для e2e со свободным временем (FixedClock).
 */
export async function bootTestApp(
  initialDate = new Date('2026-06-01T10:00:00Z'),
): Promise<E2EContext> {
  const clock = new FixedClock(initialDate);

  const builder: TestingModuleBuilder = Test.createTestingModule({ imports: [AppModule] });
  builder.overrideProvider(Clock).useValue(clock);

  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication({
    logger: process.env.E2E_SILENT ? false : ['error', 'warn'],
  });
  app.setGlobalPrefix('api', { exclude: ['healthz'] });
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
  );
  await app.init();

  const prisma = app.get(PrismaService);
  return { app, prisma, clock };
}

/**
 * Очистка всех таблиц между тестами в правильном порядке (учитывая FK).
 */
export async function truncateAll(prisma: PrismaService): Promise<void> {
  // Шаблоны не трогаем — их seed'ит globalSetup, переиспользуем.
  const tables = [
    'FeedEvent',
    'Pause',
    'Stage',
    'ProjectInvitation',
    'Membership',
    'Project',
    'DeviceToken',
    'Session',
    'RecoveryAttempt',
    'LoginAttempt',
    'UserRole',
    'User',
  ];
  const quoted = tables.map((t) => `"${t}"`).join(', ');
  await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${quoted} RESTART IDENTITY CASCADE`);
}

export async function closeTestApp(ctx: E2EContext): Promise<void> {
  await ctx.app.close();
}
