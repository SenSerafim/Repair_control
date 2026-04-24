# S3/D5 — Schema design: Steps, Substeps, Photos, ExtraWorks, Notes, Questions

**Дата:** 2026-04-22
**Issue:** [#5 `[S3/D5] Шаги, подшаги, фото, доп.работы, заметки, вопросы`](https://github.com/SenSerafim/Repair_control/issues/5)
**Подзадача:** 5.1 — Prisma-схема и миграция (фундамент под 5.2–5.8)
**Ветка:** `feat/s3-step-schema`

---

## Контекст

К концу спринта 2 в `backend/prisma/schema.prisma` есть: User/Auth, Project/Membership/Invitation, Stage/Pause, Template/TemplateStep, FeedEvent. Этапы существуют, но пустые — нет сущностей внутри этапа.

S3/D5 добавляет **внутренности этапа**: чек-лист (Step), подзадачи (Substep), фото выполнения (StepPhoto), доп.работы как тип шага (ExtraWork через дискриминатор), заметки трёх типов (Note), вопросы с FSM (Question).

Этот документ фиксирует **design-решения схемы** до написания миграции, чтобы не переделывать. Реализация сервисов/контроллеров — в подзадачах 5.2–5.8.

---

## Источники истины

- `docs/Сводное_ТЗ_и_Спринты.md` §6 — доменная модель (ключевые поля сущностей)
- `docs/Сводное_ТЗ_и_Спринты.md` §8 Спринт 3 День 5 — скоуп задач
- `docs/TZ_Kontrol_Remonta_v3 (1).docx` §6.4 — матрица прав подшагов
- `docs/TZ_Kontrol_Remonta_v3 (1).docx` §6.5 — поведение шага без фото
- `docs/TZ_Kontrol_Remonta_v3 (1).docx` §6.6 — заметки этапа + «задать вопрос»
- `docs/TZ_Gaps_Analysis.docx` §4.1 — доп.работа НЕ в бюджете до одобрения
- `docs/TZ_Gaps_Analysis.docx` §2.3 — пересчёт % при add шага в active этап

При конфликте ТЗ v1.0 финал → v3 → расшифровки созвонов (CLAUDE.md §Правила принятия решений).

---

## Принятые design-решения

### 1. ExtraWork — дискриминатор, не отдельная таблица

**Выбрано:** `Step.type: StepType { regular | extra }` + nullable поля extra на том же шаге.

**Альтернатива:** отдельная таблица `ExtraWork` с FK на Step.

**Причины:**
- §6 формулирует «ExtraWork (as a type of step)» — прямо указывает дискриминатор
- Drag-and-drop сортировка одним `orderIndex` работает для обоих типов без unionа
- OpenAPI-контракт для Flutter-разработчика проще: один ресурс `/steps` вместо `/steps` + `/extra-works` с одинаковой логикой
- Nullable-поля только на extra — приемлемая цена за простоту

### 2. Состояние шага — timestamp-as-state + отдельный enum для extra-approval

**Выбрано:**
- `doneAt: DateTime?` + `doneBy: String?` — шаг выполнен когда `doneAt != null`
- `extraApprovalStatus: ExtraApprovalStatus?` — `{ pending | approved | rejected }`, только для `type=extra`

**Альтернатива:** единый enum `StepStatus { open, done, extra_pending, extra_approved, extra_rejected }`.

**Причины:**
- Консистентность с существующей `Stage` (`startedAt/sentToReviewAt/doneAt` вместо enum-статуса)
- Две независимые оси для доп.работ: **одобрена ли заказчиком** (`extraApprovalStatus`) и **выполнена ли** (`doneAt`). По gaps §4.1 бюджет определяется одобрением, не выполнением — один enum это размазывает
- Audit-поля (`doneBy`, `extraApprovedBy`, `extraApprovedAt`, `extraRejectionReason`) хранятся на той же сущности

### 3. Права подшагов §6.4 — в сервисе, не в схеме

**Выбрано:** `Substep.authorId` (plain string userId), права проверяются в `SubstepsService` через сравнение `authorId == currentUser` + системную роль.

**Причины:**
- Схема не должна кодировать политики RBAC — это задача `AccessGuard` + `@RequireAccess` (уже есть в libs/rbac)
- Матрица §6.4:
  | Действие | Заказчик | Бригадир | Мастер |
  |---|---|---|---|
  | Добавить | ✓ | ✓ | ✓ |
  | Изменить/удалить свой | ✓ | ✓ | ✓ |
  | Изменить чужой | ✓ | ✓ | ✗ |
  | Отметить выполненным | ✗ | ✓ | ✓ |
- Индексы на `authorId` — для быстрых запросов «мои подшаги»

### 4. `Note.scope` — три значения, инварианты в сервисе

**Выбрано:** `NoteScope { personal | forMe | stage }` с явными инвариантами.

| scope | `authorId` | `addresseeId` | `stageId` | Видимость |
|---|---|---|---|---|
| `personal` | = currentUser | NULL | NULL | только автор |
| `forMe` | ≠ addresseeId | ≠ NULL | опционально | адресат и автор |
| `stage` | любой участник этапа | NULL | ≠ NULL | все участники этапа |

**Причины:**
- §6 перечисляет `scope(personal/forMe/stage)` — соответствует ТЗ
- `forMe` = «заметки мне от других» (односторонние задания/напоминания), отличается от `Question` отсутствием FSM и привязки к шагу
- Инварианты валидируются в `NotesService`, БД не enforce'ит (использовать check constraint — слишком сложно для малой выгоды)

### 5. `StepPhoto` — отдельная таблица, не generic Attachment

**Выбрано:** `StepPhoto { stepId, fileKey, thumbKey?, mimeType, size, width?, height?, uploadedBy, createdAt }`.

**Альтернатива:** generic `Attachment` с дискриминатором `ownerType` для Step/Approval/Chat/Document.

**Причины:**
- §6 перечисляет `Photo`, `ApprovalAttachment`, `Document` как **отдельные** сущности
- Явный FK даёт cascade-delete и чистые запросы «шаги без фото» для gaps §6.5 (шаг помечен `done` без photo → hi-priority push заказчику)
- `libs/files` остаётся **сервисом загрузки** (presigned, sharp thumbnails, mime/size), `StepPhoto` — **метаданные в БД**

### 6. `Question` — одиночный ответ + FSM, не тред

**Выбрано:** одна модель с nullable `answerText/answeredBy/answeredAt/closedAt`.

**Альтернатива:** `Question + QuestionReply[]` (thread-like).

**Причины:**
- §6: `Question { stepId, authorId, addresseeId, text, status(open/answered/closed) }` — одна запись
- v3 §6.6: вопрос — односторонний поток (автор спросил → адресат ответил → автор закрыл)
- ТЗ не упоминает многоходовую переписку в вопросах (это задача чата этапа, S5/D9)
- YAGNI: если понадобится — добавим `QuestionReply` без ломки существующей `Question`

### 7. Миграция — одна, атомарная

**Выбрано:** один файл `prisma/migrations/<timestamp>_s3_d5_step_catalog/`, все модели и enum'ы вместе.

**Причины:**
- Прод-БД ещё нет (первый деплой — S5/D10), атомарность не критична, но cleaner история
- Повторяет стиль `initial_s1_s2` из `S1+S2 backend` коммита
- Dev-миграция применяется одним `prisma migrate dev` локально

---

## Финальная схема (Prisma)

### Новые enum'ы

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

### Расширение `FeedEventKind`

```prisma
enum FeedEventKind {
  // ... существующие

  // Steps
  step_created
  step_reordered
  step_done
  step_reopened
  step_deleted

  // Substeps
  substep_created
  substep_updated
  substep_deleted
  substep_done
  substep_reopened

  // Photos
  step_photo_added
  step_photo_deleted

  // Extra works (триггер Approval живёт в S3/D6)
  extra_work_requested
  extra_work_approved
  extra_work_rejected

  // Notes (только scope=stage; personal/forMe — приватные, в ленту не пишем)
  note_created
  note_updated
  note_deleted

  // Questions
  question_created
  question_answered
  question_closed

  // Progress (gaps §2.3)
  stage_progress_recalculated
}
```

### `Step`

```prisma
model Step {
  id                    String    @id @default(cuid())
  stageId               String
  title                 String
  orderIndex            Int
  type                  StepType  @default(regular)

  // Справочная цена шага. Для type=regular — оценка из шаблона (TemplateStep.price) или
  // заданная вручную; не используется для расчёта бюджета в MVP (бюджеты считаются на уровне
  // Stage в S4). Для type=extra — игнорируется, фактическая стоимость = extraQty * extraUnitPrice.
  price                 BigInt?

  doneAt                DateTime?
  doneBy                String?

  // поля для type=extra (иначе NULL)
  extraQty              Int?
  extraUnitPrice        BigInt?                          // копейки
  extraApprovalStatus   ExtraApprovalStatus?
  extraApprovedBy       String?
  extraApprovedAt       DateTime?
  extraRejectionReason  String?

  createdBy             String
  createdAt             DateTime  @default(now())
  updatedAt             DateTime  @updatedAt

  stage                 Stage     @relation(fields: [stageId], references: [id], onDelete: Cascade)
  substeps              Substep[]
  photos                StepPhoto[]
  questions             Question[]

  @@index([stageId, orderIndex])
  @@index([type, extraApprovalStatus])
  @@index([doneAt])
}
```

### `Substep`

```prisma
model Substep {
  id         String   @id @default(cuid())
  stepId     String
  text       String
  authorId   String
  isDone     Boolean  @default(false)
  doneAt     DateTime?
  doneBy     String?
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt

  step       Step     @relation(fields: [stepId], references: [id], onDelete: Cascade)

  @@index([stepId, createdAt])
  @@index([authorId])
}
```

### `StepPhoto`

```prisma
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

### `Note`

```prisma
model Note {
  id           String   @id @default(cuid())
  scope        NoteScope
  authorId     String
  addresseeId  String?
  projectId    String?
  stageId      String?
  text         String
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  project      Project? @relation(fields: [projectId], references: [id], onDelete: Cascade)
  stage        Stage?   @relation(fields: [stageId], references: [id], onDelete: Cascade)

  @@index([authorId, createdAt])
  @@index([addresseeId, createdAt])
  @@index([stageId, createdAt])
  @@index([projectId, createdAt])
}
```

**Инварианты (валидация в `NotesService`):**
- `scope=personal` → `addresseeId IS NULL AND stageId IS NULL`
- `scope=forMe` → `addresseeId IS NOT NULL AND addresseeId != authorId`
- `scope=stage` → `stageId IS NOT NULL`

### `Question`

```prisma
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

**FSM:**
- `open` → `answered`: когда адресат (или участник этапа по праву `contractor/master`) заполняет `answerText`
- `answered` → `closed`: когда автор закрывает вопрос (выставляет `closedAt`)
- `open` → `closed`: если автор закрыл до ответа (передумал — valid transition)

### Изменения существующих моделей

```prisma
model Stage {
  // ... существующие поля
  steps Step[]
  notes Note[]
}

model Project {
  // ... существующие поля
  notes Note[]
}
```

---

## Что НЕ входит в подзадачу 5.1

- `StepsService` + `StepsController` CRUD и drag-and-drop → 5.2
- `SubstepsService` с проверкой прав §6.4 + push заказчику → 5.3
- `StepPhotoService` (presigned upload через `libs/files`, thumbnails, EXIF-zero) → 5.4
- Реальное создание `Approval` при `extra_work_requested` → S3/D6 (связано с `ApprovalsService`)
- `NotesService` (CRUD + поиск + валидация scope-инвариантов) → 5.6
- `QuestionsService` (FSM + push уведомления адресату) → 5.7
- Пересчёт `Stage.progressCache` при add/remove шага → 5.8 (через `ProgressCalculator`)
- OpenAPI эндпоинты — появятся с сервисами

---

## Критерии приёмки подзадачи 5.1

1. ✅ Миграция `s3_d5_step_catalog` применяется на чистой БД (`prisma migrate reset && prisma migrate deploy`)
2. ✅ `prisma generate` проходит без ошибок
3. ✅ `prisma format` нормализует файл, diff минимален
4. ✅ Линтер (eslint + prettier) зелёный для `schema.prisma` (если применимо)
5. ✅ Unit-тест схемы (опционально): Prisma Client умеет создать валидные `Step/Substep/Photo/Note/Question` и блокирует невалидные (CASCADE, FK, enum-значения). Полноценное покрытие инвариантов — в тестах сервисов 5.2–5.8.

---

## Открытые вопросы

Нет. Все design-решения зафиксированы.
