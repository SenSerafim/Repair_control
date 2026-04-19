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

## Что ещё оседает в schema.prisma «на вырост» (ТЗ §5.7)

- `Subscription` / `FeatureFlag` — не добавлены в S1-S2 (появятся в следующих спринтах).
- `Document`, `Payment`, `MaterialRequest`, `ToolItem`, `Approval`, `Chat`, `Note` — в схеме пока отсутствуют, добавим в S3-S5 под их модули.
- Партиционирование `FeedEvent` по году (ТЗ §5.4) — задел на момент, когда лента начнёт активно расти; сейчас обычная таблица.

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
