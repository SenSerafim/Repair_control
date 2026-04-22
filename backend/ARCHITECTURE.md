# ARCHITECTURE

## Структура

```
backend/
├── apps/api/            — точка входа NestJS (main.ts, app.module.ts)
│   ├── src/
│   │   ├── bootstrap/   — глобальные патчи (BigInt JSON.stringify)
│   │   └── modules/     — доменные модули (auth, users, projects, stages, templates, files, feed, health)
│   └── test/            — e2e-тесты (jest-e2e.json, global-setup.ts, setup-e2e.ts)
├── libs/
│   ├── common/          — PrismaService, ConfigSchema, DomainErrors, Clock, Cursor
│   ├── rbac/            — AccessGuard + @RequireAccess + матрица 4×16
│   └── files/           — MinIO presigned + sharp thumbnails
├── prisma/
│   ├── schema.prisma
│   ├── migrations/      — `initial_s1_s2` и последующие
│   └── seed.ts          — 8 платформенных шаблонов
└── docker-compose.yml   — postgres 16 + redis 7 + minio
```

## Поток запроса

```
HTTP Request
  → global ValidationPipe (class-validator DTO)
  → JwtAuthGuard (passport-jwt, access-token в Bearer)
  → AccessGuard (reflector читает @RequireAccess → resolveContext() → canAccess())
  → Controller (тонкий — только маппинг)
  → Service (бизнес-логика + Prisma + эмит FeedEvent)
  → PrismaService ($transaction для write-операций со стейджем/фидом в одной транзакции)
  → HTTP Response
```

Все domain-изменения эмитят событие через `FeedService.emit({ tx? })`. Это outbox ленты (ТЗ §3.3): подписчики и экспорт в PDF/ZIP работают с этой таблицей, не ходя в доменные модели.

## RBAC — как расширять

1. Добавить action в `DOMAIN_ACTIONS` (libs/rbac/src/rbac.types.ts).
2. Расширить `canAccess()` (libs/rbac/src/rbac.matrix.ts) — case со всеми 4 системными ролями + representative rights.
3. Повесить `@RequireAccess({ action, resource?, resourceIdFrom? })` на эндпоинт.
4. Если action работает с проектом/этапом — указать `resource: 'project' | 'stage'` и источник id — `AccessGuard` сам подгрузит membership и representative rights.
5. Покрыть тестами в `rbac.matrix.spec.ts` (все 4 ветки ролей) и — если нужна подгрузка ресурса — в `access.guard.spec.ts`.

## Clock и детерминированное время

`Clock` регистрируется глобально через `ClockModule` (`libs/common/src/time/clock.module.ts`). В проде — `SystemClock`; в e2e инжектится `FixedClock` через `TestingModuleBuilder.overrideProvider(Clock).useValue(clock)`.

**Важно:** любые timestamps, которые потом используются в расчётах (rate-limit, пересчёт дедлайна по паузам, истечение recovery-кода), должны браться из `this.clock.now()`, а не из Prisma `@default(now())`. Иначе детерминизм в тестах ломается и возможны классы багов «DB-время vs Clock-время».

Поймано и исправлено в S1-S2: `LoginAttempt.createdAt`, `Pause.startedAt` — теперь заполняются явно через Clock.

## BigInt сериализация

Prisma возвращает `BigInt` для всех колонок `BigInt` (`workBudget`, `materialsBudget`, `pauseDurationMs`). Express не умеет сериализовать их в JSON. Глобальный патч `apps/api/src/bootstrap/bigint-serializer.ts` добавляет `BigInt.prototype.toJSON`, который приводит к `number` (если безопасно, т.е. ≤ 2^53) или к строке.

Доменные сервисы в своих `serialize()`-хелперах дополнительно приводят BigInt к number явно — оставлено как защита, чтобы DTO типы оставались `number`, а не `number | string`.

## API contract exceptions

Ради RESTful-группировки фактические пути некоторых эндпоинтов отличаются от буквально заявленных в `Сводное_ТЗ_и_Спринты.md`:

| ТЗ пишет | Реально в API | Комментарий |
|---|---|---|
| `POST /stages/from-template/:templateId` | `POST /api/templates/:id/apply` | Шаблоны — самостоятельный ресурс; action `apply` RESTfully живёт под `/templates/:id/*`. |
| `POST /stages/:id/save-as-template` | `POST /api/templates/from-stage/:stageId` | То же самое — создание шаблона всегда под `/templates`. |

Мобильной команде: OpenAPI (`/api/docs`) — источник истины. Генерация клиентов идёт от него.

## Approvals FSM (ТЗ §8 спринт 3 день 6)

5 scope × 4 status (`pending → approved | rejected | cancelled`; из `rejected` можно resubmit → `pending` с `attemptNumber++`).

| scope | когда создаётся | addressee | `applyDecisionEffect` при approved | при rejected |
|---|---|---|---|---|
| `plan` | foreman → customer на всё дерево этапов | owner проекта | `project.planApproved=true` + все `stage.planApproved=true` + emit `plan_approved` | — (ждём resubmit) |
| `stage_accept` | `StagesService.sendToReview` автоматом | owner проекта | `stage.status=done` + emit `stage_accepted` | `stage.status=rejected` + emit `stage_rejected_by_customer` |
| `extra_work` | `StepsService.create(type=extra)` автоматом | owner проекта | `stage.workBudget += step.price` (увеличение в той же транзакции) + `step.status=pending` + emit `budget_updated` | `step.status=rejected`, бюджет не меняется |
| `deadline_change` | foreman → customer | owner проекта | `stage.plannedEnd = newEnd`, `stage.originalEnd = newEnd` + emit `deadline_changed` + `stage_deadline_recalculated` | — |
| `step` | foreman/master → foreman | foreman (или customer если нет foreman) | `step.status=done`, `doneAt` + `recalcStage` | — |

Инварианты:
- Reject требует `comment` (иначе 400 `approvals.reject_comment_required`).
- gaps §3.3 — customer-owner не может approve scope=step мимо foreman (если addressee = foreman и actor ≠ addressee → 403 `approvals.customer_bypass_foreman`).
- gaps §3.2 — `StagesService.start` бросает 409 `approvals.plan_not_approved`, если `project.requiresPlanApproval` и план ещё не одобрен.
- Все эффекты `apply*` выполняются в одной транзакции с `feed.emit({ tx })`.

## Cross-module forwardRef (паттерн)

Из-за двусторонней зависимости `Steps ↔ Approvals` (Steps создают Approval при extra_work; Approvals при approve меняют `step.status`) и `Stages ↔ Approvals` (Stages создают Approval при `sendToReview`; Approvals при approve меняют `stage.status`/`workBudget`) используется `forwardRef`:

- `StepsModule.imports = [forwardRef(() => ApprovalsModule)]` и в `StepsService`: `@Inject(forwardRef(() => ApprovalsService))`.
- `StagesModule.imports = [forwardRef(() => ApprovalsModule)]` и аналогично в `StagesService`.
- `ApprovalsModule.imports = [forwardRef(() => StagesModule)]` — нужен `ProgressCalculator` для пересчёта прогресса в `applyDecisionEffect`.

Все вызовы кросс-сервисных методов принимают optional `tx: Prisma.TransactionClient`, чтобы не терять транзакцию-родитель.

## Методичка — FTS и ETag (ТЗ §8 спринт 3 день 6, §5.2)

- `MethodologyArticle.searchVector` — GENERATED ALWAYS tsvector (russian dict) + GIN индекс + `pg_trgm` индекс на `title`. Миграция raw SQL (`prisma/migrations/*_add_methodology_fts`).
- Поиск — `ts_rank + ts_headline(snippet)` через `$queryRaw`. Trigram `%` как fallback для опечаток.
- `etag = sha256(title + body + refKeys.join(','))`. `version++` только при изменении `title|body` (не `orderIndex`). Контроллер `GET /methodology/articles/:id` возвращает `ETag` header и 304 на `If-None-Match`.
- Edit только admin (`methodology.edit`). Read — все аутентифицированные (`methodology.read`).

## Что ещё оседает в schema.prisma «на вырост» (ТЗ §5.7)

- `Subscription` / `FeatureFlag` — не добавлены (появятся в следующих спринтах).
- ~~`Document`, `Chat` — в схеме пока отсутствуют, добавим в S5 под их модули.~~ **S5: добавлены.**
- Партиционирование `FeedEvent` и `ChatMessage` по году (ТЗ §5.4) — задел. Переход — отдельная миграция через `pg_partman` поверх Prisma (вне migrate deploy). Комментарий в schema.prisma и трекер в backlog.

## S5 — Real-time, Docs, Feed-export, Push, Admin

### Модули (добавлены в app.module.ts)

- `QueuesModule` (глобально) — BullMQ регистрация (`exports`, `push`, `documents.thumbnails`) + `RedisClientModule` (`REDIS_CLIENT`, `REDIS_PUBSUB_CLIENT`) для socket.io-adapter и health-checks.
- `RealtimeModule` — WebSocket gateway `/chats` (socket.io), handshake JWT (`WsAuthService`), комнаты `chat:{id}` и `user:{id}`. Подписан через `@OnEvent` на внутренние события чата/экспорта/уведомлений и broadcast'ит в socket.io.
- `ChatsModule` — CRUD чатов (project/stage/personal/group), `messages.service` (edit-window 15 мин, soft-delete, forward, cursor-пагинация), `read-receipts.service` (lastReadAt, unreadCount).
- `DocumentsModule` — presigned-upload через `FilesService`, `confirm` с проверкой `minio.statObject`, auto-enqueue thumbnail для PDF. Worker использует `puppeteer-core + @sparticuz/chromium` для рендера 1-й страницы в JPG.
- `ExportsModule` — `ExportJob` FSM (queued → running → done/failed/expired). `PdfRendererService` (puppeteer HTML→PDF с graceful-fallback на plaintext если chromium недоступен), `ZipPackerService` (archiver), `ExportProcessor` BullMQ-worker. Idempotency-Key обязателен.
- `NotificationsModule` — абстракция `NotificationProvider` (FCM + Noop для тестов/FCM_ENABLED=false). `NotificationRouter` подписан на `feed.emitted`, мапит `FeedEventKind → NotificationKind` + получатели. Критичные kinds не отключаются. `PushProcessor` + `DeviceToken` cleanup при `token-not-registered`.
- `FeedbackModule` — `POST /feedback` + admin list/patch.
- `AdminModule` — FAQ CRUD, AppSettings (public subset через `GET /me/app-settings`). Telegram support URL — `support_telegram_url` (ТЗ §753).
- `MetricsModule` — `/api/metrics` (Prometheus), защищён `X-Metrics-Token`.

### Observability

- `nestjs-pino` — structured logs, `x-request-id` middleware, redact `authorization`/`password`/`token`/`idempotencyKey`/`fcmPrivateKey`.
- `@sentry/node` — init в `bootstrap/sentry.ts` до `NestFactory.create`, если `SENTRY_DSN` не пусто.
- `prom-client` — HTTP counter/histogram, BullMQ queue depth gauge, push и export counters.
- `/healthz` расширен: db + redis + minio (timeout 500ms на каждый).

### WebSocket — Redis adapter

`main.ts` использует `RedisIoAdapter` (extends `IoAdapter`) из `modules/realtime/ws-adapter.ts`. Два `ioredis` клиента (pub + sub-duplicate) + `createAdapter` из `@socket.io/redis-adapter` для горизонтального масштаба. Комнаты `chat:{id}` и `user:{id}` — точная фильтрация broadcast.

**Integration via event-emitter:**
- `ChatsService/MessagesService` эмитят `chat.message.sent`, `chat.participant.added`, и т.д.
- `ChatsGateway` подписан `@OnEvent('chat.message.sent')` → `server.to('chat:{id}').emit('message:new', ...)`.
- `FeedService.emit` после `INSERT feed_events` дополнительно эмитит `feed.emitted` → `NotificationRouter` фан-аут на push + `ChatsGateway` на `user:{id}` для `export:ready`, `notification:new`.

### FeedEventKind расширение

+16 значений: `chat_created`, `chat_message_sent`, `chat_participant_added/removed`, `chat_visibility_toggled`, `document_uploaded/updated/deleted`, `export_requested/completed/failed`, `feedback_received`, `admin_*`. Всего 91.

### RBAC — новые actions (+16)

`chat.write`, `chat.create_personal`, `chat.create_group`, `chat.toggle_customer_visibility`, `chat.moderate`, `document.read`, `document.write`, `document.delete`, `feed.export`, `notification.settings.self`, `feedback.create`, `admin.templates.manage`, `admin.faq.manage`, `admin.feedback.read`, `admin.settings.manage`, `admin.notifications.inspect`.

Новые resource hydrators в `AccessGuard`: `chat`, `document`, `chat_message`.

Расширенный `AccessContext` — `chatCreatedById`, `chatIsParticipant`, `chatIsActiveParticipant`, `chatVisibleToCustomer`, `chatType`, `documentUploadedById`.

### Idempotency

`@Idempotent()` на `POST /projects/:id/exports` (как в S4 для `payments`/`materials`/`selfpurchases`). Replay через `IdempotencyRecord` (TTL 24 ч).

### FCM абстракция (санкционный failover, ТЗ §11)

```
NotificationProvider (interface)
  ├── FcmProvider        — firebase-admin, реальная отправка при FCM_ENABLED=true
  └── NoopProvider       — для тестов и staging без ключей
```

Переключение — factory в `NotificationsModule` по ENV. Добавить Mind Push/Yandex Push — реализовать `NotificationProvider` и зарегистрировать в factory.

## Миграции

- `npx prisma migrate dev --name <slug>` — в dev: применяет и генерирует миграцию.
- `npx prisma migrate deploy` — в staging/prod/CI: применяет уже закоммиченные миграции.
- Любое изменение `schema.prisma` должно сопровождаться новой миграцией в том же PR.

## Как запустить локально

```bash
docker compose up -d postgres redis minio
cp .env.example .env         # или .env.local
npm ci
npx prisma migrate deploy
npm run prisma:seed          # 8 платформенных шаблонов
npm run start:dev            # API на :3000, docs на /api/docs
```

Тесты:
```bash
npm test                     # unit (135+)
npm run test:e2e             # e2e (требует поднятый postgres)
npm run test:cov             # с отчётом покрытия
```
