# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Репозиторий в активной разработке. Структура:

- `backend/` — NestJS + Prisma + PostgreSQL + Redis + MinIO + Socket.IO + BullMQ. **S1–S5 закрыты**, API заморожен в 1.0.0 (`backend/docs/openapi.v1.json`, 148 путей, 32 модуля, 46 Prisma-моделей, 351 unit + 30 e2e тестов). Admin Panel поднят (коммит `563b23a`).
- `mobile/` — Flutter 3.35+ / Dart 3.11. **S6–S17 закрыты** (full 12-sprint roadmap). 176 тестов зелёные, `flutter analyze` чистый, `flutter build apk --flavor dev --debug` собирается, CI (`.github/workflows/mobile-ci.yml`) настроен, `mobile/README_RELEASE.md` готов к TestFlight/Play Internal.
- `design/` — 6 HTML-кластеров макетов (A Профиль / B Проекты / C Этапы / D Согласования / E Финансы / F Коммуникации), ~180 экранов. Источник дизайн-токенов для `mobile/lib/core/theme/tokens.dart`.
- `Сводное_ТЗ_и_Спринты.md` — **главный рабочий документ**. Изначальный план (9 спринтов) расширен на Flutter-часть до 12 спринтов (S6–S17). План итерации: `.claude/plans/users-serafim-project-repair-control-md-hidden-hellman.md`.
- Исходные `.docx`: ТЗ v1.0 (источник истины), v3.0 (UI-состояния, push-приоритеты), Gaps_Analysis (25 закрытых пробелов).
- `видео1255320897.txt`, `константин1.txt` — расшифровки созвонов; при конфликтах с ранними ТЗ **приоритет у цитат заказчика**.

Рабочая ветка — `dev_v1`. `main` принимает только зелёные спринты.

### Flutter roadmap (S6–S18, ~36 рабочих дней)

| Sprint | Дни | Scope |
|---|---|---|
| S6 | 11–12 | Foundation, design-tokens, shared widgets, Dio+refresh+idempotency, go_router, l10n. **ЗАКРЫТ.** |
| S7 | 13–14 | Auth (register/login/refresh/recovery), PinInput, legal-acceptance, device register. **ЗАКРЫТ.** |
| S8 | 15–16 | Профиль (hero + меню), edit-profile, 4 роли + add/switch, notif-settings с disabled-critical, language RU/EN, FAQ accordion, feedback, rep-rights info. **ЗАКРЫТ.** |
| S9 | 17–18 | Проекты list/archive/search, ProjectCard со светофором + прогресс, 5 фильтр-чипов, 3-step wizard, edit с archived-баннером, copy-sheet, card-menu, Money util. **ЗАКРЫТ.** |
| S10 | 19–20 | ConsoleScreen (5 semaphore-states + banner per state), AppHouseProgress CustomPainter, Stage domain, TeamScreen, AddMemberFlow (search+found/not-found+role), RepRightsSheet с 13 DomainAction. **ЗАКРЫТ.** |
| S11 | 21–22 | StagesScreen (tile+list + drag-and-drop reorder), StageDetailScreen с 8 computed display-states (+ overdue/late-start), PauseSheet 4 причины + обязательный комментарий для other, Create wizard (blank + 8 платформенных шаблонов + user templates), Template preview sheet, SaveAsTemplateSheet. **ЗАКРЫТ.** |
| S12 | 23–24 | Step/Substep/StepPhoto/Question/Note domain (5 freezed моделей), StepsRepository (23 endpoints), StepsController + StepDetailController.family, полный photo-upload flow с compressImage (1920/80 JPEG + EXIF-zero через crypto SHA-256), StepDetailScreen с подшагами-чеклистом + фото-grid + вопросы-thread, ExtraWorkSheet (auto-approval на бекенде), NotesScreen с фильтрами, интеграция в StageDetailScreen. **ЗАКРЫТ.** |
| S13 | 25–26 | Approval domain (5 scope × 4 status FSM), ApprovalsRepository (6 методов), ApprovalsController (pending/history buckets), ApprovalsScreen с tabs + scope chips, ApprovalDetailScreen со scope-dispatcher (plan/step/extra_work/deadline_change/stage_accept бодис), Approve/Reject/Resubmit sheets, Methodology с ETag-кешем статей, FTS-поиск со сниппет-подсветкой, `/methodology` global route. **ЗАКРЫТ.** |
| S14 | 27–28 | Finance domain (Payment kind/status + Dispute + BudgetBucket), PaymentsRepository (10 методов, Idempotency-Key авто через interceptor), BudgetScreen (total/work/materials/по этапам с progress-bars + overspent-badge), PaymentsList с filter-chips, CreateAdvance (foreman picker), DistributeSheet (validation по remainingToDistribute), PaymentDetail с scope-specific CTA (Confirm/Distribute/Dispute/Resolve/Cancel по role). **ЗАКРЫТ.** |
| S15 | 29–30 | Materials (8-status FSM, items checklist с MarkBought/Finalize/Confirm-delivery/Dispute/Resolve), Selfpurchase (3-status + approve/reject), Tools (my tools CRUD + ToolIssuance FSM issued→confirmed→return_requested→returned). Console плитки «Материалы/Самозакуп/Инструмент». Профиль — «Мои инструменты». **ЗАКРЫТ.** |
| S16 | 31–32 | Chat domain + WS `/chats` SocketService (11 events, JWT auth, reconnect 1s→30s), ChatsRepository (14 методов), MessagesController.family с real-time подписками + 15-min edit window, ProjectChatsScreen + ChatConversationScreen (reverse list + long-press edit/delete), Documents (7 categories, filter chips), Feed (cursor + FeedCategory mapping 9 категорий с приоритетом approval над stage_), ExportSheet (PDF/ZIP). **ЗАКРЫТ.** |
| S17 | 33–34 | FCM push (soft-fail init + token register + foreground local notifications), DeepLinkRouter (6 payload-видов → go_router пути), NotificationsScreen + NotificationsController (in-memory, unread badge), ConnectivityBanner (offline-пилюля глобально), OfflineQueue (JSON-persist, drain on online, 5 retry), NotificationSettings lock-icon + tooltip для critical, AppHouseProgress — pulse-анимация + glow at 100%, глобальный `/notifications` route, mobile-ci GitHub Actions workflow (analyze → test → build APK), `mobile/README_RELEASE.md` (чек-лист TestFlight/Play Internal). 176 тестов, analyze clean. **ЗАКРЫТ.** |
| S18 | 35–46 | Контакты поддержки (admin AppSetting whitelist + mobile `support_contacts/` feature, замена hardcoded в `help_screen.dart`); Юридические PDF (новая модель `LegalPublication` + публичный stream `/legal/public/:slug` с ETag/304 + admin upload UI + mobile bottom sheet через `url_launcher` external browser); База знаний (`KnowledgeCategory`/`Article`/`Asset` + GIN-FTS + manual video thumbnail + admin двухпанельный UI с upload progress + mobile feature `knowledge_base/` с `flutter_markdown` + `chewie/video_player` + ETag-кеш статей + 3 точки входа: profile, help, console NavGrid `?moduleSlug=`); Broadcast hardening (rewrite на `notifications.dispatch({ kind: 'admin_announcement' })` вместо костыля `membership_added`, фильтр по `DeviceToken.platform`, multi-projectIds, deep_link_router case); Per-scope FilesService policy (`FILE_SCOPE_POLICIES_JSON`: knowledge/=200MB+video, legal/=PDF only). RBAC: `admin.legal_publications.manage`, `admin.knowledge.manage`, `knowledge.read`. OpenAPI bump 1.1.0 → 1.2.0. **ЗАКРЫТ.** |

## Как ведётся работа (обязательная дисциплина)

### Спринты
1. Работа строго по плану из `Сводное_ТЗ_и_Спринты.md` §7–9. Порядок спринтов нельзя менять: каждый следующий опирается на готовую базу.
2. Бекенд (спринты 1–5) закрывается до старта Flutter (спринты 6–9). OpenAPI замораживается в конце спринта 5 (v1.0).
3. Спринт не может быть закрыт «частично». Несделанное переносится в день 1 следующего спринта и урезает его scope (§10).
4. В конце каждого спринта: демо ≤3 мин → прогон Definition of Done → обновление OpenAPI/ARCHITECTURE.md → запись в журнал.

### GitHub Issues как единственный источник задач
- Каждая задача спринта = отдельный GitHub Issue. Название: `[S{n}/D{day}] <кратко>` (пример: `[S2/D4] ProgressCalculator: 5 веток светофора`).
- Тело Issue обязано содержать: ссылку на раздел ТЗ (§…) и/или экран из `design/`, критерии приёмки, DoD-галочки спринта.
- Labels: `sprint-1`…`sprint-9`, `backend` / `flutter`, `domain:<name>` (auth/project/stage/approval/finance/materials/tool/chat/doc/feed/push/rbac/admin), `priority:p0|p1|p2`, `type:feature|bug|chore|test|docs`.
- Milestones: по одному на спринт (`Sprint 1 — Backend Foundation`, …, `Sprint 9 — Flutter Release`).
- Branch naming: `feat/s{n}-<domain>-<slug>`, `fix/…`, `chore/…`. Один PR закрывает один (реже несколько связанных) Issue — в теле PR `Closes #<id>`.
- Спорные решения обсуждаются в комментариях Issue, а не в чате — история остаётся в репозитории.

### Definition of Done (для любого PR)
- Код в целевой ветке, CI зелёный, миграции применяются на чистой БД.
- Покрытие критичной логики (финансы / согласования / RBAC) ≥80%, остальное ≥50–70% (конкретика — в разделе спринта).
- e2e-сценарии спринта прогнаны (автоматически где возможно, иначе вручную по чек-листу).
- OpenAPI / ARCHITECTURE.md / FINANCE_RULES.md обновлены под изменения.
- Новые эндпоинты видны в Grafana; ошибки идут в Sentry.

## Архитектура (big picture)

### Бекенд — модульный монолит на NestJS (DDD-light)
Граница между доменами строгая — это оставляет возможность выноса `chat` / `files` в микросервисы при росте нагрузки без переписывания.

- **Domain modules (16)**: auth, users, roles, projects, stages, steps, approvals, materials, tools, finance, chat, documents, feed, notifications, templates, methodology, admin.
- **Поперечные слои**: `rbac` (политики), `audit` (event log), `files` (S3-обёртка), `realtime` (Socket.IO gateway), `notifications` (FCM).
- **Лента событий = outbox**. Все доменные изменения публикуют события через `@nestjs/event-emitter` → подписчик пишет неизменяемую запись в `feed_events` (партиционирование по году). Никогда не писать в ленту напрямую из контроллеров — только через события.
- **RBAC = (системная_роль × участие_в_сущности × права_представителя)**. Решение централизовано в `AccessGuard` + декораторе `@RequireAccess('action', resourceLoader)`. Матрица — ТЗ §1.5. Любой новый эндпоинт оборачивается в guard.
- **Финансы**: `Money` — value object, int64 копейки; форматирование только на клиенте. Все `POST /payments*` защищены `Idempotency-Key` middleware.
- **Светофор и прогресс** — материализованные представления (`progressCache`), пересчёт триггером при изменении шага/паузы/дедлайна + cron 15 мин. Никогда не пересчитывать на каждый GET.
- **Real-time**: комнаты `project:{id}`, `stage:{id}`, `chat:{id}`, `user:{id}`. Socket.IO + Redis adapter для горизонтального масштабирования.
- **Файлы**: MinIO (S3-совместимо) + presigned URLs (TTL 5 мин). Фото — компрессия на клиенте до 1920px/80% + EXIF-zero. Превью PDF — фоновая задача BullMQ.

### Flutter — Clean Architecture
`presentation` (виджеты) → `application` (riverpod providers + usecases) → `domain` (модели + интерфейсы) → `data` (DTO, dio-клиенты, drift-репозитории).

- Папочная структура: `lib/core` (theme, network, storage, routing), `lib/features/<domain>`, `lib/shared` (виджеты).
- Дизайн-токены (цвета, типографика Manrope, радиусы, тени) из `Сводное_ТЗ_и_Спринты.md` §4 → `lib/core/theme/tokens.dart`. **Никаких хардкод-цветов** в виджетах.
- Каждый экран имеет 4 состояния: loading / empty / data / error (ТЗ v3 §21). Компоненты `AppLoadingState`, `AppEmptyState`, `AppErrorState` — обязательны.
- DTO/клиенты генерируются из OpenAPI (`openapi_generator` + `freezed`). После любого изменения API — ре-генерация.
- Оффлайн: drift-очередь отложенных действий. Без сети можно отметить шаг, прикрепить фото, оставить заметку — синхронизация при восстановлении связи (с разрешением конфликтов).

### Домены и их взаимосвязи
Полная доменная модель — §6 основного ТЗ. Ключевое:
- `Project` ↔ `Membership` ↔ `User` (с `RepresentativeRights` JSONB для представителя).
- `Stage` имеет 7 состояний (pending/active/paused/review/done/rejected/overdue) + computed `late-start` (дата старта прошла, Старт не нажат).
- `Approval` — FSM с 5 типами (план / шаг / доп.работа / дедлайн / приёмка этапа), `attemptNumber` инкрементится при повторе. Заказчик **не может** согласовать мимо бригадира (gaps §3.3).
- `Payment.parentPaymentId` — связывает аванс заказчик→бригадир с дочерними выплатами бригадир→мастер.
- Доп.работа попадает в бюджет **только** после одобрения заказчиком (ТЗ §4.3 + gaps §4.1).

## Компетенции команды (требуются для реализации)

### Backend
- **TypeScript / Node.js 20 + NestJS 10**: модули, DI, CQRS-light, guards, interceptors, `@nestjs/event-emitter`, `@nestjs/websockets`, `@nestjs/schedule`.
- **PostgreSQL 16 + Prisma 5**: миграции, JSONB (для прав и payload), FTS с русской морфологией (`pg_trgm`, `tsvector`), партиционирование по году, материализованные представления.
- **Redis 7 + BullMQ**: очереди (push, PDF, ZIP, пересчёт светофора), rate limiting, Socket.IO adapter.
- **Socket.IO (через `@nestjs/websockets`)**: комнаты, heartbeat, reconnect, presence.
- **Auth**: JWT (access 15 мин / refresh 30 дней с ротацией), bcrypt (cost 12), привязка refresh к `deviceId + ip-fingerprint`, rate limiting логина.
- **S3 / MinIO**: presigned URLs, lifecycle-политики (STANDARD → IA через 1 год, GLACIER через 3 года), `sharp` для thumbnails.
- **FCM (iOS APNs + Android)**: topics, conditions, deep-links. Абстракция `NotificationProvider` для санкционного failover на Mind Push.
- **PDF/ZIP**: `puppeteer-core` (A4-шаблон ленты), `archiver` (архив проекта).
- **Observability**: `pino` → Loki, Prometheus + Grafana, Sentry, OpenTelemetry.
- **Тестирование**: Jest (unit), Supertest (e2e), k6 (нагрузка), Pact-light (контракты).
- **Безопасность**: `Idempotency-Key` для финансов, rate limit (5 попыток / 5 мин), защита от энумерации телефонов, подписанные URL, bcrypt.
- **DevOps**: Docker Compose / k3s, GitHub Actions (lint → build → миграции → тесты → docker push), secrets в Vault/SSM, WAL-E/WAL-G бэкапы.

### Flutter
- **Flutter 3.22 + Dart 3.4**: flavors (dev/staging/prod), null-safety, ~60 FPS.
- **State**: Riverpod 2 (`riverpod_generator`), `freezed` для immutable-моделей/states.
- **Навигация**: `go_router` 14 с auth-гардами, role-гардами, deep-links из push.
- **Сеть**: `dio` + `retrofit` + интерсепторы (auth header, refresh on 401, Sentry breadcrumbs). Генерация клиентов из OpenAPI.
- **Local storage**: `drift` (SQLite, оффлайн-кеш и очередь), `flutter_secure_storage` (токены).
- **Real-time**: `socket_io_client` с экспоненциальным reconnect (1s → 30s).
- **Push**: `firebase_messaging` + `flutter_local_notifications` (foreground).
- **Медиа**: `image_picker`, `camera`, `photo_view`, `cached_network_image`, `image` (компрессия до 1920px/80% + EXIF-zero перед upload).
- **Документы**: `syncfusion_flutter_pdfviewer` или `pdfx` (PDF inline), `open_filex` (XLSX/DOCX).
- **UI**: `flutter_animate`, `lottie` (анимация дома-геймификации), `reactive_forms` или `flutter_hooks`+`freezed` для мультистеповых форм.
- **Локализация**: `flutter_intl` (ARB), RU по умолчанию, EN — задел.
- **Линтер**: `very_good_analysis` (строгие правила).
- **CI/CD**: Codemagic / Fastlane + GitHub Actions, подпись, TestFlight Internal, Google Play Internal Testing.

### Продуктовые / юридические
- 152-ФЗ: согласие на обработку ПДн с версионированием, пересогласие при смене версии.
- Единый формат сумм (int64 копейки), дат (ДД.ММ.ГГГГ + локальное время), timestamps в UTC.
- Локализация RU (default) / EN.

## Правила принятия решений
1. При конфликте между ТЗ v1.0 и v3.0 — побеждает финал (v1.0). При конфликте с ранними ТЗ — побеждают цитаты заказчика из расшифровок созвонов.
2. Любая новая фича, не входящая в §7 дорожной карты, — в backlog, а не в текущий спринт, без согласования.
3. Отложенные фичи (аннотации на фото, Pro-подписка, эквайринг) — **заложить в схему БД** (`FeatureFlag`, `Subscription`), **не реализовывать** (§5.7, §11).
4. Санкционный риск FCM — закладываем абстракцию `NotificationProvider` сразу, не после (§11).

## Полезные ссылки внутри репозитория
- План и DoD по каждому спринту — `Сводное_ТЗ_и_Спринты.md` §7–10.
- Матрица прав 4 ролей × 16 действий — ТЗ финал §1.5.
- Формула светофора и все 5 веток — ТЗ §2.4 + Gaps §2.
- Push-приоритеты и шаблоны — ТЗ v3 §15.2.
- Открытые вопросы и их статус — `Сводное_ТЗ_и_Спринты.md` §12.
- Чек-лист релиза — §13.
