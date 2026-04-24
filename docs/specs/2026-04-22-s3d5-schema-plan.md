# S3/D5 Task 5.1 — Step Catalog Schema Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить Prisma-схему и миграцию для `Step`, `Substep`, `StepPhoto`, `Note`, `Question` с новыми enum'ами и расширением `FeedEventKind`. Никакой бизнес-логики — только слой данных.

**Architecture:** Одна атомарная миграция `s3_d5_step_catalog`. Пять новых моделей, четыре новых enum'а, расширение `FeedEventKind` (18 значений), обратные связи на `Stage` и `Project`. TDD-цикл: сначала smoke-тест через Prisma Client (упадёт на компиляции, т.к. типов нет), потом правим `schema.prisma`, генерим клиент — тест становится зелёным.

**Tech Stack:** Prisma 5.20, PostgreSQL 16, NestJS 10, Jest + supertest, ts-jest.

**Spec:** `docs/specs/2026-04-22-s3d5-schema-design.md` (коммит `6b22fb2`).

**Issue:** [#5 `[S3/D5]`](https://github.com/SenSerafim/Repair_control/issues/5) → sub-task 5.1.

**Branch:** `feat/s3-step-schema`.

---

## File Structure

- **Modify:** `backend/prisma/schema.prisma` — добавить 4 enum'а, расширить `FeedEventKind`, добавить 5 моделей, добавить обратные связи в `Stage` и `Project`.
- **Create:** `backend/prisma/migrations/<timestamp>_s3_d5_step_catalog/migration.sql` — автогенерируется `prisma migrate dev`.
- **Create:** `backend/apps/api/test/step-schema.e2e-spec.ts` — smoke-тест валидности схемы (create of each, cascade delete, enum rejection).
- **Modify:** `backend/apps/api/test/setup-e2e.ts` — добавить новые таблицы в `truncateAll` в правильном FK-порядке.

---

## Prerequisites (one-time, разовая настройка)

- [ ] **Step A: Убедиться, что Docker Compose поднят**

```bash
cd ~/projects/web/Repair_control
docker compose -f backend/docker-compose.yml up -d postgres
docker compose -f backend/docker-compose.yml ps
```

Ожидание: `postgres` имеет статус `running (healthy)`. Если контейнер ещё не стартовал — подождать 10 секунд и проверить снова.

- [ ] **Step B: Проверить `.env.test` (нужен для e2e global-setup)**

```bash
test -f backend/.env.test && echo "OK: .env.test exists" || echo "MISSING"
```

Если `MISSING` — создать файл (он игнорируется git'ом):

```bash
cp .env.dev backend/.env.test
# заменить имя БД на тестовую
sed -i 's|/repair_control?|/repair_control_test?|' backend/.env.test
grep DATABASE_URL backend/.env.test
```

Ожидание: `DATABASE_URL=postgresql://postgres:postgres@localhost:5432/repair_control_test?schema=public`.

- [ ] **Step C: Убедиться, что существующие тесты зелёные (baseline)**

```bash
cd backend && npm run test:e2e 2>&1 | tail -20
```

Ожидание: `Test Suites: 2 passed, 2 total` (auth + projects-stages). Если красные — не продолжать, разбираться отдельно.

---

## Task 1: Создать ветку и зафиксировать начальное состояние

**Files:**
- N/A (git ops)

- [ ] **Step 1: Убедиться, что мы на dev_v1 и дерево чистое**

```bash
cd ~/projects/web/Repair_control
git status
git branch --show-current
```

Ожидание: `On branch dev_v1`, `nothing to commit, working tree clean`. Если нет — остановиться, разобраться.

- [ ] **Step 2: Создать feature-ветку от `dev_v1`**

```bash
git checkout -b feat/s3-step-schema
git branch --show-current
```

Ожидание: `feat/s3-step-schema`.

---

## Task 2: Написать падающий smoke-тест (TDD-красный)

**Files:**
- Create: `backend/apps/api/test/step-schema.e2e-spec.ts`

- [ ] **Step 1: Создать файл с smoke-тестом, покрывающим create/cascade/enum-invariant**

```typescript
// backend/apps/api/test/step-schema.e2e-spec.ts
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

    // cascade: удаление Stage уносит Step → Substep → StepPhoto
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
        extraUnitPrice: BigInt(120_000), // 1200 ₽ за розетку
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

    // cascade: удаление Stage уносит только stage-note, не personal/forMe
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
```

- [ ] **Step 2: Убедиться, что тест не компилируется (красный этап TDD)**

```bash
cd backend && npx tsc --noEmit -p tsconfig.json 2>&1 | grep -E "step-schema|Property 'step'|Property 'substep'|Property 'stepPhoto'|Property 'note'|Property 'question'" | head -10
```

Ожидание: TypeScript ругается на отсутствующие `prisma.step`, `prisma.substep`, `prisma.stepPhoto`, `prisma.note`, `prisma.question` — это и есть «красный» TDD.

---

## Task 3: Добавить новые enum'ы в `schema.prisma`

**Files:**
- Modify: `backend/prisma/schema.prisma:78` (после `FeedEventKind`)

- [ ] **Step 1: Добавить `StepType`, `ExtraApprovalStatus`, `NoteScope`, `QuestionStatus` после существующих enum'ов**

Открыть `backend/prisma/schema.prisma`, найти блок `enum FeedEventKind { ... }` (около строки 63). Сразу **после** его закрывающей скобки (до комментария `// ---------- Users / Auth ----------`) вставить:

```prisma
enum StepType {
  regular
  extra
}

enum ExtraApprovalStatus {
  pending
  approved
  rejected
}

enum NoteScope {
  personal
  forMe
  stage
}

enum QuestionStatus {
  open
  answered
  closed
}
```

- [ ] **Step 2: Расширить `FeedEventKind` новыми значениями**

В enum'е `FeedEventKind` **после** последней строки `stages_reordered` и **до** закрывающей `}` добавить:

```prisma
  // S3/D5 — steps, substeps, photos, extras, notes, questions
  step_created
  step_reordered
  step_done
  step_reopened
  step_deleted
  substep_created
  substep_updated
  substep_deleted
  substep_done
  substep_reopened
  step_photo_added
  step_photo_deleted
  extra_work_requested
  extra_work_approved
  extra_work_rejected
  note_created
  note_updated
  note_deleted
  question_created
  question_answered
  question_closed
  stage_progress_recalculated
```

- [ ] **Step 3: Запустить `prisma format` для нормализации**

```bash
cd backend && npx prisma format
```

Ожидание: `Formatted ./prisma/schema.prisma in Xms`. Файл нормализован, diff может быть минимальный (выравнивание).

---

## Task 4: Добавить модели `Step`, `Substep`, `StepPhoto`

**Files:**
- Modify: `backend/prisma/schema.prisma` (в конце файла, после `FeedEvent`)

- [ ] **Step 1: Добавить раздел `// ---------- Steps ----------` в конец файла**

После модели `FeedEvent` (последней в файле) добавить:

```prisma
// ---------- Steps ----------

model Step {
  id                    String    @id @default(cuid())
  stageId               String
  title                 String
  orderIndex            Int
  type                  StepType  @default(regular)

  // Справочная цена шага. Для type=regular — оценка из шаблона или вручную;
  // не используется в MVP для расчёта бюджета (он на уровне Stage в S4).
  // Для type=extra — игнорируется, факт. стоимость = extraQty * extraUnitPrice.
  price                 BigInt?

  doneAt                DateTime?
  doneBy                String?

  // Поля для type=extra (иначе NULL)
  extraQty              Int?
  extraUnitPrice        BigInt?
  extraApprovalStatus   ExtraApprovalStatus?
  extraApprovedBy       String?
  extraApprovedAt       DateTime?
  extraRejectionReason  String?

  createdBy             String
  createdAt             DateTime  @default(now())
  updatedAt             DateTime  @updatedAt

  stage                 Stage       @relation(fields: [stageId], references: [id], onDelete: Cascade)
  substeps              Substep[]
  photos                StepPhoto[]
  questions             Question[]

  @@index([stageId, orderIndex])
  @@index([type, extraApprovalStatus])
  @@index([doneAt])
}

model Substep {
  id         String    @id @default(cuid())
  stepId     String
  text       String
  authorId   String
  isDone     Boolean   @default(false)
  doneAt     DateTime?
  doneBy     String?
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt

  step       Step      @relation(fields: [stepId], references: [id], onDelete: Cascade)

  @@index([stepId, createdAt])
  @@index([authorId])
}

model StepPhoto {
  id          String   @id @default(cuid())
  stepId      String
  fileKey     String
  thumbKey    String?
  mimeType    String
  size        BigInt
  width       Int?
  height      Int?
  uploadedBy  String
  createdAt   DateTime @default(now())

  step        Step     @relation(fields: [stepId], references: [id], onDelete: Cascade)

  @@index([stepId, createdAt])
}
```

- [ ] **Step 2: Запустить `prisma format` и убедиться, что файл валидный**

```bash
cd backend && npx prisma format && npx prisma validate
```

Ожидание: `The schema at ./prisma/schema.prisma is valid 🚀`. Если ошибка — читать сообщение, проверять типы/связи.

---

## Task 5: Добавить модели `Note`, `Question`

**Files:**
- Modify: `backend/prisma/schema.prisma` (в конце файла, после `StepPhoto`)

- [ ] **Step 1: Добавить `Note` и `Question` в конец файла**

После `StepPhoto`:

```prisma
// ---------- Notes & Questions ----------

model Note {
  id           String    @id @default(cuid())
  scope        NoteScope
  authorId     String
  addresseeId  String?
  projectId    String?
  stageId      String?
  text         String
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt

  project      Project?  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  stage        Stage?    @relation(fields: [stageId], references: [id], onDelete: Cascade)

  @@index([authorId, createdAt])
  @@index([addresseeId, createdAt])
  @@index([stageId, createdAt])
  @@index([projectId, createdAt])
}

model Question {
  id            String         @id @default(cuid())
  stepId        String
  authorId      String
  addresseeId   String
  text          String
  status        QuestionStatus @default(open)
  answerText    String?
  answeredBy    String?
  answeredAt    DateTime?
  closedAt      DateTime?
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt

  step          Step           @relation(fields: [stepId], references: [id], onDelete: Cascade)

  @@index([stepId, createdAt])
  @@index([addresseeId, status])
  @@index([authorId, status])
}
```

- [ ] **Step 2: Валидировать**

```bash
cd backend && npx prisma format && npx prisma validate
```

Ожидание: `valid 🚀`.

---

## Task 6: Добавить обратные связи в `Stage` и `Project`

**Files:**
- Modify: `backend/prisma/schema.prisma:244-283` (`Stage`), `backend/prisma/schema.prisma:179-203` (`Project`)

- [ ] **Step 1: В `Stage` добавить обратные связи на `Step` и `Note`**

Найти `model Stage { ... }`. Внутри блока, после строки `pauses Pause[]`, добавить:

```prisma
  steps           Step[]
  notes           Note[]
```

- [ ] **Step 2: В `Project` добавить обратную связь на `Note`**

Найти `model Project { ... }`. Внутри блока, после строки `feedEvents FeedEvent[]`, добавить:

```prisma
  notes           Note[]
```

- [ ] **Step 3: Валидировать схему**

```bash
cd backend && npx prisma format && npx prisma validate
```

Ожидание: `valid 🚀`. Если Prisma жалуется на «ambiguous relation» — именовать связи явно через `@relation("Name")`.

---

## Task 7: Обновить `truncateAll` в setup-e2e

**Files:**
- Modify: `backend/apps/api/test/setup-e2e.ts` — добавить новые таблицы в TRUNCATE-список в правильном FK-порядке (child → parent).

- [ ] **Step 1: Найти массив `tables` в `truncateAll` и добавить новые таблицы в начало**

Функция `truncateAll` в файле `backend/apps/api/test/setup-e2e.ts`. Массив `tables` сейчас начинается с `'FeedEvent'`. Добавить **в начало** массива (child-таблицы уходят первыми):

```typescript
  const tables = [
    'Question',
    'Note',
    'StepPhoto',
    'Substep',
    'Step',
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
```

Порядок важен — `CASCADE` в TRUNCATE и так почистит зависимые, но явный порядок делает план транзакции детерминированным и ускоряет тесты.

---

## Task 8: Сгенерировать миграцию (create-only) и посмотреть SQL

**Files:**
- Create: `backend/prisma/migrations/<timestamp>_s3_d5_step_catalog/migration.sql`

- [ ] **Step 1: Сгенерировать миграцию без применения**

```bash
cd backend && npx prisma migrate dev --create-only --name s3_d5_step_catalog
```

Ожидание: создан каталог `prisma/migrations/<timestamp>_s3_d5_step_catalog/` с файлом `migration.sql`. Применение **не** произошло.

- [ ] **Step 2: Убедиться, что SQL содержит ожидаемые объекты**

```bash
ls backend/prisma/migrations/ | grep s3_d5_step_catalog
MIG_DIR=$(ls -d backend/prisma/migrations/*s3_d5_step_catalog)
grep -E "^CREATE TYPE|^CREATE TABLE|^ALTER TABLE.*ADD COLUMN|^ALTER TYPE" "$MIG_DIR/migration.sql" | head -40
```

Ожидание видеть:
- `CREATE TYPE "StepType"`, `CREATE TYPE "ExtraApprovalStatus"`, `CREATE TYPE "NoteScope"`, `CREATE TYPE "QuestionStatus"`
- 22 строк `ALTER TYPE "FeedEventKind" ADD VALUE` (по одному на каждое новое значение)
- `CREATE TABLE "Step"`, `CREATE TABLE "Substep"`, `CREATE TABLE "StepPhoto"`, `CREATE TABLE "Note"`, `CREATE TABLE "Question"`
- FK с `ON DELETE CASCADE`

Если SQL выглядит странно — открыть файл целиком, пересчитать, при сомнениях переделать: `rm -rf $MIG_DIR` и переписать схему → снова `migrate dev --create-only`.

---

## Task 9: Применить миграцию и перегенерировать Prisma Client

**Files:**
- N/A (operational)

- [ ] **Step 1: Применить миграцию**

```bash
cd backend && npx prisma migrate dev
```

Ожидание: `Database is now in sync with your schema`, миграция помечена как applied. Если ошибка — читать, разбираться. Обычная ошибка — SQL некорректен → откатиться, править схему, `rm -rf` каталог миграции и пересобрать.

- [ ] **Step 2: Перегенерировать Prisma Client**

```bash
cd backend && npx prisma generate
```

Ожидание: `Generated Prisma Client (vX.Y.Z) ... in Xms`.

- [ ] **Step 3: Убедиться, что TS теперь компилируется**

```bash
cd backend && npx tsc --noEmit -p tsconfig.json 2>&1 | head -20
```

Ожидание: пусто (0 ошибок) либо только не связанные с нашим изменением ошибки. Если всплывают ошибки в `step-schema.e2e-spec.ts` — значит сгенерированные типы не совпадают с нашими допущениями, править тест или схему.

---

## Task 10: Запустить smoke-тест (TDD-зелёный)

**Files:**
- N/A

- [ ] **Step 1: Запустить только новый smoke-тест**

```bash
cd backend && npx jest --runInBand --config apps/api/test/jest-e2e.json --testPathPattern=step-schema 2>&1 | tail -30
```

Ожидание:
```
PASS  apps/api/test/step-schema.e2e-spec.ts
  S3/D5 Schema — Step/Substep/StepPhoto/Note/Question
    ✓ создаёт regular Step + Substep + StepPhoto и cascade-удаляет их при удалении Stage
    ✓ создаёт extra-work Step c pending approval и хранит qty/unitPrice
    ✓ создаёт Note каждого scope (personal / forMe / stage)
    ✓ создаёт Question в статусе open и поднимает answered при заполнении answerText
    ✓ отклоняет невалидное значение enum (extraApprovalStatus)

Test Suites: 1 passed, 1 total
Tests:       5 passed, 5 total
```

Если тесты падают:
- **FK-нарушение в truncate** → проверить Task 7, порядок таблиц
- **Missing .env.test** → прогнать Prerequisites Step B ещё раз
- **`prisma.step is undefined`** → Prisma Client не перегенерирован, повторить Task 9 Step 2

- [ ] **Step 2: Запустить ВСЕ e2e — убедиться, что не сломали существующее**

```bash
cd backend && npm run test:e2e 2>&1 | tail -10
```

Ожидание: `Test Suites: 3 passed, 3 total` (auth + projects-stages + step-schema). Если auth/projects-stages стали красными — `truncateAll` несовместим, разбираться.

---

## Task 11: Проверить, что миграция чисто применяется с нуля

**Files:**
- N/A (чистота миграции)

- [ ] **Step 1: Сбросить БД и применить все миграции с нуля**

```bash
cd backend && npx prisma migrate reset --force --skip-seed
```

Ожидание: `Database reset successful`, затем `Applying migration 20260419192345_initial_s1_s2`, затем `Applying migration <timestamp>_s3_d5_step_catalog`.

- [ ] **Step 2: Повторить seed и e2e**

```bash
cd backend && npx ts-node prisma/seed.ts && npm run test:e2e 2>&1 | tail -10
```

Ожидание: seed проходит (8 платформенных шаблонов), `Test Suites: 3 passed`.

---

## Task 12: Закоммитить и запушить, создать под-issue и PR

**Files:**
- N/A (git + gh ops)

- [ ] **Step 1: Проверить, что в коммит попадает**

```bash
cd ~/projects/web/Repair_control && git status
```

Ожидание: `backend/prisma/schema.prisma` (modified), `backend/prisma/migrations/<timestamp>_s3_d5_step_catalog/migration.sql` (new), `backend/apps/api/test/step-schema.e2e-spec.ts` (new), `backend/apps/api/test/setup-e2e.ts` (modified). Ничего лишнего.

- [ ] **Step 2: Закоммитить**

```bash
git add backend/prisma/schema.prisma backend/prisma/migrations backend/apps/api/test/step-schema.e2e-spec.ts backend/apps/api/test/setup-e2e.ts
git commit -m "$(cat <<'EOF'
feat(s3/d5): prisma-схема Step/Substep/StepPhoto/Note/Question + миграция

- Новые enum'ы: StepType, ExtraApprovalStatus, NoteScope, QuestionStatus
- FeedEventKind расширен 22 значениями (step_*, substep_*, step_photo_*, extra_work_*, note_*, question_*, stage_progress_recalculated)
- 5 новых моделей с cascade-FK на Stage/Project
- Обратные связи в Stage (steps, notes) и Project (notes)
- Обновлён truncateAll в setup-e2e
- Smoke-тест валидности схемы (5 тестов): create/cascade/enum-rejection
- ExtraWork через дискриминатор Step.type (по spec 2026-04-22-s3d5-schema-design.md)

Spec: docs/specs/2026-04-22-s3d5-schema-design.md
Sub-task 5.1 / Issue #5

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Создать под-issue 5.1 в GitHub и связать с #5**

```bash
gh issue create --repo SenSerafim/Repair_control \
  --title "[S3/D5 5.1] Prisma-схема Step/Substep/StepPhoto/Note/Question + миграция" \
  --milestone "Sprint 3 — Backend Steps, Approvals, Methodology" \
  --label sprint-3,backend,domain:stage,type:chore,priority:p0 \
  --body "Подзадача 5.1 из #5. Spec: docs/specs/2026-04-22-s3d5-schema-design.md. Критерии приёмки: миграция применяется на чистой БД, prisma generate проходит, smoke-тест зелёный."
```

Записать номер созданного issue (например, `#19`).

- [ ] **Step 4: Запушить ветку**

```bash
git push -u origin feat/s3-step-schema
```

- [ ] **Step 5: Открыть PR, который закрывает под-issue**

```bash
gh pr create --repo SenSerafim/Repair_control \
  --base dev_v1 \
  --head feat/s3-step-schema \
  --title "feat(s3/d5.1): prisma-схема Step/Substep/StepPhoto/Note/Question" \
  --body "$(cat <<'EOF'
Реализует подзадачу 5.1 из #5 согласно spec'у `docs/specs/2026-04-22-s3d5-schema-design.md`.

## Что сделано
- 4 новых enum'а (StepType, ExtraApprovalStatus, NoteScope, QuestionStatus)
- FeedEventKind расширен 22 значениями
- 5 новых моделей с cascade-FK
- Smoke-тест схемы (5 кейсов)
- Миграция `s3_d5_step_catalog` — применяется на чистой БД

## Вне скоупа (следующие подзадачи #5)
- Сервисы/контроллеры CRUD → 5.2
- Логика прав §6.4 → 5.3
- Presigned upload фото → 5.4
- Создание Approval при extra_work_requested → S3/D6
- Notes/Questions сервисы → 5.6 / 5.7
- Пересчёт прогресса → 5.8

Closes #<номер sub-issue из Step 3>
EOF
)"
```

Вписать в `Closes #...` реальный номер из Step 3. Вывод команды — URL PR.

---

## Definition of Done (критерии приёмки подзадачи 5.1)

- [x] `backend/prisma/schema.prisma` содержит 4 новых enum, 5 новых моделей, 22 новых значения `FeedEventKind`, обратные связи в `Stage`/`Project`
- [x] Миграция `s3_d5_step_catalog` в `backend/prisma/migrations/` применяется на чистой БД (`migrate reset && migrate deploy`)
- [x] `npx prisma generate` проходит, TS компилируется
- [x] `npm run test:e2e` — 3 suites passed (auth, projects-stages, step-schema), 5 новых тестов зелёных
- [x] Коммит + PR, связанный с sub-issue 5.1, который под-зависимость #5

---

## Self-Review (для автора плана)

**Spec coverage:** все 7 design-решений из spec'а покрыты:
1. ExtraWork discriminator → Task 4 (Step.type + extra* fields)
2. timestamp-as-state → Task 4 (doneAt/doneBy)
3. Substep rights в сервисе → Task 4 (только authorId в схеме, без политик)
4. Note.scope enum → Task 3 + Task 5
5. StepPhoto отдельная → Task 4
6. Question single answer → Task 5
7. Одна миграция → Task 8

**Placeholder scan:** нет TBD/TODO, каждый шаг содержит конкретные команды или код.

**Type consistency:** `prisma.step`, `prisma.substep`, `prisma.stepPhoto`, `prisma.note`, `prisma.question` — имена camelCase с первой строчной буквой, совпадают между тестом (Task 2) и схемой (Task 4/5).

**Scope check:** план покрывает только схему + миграцию + smoke-тест. Логика сервисов/контроллеров — в отдельных планах (5.2–5.8).
