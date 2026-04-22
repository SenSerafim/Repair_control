# Repair Control — Backend

NestJS + Prisma + PostgreSQL + Redis + MinIO + Socket.IO + BullMQ. Full S1–S5 complete.

- **Версия API**: `1.0.0` (замороженная после S5). OpenAPI: `/api/docs`; JSON: `backend/docs/openapi.v1.json`.
- **Postman**: `backend/postman/repair-control.v1.json` (162 endpoint, 22 папки).
- **Основной документ проекта**: `../Сводное_ТЗ_и_Спринты.md` (v1.1).
- **Архитектура**: [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Быстрый старт (5 минут)

```bash
# 1. Инфра — postgres / redis / minio
docker compose up -d

# 2. Копируем env и ставим зависимости
cp .env.example .env
npm ci

# 3. Применяем миграции и сид
npx prisma migrate deploy
npm run prisma:seed            # 8 платформенных шаблонов + методичка
npm run prisma:seed:staging    # 5 демо-пользователей + 2 проекта + FAQ (опц.)

# 4. Запускаем API
npm run start:dev              # :3000, docs на /api/docs
```

Healthcheck: `curl http://localhost:3000/healthz` → `{"status":"ok","db":true,"redis":true,"minio":true}`.

### Demo-учётки (после `prisma:seed:staging`)

| Роль | Телефон | Пароль |
|---|---|---|
| admin | `+79990000000` | `staging-demo-12345` |
| customer | `+79990000001` | `staging-demo-12345` |
| representative | `+79990000002` | `staging-demo-12345` |
| foreman | `+79990000003` | `staging-demo-12345` |
| master | `+79990000004` | `staging-demo-12345` |

## Команды

```bash
npm run start:dev      # Dev сервер с watch
npm run build          # Прод-сборка (dist/)
npm run lint:check     # ESLint без autofix
npm run lint           # ESLint с autofix + prettier
npm test               # Unit тесты (351 тест, 31 suite)
npm run test:cov       # Unit + coverage report
npm run test:e2e       # E2E (30 тестов, 9 suite)
npm run openapi:export # backend/docs/openapi.v1.json
npm run postman:export # backend/postman/repair-control.v1.json
```

## Staging

```bash
cp .env.staging.example .env.staging   # отредактировать секреты!
docker compose -f docker-compose.yml -f docker-compose.staging.yml --env-file .env.staging up -d
```

Поднимает: postgres / redis / minio / **api** (Docker image) / **admin-web** (nginx + Vite build).

Админка доступна на `http://localhost:8080`. Default login: `+79990000000` / `staging-demo-12345`.

## Load tests (k6)

См. `load/README.md`. Ручной запуск — не в CI.

```bash
k6 run load/s5-load.js -e API_URL=http://localhost:3000 -e PHONE=+79990000001 -e PASSWORD=staging-demo-12345
```

## Структура

```
backend/
├── apps/
│   ├── api/              — NestJS API (main)
│   │   ├── src/
│   │   │   ├── bootstrap/   bigint serializer, pino, sentry
│   │   │   └── modules/     19 доменных + 8 S5 (chats/realtime/documents/exports/notifications/feedback/admin/metrics/queues)
│   │   └── test/            e2e specs (9 файлов, 30 тестов)
│   └── admin-web/        — Vite + React (staging admin UI)
├── libs/
│   ├── common/           — PrismaService, Clock, Errors, Cursor, Money, AppConfig
│   ├── rbac/             — AccessGuard + матрица 47 actions × 4 ролей
│   └── files/            — MinIO presigned + sharp thumbnails
├── prisma/
│   ├── schema.prisma     — 46 моделей, 22 enums
│   ├── migrations/       — 7 миграций (S1–S5)
│   ├── seed.ts           — 8 шаблонов + 6 методических статей
│   └── seed-staging.ts   — 5 юзеров + 2 проекта + FAQ
├── scripts/
│   ├── export-openapi.ts — генерация openapi.v1.json
│   └── export-postman.ts — генерация Postman collection
├── docs/openapi.v1.json  — frozen OpenAPI spec v1.0 (162 endpoint)
├── postman/              — коллекция для мобильщиков
├── load/s5-load.js       — k6 load scripts
├── Dockerfile            — backend prod image
├── docker-compose.staging.yml
└── ARCHITECTURE.md
```

## Troubleshooting

### `Authentication failed against database server`
При свежем старте `docker compose up` инициализация postgres может оставить старый volume с другим паролем. Используйте `docker compose down -v` чтобы полностью пересоздать volumes, затем `docker compose up -d`.

### `Bind for 0.0.0.0:5432 failed: port is already allocated`
Docker proxy не освободил порт. Рестарт Docker Desktop + `docker compose up -d --force-recreate`.

### `Unable to get bucket region`
MinIO bucket ещё не создан. `FilesService.onModuleInit` создаёт его автоматически при первом старте — если не сработало, проверьте MinIO console (`:9001`) и создайте `repair-control` (или `repair-control-test` для e2e) вручную.

### Chromium / puppeteer не стартует в Docker
Используется `@sparticuz/chromium`. Dockerfile уже подтянул нужные alpine-зависимости (nss, freetype, harfbuzz, ttf-freefont). В dev-среде без chromium PDF-экспорт падает в fallback — plaintext.

## Интеграция с Flutter

1. Мобильщики берут `backend/docs/openapi.v1.json` → `openapi-generator-cli generate -g dart-dio`.
2. В Postman импортируют `backend/postman/repair-control.v1.json` для ручного тестирования.
3. WebSocket namespace: `/chats`, JWT в `handshake.auth.token`.
4. Push: DeepLink формат `repair://projects/{id}/{resource}/{resourceId}?role={role}`.

## Что НЕ реализовано (backlog)

- Реальная отправка FCM push на физ. устройство — требует service-account JSON от заказчика. Абстракция `NotificationProvider` + `NoopProvider` на месте; переключить через `FCM_ENABLED=true` + креды.
- Партиционирование `feed_events` / `chat_messages` по году (ТЗ §5.4) — задел в комментариях schema.
- Аннотации на фото (стрелочки) — явно отложено в §11 рисков.
- Pro-подписка / эквайринг (CloudPayments / ЮKassa) — stub-сервис, в §5.7.
