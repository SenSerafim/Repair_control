import { bootTestApp, closeTestApp, E2EContext, truncateAll } from './setup-e2e';

/**
 * Smoke-тест схемы S3/D5: проверяет, что Prisma умеет создать валидные записи
 * новых моделей (Step/Substep/StepPhoto/Note/Question), соблюдает FK-cascade
 * при удалении Stage и отвергает невалидные enum-значения.
 *
 * Не покрывает бизнес-инварианты (scope, права §6.4) — это тесты сервисов в 5.2–5.8.
 */
describe('S3/D5 Schema — Step/Substep/StepPhoto/Note/Question', () => {
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

  async function seedProjectStage() {
    const owner = await ctx.prisma.user.create({
      data: {
        phone: '+79990000001',
        passwordHash: 'hash',
        firstName: 'O',
        lastName: 'W',
        roles: { create: { role: 'customer' } },
      },
    });
    const project = await ctx.prisma.project.create({
      data: { ownerId: owner.id, title: 'Тестовый' },
    });
    const stage = await ctx.prisma.stage.create({
      data: { projectId: project.id, title: 'Демонтаж', orderIndex: 0 },
    });
    return { owner, project, stage };
  }

  it('создаёт regular Step + Substep + StepPhoto и cascade-удаляет их при удалении Stage', async () => {
    const { owner, stage } = await seedProjectStage();

    const step = await ctx.prisma.step.create({
      data: {
        stageId: stage.id,
        title: 'Штробление стен',
        orderIndex: 0,
        type: 'regular',
        createdBy: owner.id,
      },
    });
    expect(step.type).toBe('regular');
    expect(step.doneAt).toBeNull();
    expect(step.extraApprovalStatus).toBeNull();

    const substep = await ctx.prisma.substep.create({
      data: { stepId: step.id, text: 'Проверить уровень', authorId: owner.id },
    });
    expect(substep.isDone).toBe(false);

    const photo = await ctx.prisma.stepPhoto.create({
      data: {
        stepId: step.id,
        fileKey: 'projects/x/steps/y/photo.jpg',
        mimeType: 'image/jpeg',
        size: BigInt(102_400),
        uploadedBy: owner.id,
      },
    });
    expect(photo.id).toBeTruthy();

    await ctx.prisma.stage.delete({ where: { id: stage.id } });
    expect(await ctx.prisma.step.count()).toBe(0);
    expect(await ctx.prisma.substep.count()).toBe(0);
    expect(await ctx.prisma.stepPhoto.count()).toBe(0);
  });

  it('создаёт extra-work Step c pending approval и хранит qty/unitPrice', async () => {
    const { owner, stage } = await seedProjectStage();

    const extra = await ctx.prisma.step.create({
      data: {
        stageId: stage.id,
        title: 'Розетки +10 шт.',
        orderIndex: 1,
        type: 'extra',
        extraQty: 10,
        extraUnitPrice: BigInt(120_000),
        extraApprovalStatus: 'pending',
        createdBy: owner.id,
      },
    });
    expect(extra.type).toBe('extra');
    expect(extra.extraApprovalStatus).toBe('pending');
    expect(extra.extraQty).toBe(10);
    expect(extra.extraUnitPrice).toBe(BigInt(120_000));
  });

  it('создаёт Note каждого scope (personal / forMe / stage)', async () => {
    const { owner, project, stage } = await seedProjectStage();
    const other = await ctx.prisma.user.create({
      data: {
        phone: '+79990000002',
        passwordHash: 'hash',
        firstName: 'M',
        lastName: 'M',
        roles: { create: { role: 'master' } },
      },
    });

    const personal = await ctx.prisma.note.create({
      data: { scope: 'personal', authorId: owner.id, text: 'Моя заметка' },
    });
    const forMe = await ctx.prisma.note.create({
      data: {
        scope: 'forMe',
        authorId: owner.id,
        addresseeId: other.id,
        projectId: project.id,
        text: 'Мастеру: проверь проводку',
      },
    });
    const stageNote = await ctx.prisma.note.create({
      data: {
        scope: 'stage',
        authorId: owner.id,
        stageId: stage.id,
        text: 'Общая заметка этапа',
      },
    });
    expect(personal.scope).toBe('personal');
    expect(forMe.addresseeId).toBe(other.id);
    expect(stageNote.stageId).toBe(stage.id);

    await ctx.prisma.stage.delete({ where: { id: stage.id } });
    const remaining = await ctx.prisma.note.findMany();
    expect(remaining.map((n) => n.scope).sort()).toEqual(['forMe', 'personal']);
  });

  it('создаёт Question в статусе open и поднимает answered при заполнении answerText', async () => {
    const { owner, stage } = await seedProjectStage();
    const master = await ctx.prisma.user.create({
      data: {
        phone: '+79990000003',
        passwordHash: 'hash',
        firstName: 'M',
        lastName: 'A',
        roles: { create: { role: 'master' } },
      },
    });
    const step = await ctx.prisma.step.create({
      data: {
        stageId: stage.id,
        title: 'Клей для плитки',
        orderIndex: 0,
        type: 'regular',
        createdBy: owner.id,
      },
    });

    const q = await ctx.prisma.question.create({
      data: {
        stepId: step.id,
        authorId: owner.id,
        addresseeId: master.id,
        text: 'Какой бренд клея?',
      },
    });
    expect(q.status).toBe('open');
    expect(q.answerText).toBeNull();

    const answered = await ctx.prisma.question.update({
      where: { id: q.id },
      data: {
        status: 'answered',
        answerText: 'Ceresit CM-11',
        answeredBy: master.id,
        answeredAt: new Date(),
      },
    });
    expect(answered.status).toBe('answered');
    expect(answered.answerText).toBe('Ceresit CM-11');
  });

  it('отклоняет невалидное значение enum (extraApprovalStatus)', async () => {
    const { owner, stage } = await seedProjectStage();
    await expect(
      ctx.prisma.step.create({
        data: {
          stageId: stage.id,
          title: 'bad',
          orderIndex: 0,
          type: 'extra',
          extraApprovalStatus: 'bogus' as any,
          createdBy: owner.id,
        },
      }),
    ).rejects.toThrow();
  });
});
