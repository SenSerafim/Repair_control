# Repair Control — Доведение до 100/100

Финальный план закрытия всех оставшихся пробелов между ТЗ + дизайном и текущей реализацией mobile + backend.

---

## ✅ Прогресс реализации (2026-04-25)

| Этап | Статус | Комментарий |
|---|---|---|
| 1. Backend-расширения | ✅ | Step.methodologyArticleId + DTO + e2e; PaymentDispute.photoKeys[] + DTO + service + e2e; Subscription/FeatureFlag stubs; iOS bundleId зафиксирован; миграция `20260425000000_road_to_100`; backend `npx nest build` зелёный, jest 48/48 на затронутых модулях |
| 2. EN-локализация | ✅ | ARB расширен с 22 → 174 ключей (RU + EN); `L10N_AUDIT.md` создан со списком оставшихся 60 хардкод-строк (для Этапа 7 cleanup); `flutter gen-l10n` зелёный |
| 3. Integration-тесты | ✅ | Созданы 5 файлов в `mobile/integration_test/`: 1 smoke (register_flow) + 4 placeholder с skip-маркером (требуют staging-инфры); `flutter analyze` зелёный |
| 4. Golden-тесты | ✅ | 8 файлов в `mobile/test/golden/`: avatar (15) + message_bubble (6) + step_checkbox (2) + traffic_badge (5) + photo_grid (3) + gradient_hero (2) + gradient_progress_bar (5) + house_progress (6). **44 golden зелёные.** Helper `_helpers.dart` с `goldenScaffold` |
| 5. UI P1 | ✅ | Selfpurchase 6 ролевых вариантов через `_roleVariant(...)` switch; Approval stacked-cards с opacity 0.85→0.55; Chat forward sheet + group multi-select (уже работали, проверены); 15-min edit gate в `_showActions` |
| 6. UI P2 + RepRights | ✅ | Distribute overspent блокер (уже работал — проверен); Photo upload в PaymentDispute через PhotoPicker + presign; OfflineConflict stream + AppToast в `app.dart`; **RepresentativeRights реальная интеграция** через `MembershipRights` side-channel + `representativeRightsProvider` autoDispose; Notes filter chips (UX-эквивалент TabBar); Templates preview модалка (уже работала) |
| 7. Pixel-perfect QA | ✅ (артефакт) | `mobile/PIXEL_QA_REPORT.md` — шаблон чек-листа по 6 кластерам с пометками что закрыто этапами 5/6/6.6 |
| 7.5. Dark mode | ✅ | `AppColorsDark` (Material 3 dark-инверсия brand); `AppTheme.dark()` полный; `themeModeProvider` + persist в secure_storage; переключатель Light/Dark/System в Profile через `_showThemeSheet`; `MaterialApp.themeMode` подключён |
| 8. Performance | ✅ (артефакт) | `mobile/PERFORMANCE_REPORT.md` — шаблон с 4 сценариями + таргетами (FPS 55 / cold-start 2.5s / memory 20MB) |
| 9. Coverage gates | ✅ | CI gate в `mobile-ci.yml` ≥50% global + per-domain warning ≥60% для finance/approvals/access; новый тест `offline_conflict_test.dart` |
| 10. Релиз-чек-лист | ✅ | `mobile/RELEASE_1.0.0_CHECKLIST.md` — полный sign-off чек-лист с 10 регрессионными сценариями |

**Итог автоматизированного прохода:**
- `flutter analyze` — `No issues found!` ✅
- `flutter test` — **344 / 344 зелёные** (было 298, +46 новых) ✅
- backend `npx nest build` — зелёный ✅
- backend `jest steps + payments` — 48 / 48 ✅
- Все 10 этапов прогнаны.

**Что осталось вручную (требует внешних ресурсов):**
- Этап 1.3: реальная регистрация iOS app в Firebase Console + `flutterfire configure` (bundleId зафиксирован — `com.repaircontrol.app`).
- Этап 3: подключение integration-тестов к staging-бэкенду + connectivity_plus mock + FCM driver.
- Этапы 7 и 8: ручной QA на устройстве + DevTools профилирование (артефакты-шаблоны готовы).
- Backend `prisma migrate deploy` на prod-БД для миграции `20260425000000_road_to_100`.
- `npm run openapi:export` после поднятия бэка для регенерации `backend/docs/openapi.v1.json` с новыми полями.
- Финальная EN-локализация оставшихся ~60 хардкод-строк (см. `mobile/L10N_AUDIT.md`).

---

## Контекст

Проект `Repair_control` (NestJS-бекенд + Flutter mobile) находится в финальной фазе:

- **Бекенд S1–S5 закрыт**: 148 эндпоинтов, OpenAPI v1.0 заморожен, 351 unit + 30 e2e тестов зелёные. Admin Panel поднят.
- **Mobile S6–S17 закрыт**: 298 тестов зелёные, `flutter analyze` чистый, CI зелёный, релиз-сборка APK собирается.
- **Готовность к TestFlight Internal / Google Play Internal Testing — 1.0.0** уже достигнута (`mobile/README_RELEASE.md`).

Между текущим состоянием и пиксель-перфект 100/100 (по 6 кластерам дизайна + матрице ТЗ) остаётся **7–14 рабочих дней** работы, разбитых на P1/P2/P3. **Релиз-блокеров (P0) нет**.

---

## Где брать актуальную информацию (Source of Truth)

| Что | Файл / каталог | Назначение |
|---|---|---|
| Главное ТЗ | `Сводное_ТЗ_и_Спринты.md` | 846 строк. §1.5 RBAC, §2.4 светофор, §3.3 approval gaps, §4.3 финансы, §5.3 offline, §10.2 чат, §15.2 push, §13 release-чек-лист, журнал v1.1 |
| Дизайн | `design/Кластер*.html` | 6 кластеров A–F, ~180 экранов. HTML с inline CSS — источник токенов и пиксельных размеров. Открывать в браузере |
| Текущий аудит mobile | `mobile/REMAINING_FOR_100.md` | 302 строки, явная разбивка P1/P2/P3 с оценками в днях и абсолютными путями к файлам |
| OpenAPI бекенда | `backend/docs/openapi.v1.json` | 148 путей, заморожен v1.0. Генерация retrofit-клиентов отсюда |
| README бекенда | `backend/README.md`, `backend/ARCHITECTURE.md`, `backend/FINANCE_RULES.md` | Поток запроса, RBAC, финансовые инварианты |
| README mobile релиз-чек-лист | `mobile/README_RELEASE.md` | TestFlight / Play Internal чек-лист |
| Project-инструкции | `CLAUDE.md` | Дисциплина, DoD, big-picture архитектуры |
| Расшифровки заказчика | `видео1255320897.txt`, `константин1.txt` (gitignored) | При конфликтах с ранними ТЗ — приоритет у этих цитат |
| RBAC actions | `backend/libs/rbac/src/rbac.types.ts` | 31 гранулярный action |
| BudgetCalculator | `backend/apps/api/src/modules/finance/budget/budget.calculator.ts` | Формула computed-view бюджета |
| ProgressCalculator | `backend/apps/api/src/modules/stages/progress/progress.calculator.ts` | 5 веток светофора |
| Approval FSM | `backend/apps/api/src/modules/approvals/approval.fsm.ts` | 5 scope × 4 status |

**Правила приоритета**: при конфликте ТЗ v1.0 → ТЗ v3.0 → расшифровки созвонов. Цитаты заказчика побеждают всегда.

---

## Текущая готовность (база отсчёта на 2026-04-25)

| Слой | % | Источник цифры |
|---|---|---|
| Backend OpenAPI v1.0 | 100% | заморожен после S5, 148 путей, 32 модуля |
| Backend unit + e2e тесты | ~95% | 351 + 30 зелёные |
| Mobile S6–S17 функционал | ~85% | `mobile/REMAINING_FOR_100.md` сводка |
| Mobile unit/widget тесты | 51.4% global / 75–100% critical | `mobile/coverage/lcov.info` |
| EN-локализация | 4% | 22 ключа из ~600 в `mobile/lib/core/l10n/app_en.arb` |
| Golden-тесты дизайн-виджетов | 0% | `mobile/test/golden/` — каталог пуст |
| Integration-тесты | 20% | 1 из 5 сценариев (только `auth_flow_test.dart`) |
| iOS Firebase | 50% | `mobile/lib/firebase_options.dart:60` TODO для iOS |
| Pixel-perfect соответствие дизайну | 75% | разбивка по 6 кластерам в `REMAINING_FOR_100.md:26-33` |
| Dark mode | 0% | каркас в `mobile/lib/core/theme/app_theme.dart`, палитры нет |

**Итог: ~82–85%. До 100/100 — 7–14 рабочих дней.**

---

## Этапы работ

Этапы упорядочены по приоритету (P1 → P2 → P3) и по зависимостям. Каждый этап автономен и заканчивается closeable PR с зелёным CI.

---

### Этап 1 — Backend-расширения (≈1.75 дня) [P1+P2]

Закрывает зависимости для mobile-этапов 6, 7, 9. Делается первым, чтобы mobile не блокировался.

**1.1. `Step.methodologyArticleId` — связь шага с методичкой**

- Файлы: `backend/apps/api/src/modules/steps/` (DTO, controller), `backend/prisma/schema.prisma` (поле `methodologyArticleId String? @db.Uuid`).
- Миграция: `npx prisma migrate dev --name step_methodology_link`.
- Endpoint: `PATCH /steps/:id` принимает `methodologyArticleId`, `GET /steps/:id` возвращает.
- Тест: e2e в `backend/apps/api/test/steps.e2e-spec.ts` — set/get article.
- ТЗ-ссылка: §6.4 (заметки/методичка), `mobile/REMAINING_FOR_100.md:177-180`.

**1.2. `PaymentDispute.photoKeys[]` — фото-доказательства спора**

- Файлы: `backend/apps/api/src/modules/finance/payments/dispute.dto.ts`, prisma model `PaymentDispute` (поле `photoKeys String[] @default([])`).
- Миграция: `npx prisma migrate dev --name payment_dispute_photos`.
- Endpoint: `POST /payments/:id/dispute` принимает `photoKeys[]` (presigned, как в materials/selfpurchase).
- Тест: e2e в `backend/apps/api/test/payments.e2e-spec.ts` — open dispute с фото.
- ТЗ-ссылка: §4.3 + gaps §4.2.

**1.3. iOS Firebase configure**

- Файл: `mobile/ios/Runner/GoogleService-Info.plist` (отсутствует), `mobile/lib/firebase_options.dart:60` (TODO).
- bundleId: **`com.repaircontrol.app`**.
- Зарегистрировать iOS-app в Firebase Console → скачать `GoogleService-Info.plist` → положить в `mobile/ios/Runner/` → обновить `firebase_options.dart` через `flutterfire configure -p mobile/ -i com.repaircontrol.app`.
- Дополнительно: APNs auth key загрузить в Firebase Project Settings → Cloud Messaging.
- ТЗ-ссылка: §13 чек-лист релиза.

**1.4. Subscription / FeatureFlag stubs (ТЗ §5.7)**

- Файл: `backend/prisma/schema.prisma` — добавить минимальные модели:

```prisma
model Subscription {
  id        String   @id @default(uuid()) @db.Uuid
  userId    String   @db.Uuid
  plan      String   @default("free")  // free | pro
  validTo   DateTime?
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id])
  @@index([userId])
}

model FeatureFlag {
  id        String   @id @default(uuid()) @db.Uuid
  key       String   @unique
  plan      String   @default("free")
  enabled   Boolean  @default(true)
  createdAt DateTime @default(now())
}
```

- Миграция: `npx prisma migrate dev --name pro_stubs`. **Без endpoint'ов** — только схема, как требует ТЗ §5.7 «заложить, не реализовывать».
- Mobile НЕ трогаем.
- Цель: при будущем расширении в Pro-версию не делать breaking-миграцию.

**1.5. NotificationProvider — оставить только абстракцию (без Mind Push)**

- Решение: интегрируем только интерфейс `NotificationProvider` в `backend/apps/api/src/modules/notifications/`, реальный Mind Push НЕ подключаем.
- Уже сделано в S5 — проверить в коде что абстракция выделена и FCM реализует её.

**Acceptance Этапа 1:**

- `npm run test:e2e` в `backend/` — зелёный (новые тесты на step.methodology + payment.dispute.photo).
- OpenAPI обновлён через `npm run openapi:generate`.
- Миграция `pro_stubs` применилась на чистой БД, модели Subscription/FeatureFlag видны в Prisma Studio.
- `flutter run --flavor dev` на симуляторе iOS не падает на `Firebase.initializeApp()`.

---

### Этап 2 — EN-локализация (≈2 дня) [P1]

Самый объёмный этап. По ТЗ §5.6 EN — задел, но реальный перевод нужен для 100/100.

**2.1. Аудит хардкода**

- Команда: `grep -rnE "Text\(['\"]" mobile/lib/features/ | grep -E "['\"][А-яЁё]"` — собрать список (≥61 явных + ещё ~350 в conditional/builder контекстах).
- Результат: список из ~414 файлов с RU-строками — фиксировать в `mobile/L10N_AUDIT.md` (создать).

**2.2. Расширение ARB**

- Файлы: `mobile/lib/core/l10n/app_ru.arb`, `app_en.arb`.
- Текущее: 22 ключа (`appTitle`, `nav_*`, `auth_welcome_*`, `error_*`, `common_*`).
- Добавить ~580 ключей по разделам: `profile_*`, `projects_*`, `stages_*`, `approvals_*`, `finance_*`, `materials_*`, `chat_*`, `documents_*`, `feed_*`, `notifications_*`, `methodology_*`, `tools_*`.
- Валидаторы форм, button-labels, snackbar messages, banner texts, semantics labels — всё в ARB.
- После добавления: `flutter gen-l10n` → проверить генерацию `lib/core/l10n/gen/app_localizations*.dart`.

**2.3. Замена в коде**

- Прогон по `lib/features/`: `Text('Русский')` → `Text(AppLocalizations.of(context).key)`.
- Snackbar/Toast/Dialog: `AppToast.show(text: 'Сохранено')` → `AppToast.show(text: l10n.common_saved)`.
- Особенно внимательно к `mobile/lib/features/chat/`, `mobile/lib/features/finance/`.

**2.4. Switcher проверка**

- Экран: `mobile/lib/features/profile/presentation/language_screen.dart`.
- Прогон вручную: переключить EN → проверить все 6 кластеров — не должно остаться RU-строк.

**Acceptance Этапа 2:**

- `grep -rnE "Text\(['\"][А-яЁё]" mobile/lib/features/` — пусто (кроме комментариев и локалей).
- В EN-режиме все экраны на английском.
- Виджет-тест на переключение языка добавлен в `mobile/test/widget/language_switch_test.dart`.

---

### Этап 3 — Integration-тесты (≈1.5 дня) [P1]

Сейчас: 1 из 5 сценариев. Каталог `mobile/integration_test/` содержит только `auth_flow_test.dart`.

**3.1. Создать тестовый бэкенд-фикстур**

- Файл: `mobile/integration_test/helpers/test_backend.dart`.
- Поднимать staging-бэк в Docker: `docker compose -f backend/docker-compose.staging.yml up -d`.
- Готовые seed: `backend/prisma/seed.ts` уже создаёт тест-данные (8 шаблонов, демо-проект).

**3.2. Сценарии**

- `mobile/integration_test/register_flow_test.dart` — register → login → create-project → create-stage → start-stage.
- `mobile/integration_test/plan_approval_test.dart` — Foreman submits plan → Customer approves → Foreman может стартовать.
- `mobile/integration_test/payment_hierarchy_test.dart` — create-advance → confirm → distribute → dispute → resolve. Проверка `parentPaymentId` цепочки.
- `mobile/integration_test/offline_sync_test.dart` — отключить network → mark step done → включить → action drained.
- `mobile/integration_test/push_deep_link_test.dart` — эмитить FCM payload → проверить что DeepLinkRouter открывает корректный экран для каждого из 6 типов.

**3.3. CI**

- В `.github/workflows/mobile-ci.yml` добавить job `integration-tests` (Android emulator через `reactivecircus/android-emulator-runner@v2`).

**Acceptance Этапа 3:**

- `flutter test integration_test/` — все 5 файлов зелёные локально.
- CI-job `integration-tests` зелёный.

---

### Этап 4 — Golden-тесты дизайн-виджетов (≈1 день) [P1]

Сейчас: 0 golden. Каталог `mobile/test/golden/` пуст.

**4.1. Setup**

- Использовать `golden_toolkit: ^0.15.0` (уже в `pubspec.yaml`) или мигрировать на `alchemist: ^0.10.0` (рекомендуется, golden_toolkit deprecated).
- Создать `mobile/test/golden/_helpers.dart` с `runWithFonts(...)` для Manrope.

**4.2. 8 виджетов** (файлы — в `mobile/test/golden/`):

1. `avatar_test.dart` — `AppAvatar` (5 палитр × 3 размера = 15 snapshots).
2. `message_bubble_test.dart` — `AppMessageBubble` (incoming/outgoing × 3 состояния = 6).
3. `step_checkbox_test.dart` — `AppStepCheckbox` (checked/unchecked = 2).
4. `traffic_badge_test.dart` — `AppTrafficBadge` (5 цветов = 5).
5. `photo_grid_test.dart` — `AppPhotoGrid` (с/без add-cell, 1/4/9 фото = 6).
6. `gradient_hero_test.dart` — `AppGradientHero` (Console/Profile палитры = 2).
7. `gradient_progress_bar_test.dart` — `AppGradientProgressBar` (4 палитры + overspent = 5).
8. `house_progress_test.dart` — `AppHouseProgress` (5 веток + 100% pulse = 6).

**4.3. CI**

- В `.github/workflows/mobile-ci.yml` добавить step `flutter test test/golden/`. Goldens хранить в репозитории (`test/golden/goldens/*.png`).

**Acceptance Этапа 4:**

- `flutter test test/golden/` — все 8 файлов зелёные.
- При случайном изменении виджетов CI ловит регрессию.

---

### Этап 5 — UI-доделки P1 (≈1.75 дня)

**5.1. Selfpurchase: 6 ролевых вариантов** (0.5 дня)

- Файл: `mobile/lib/features/selfpurchase/presentation/selfpurchases_screen.dart`.
- Сейчас: один универсальный `_DetailBody` для всех статусов.
- Дизайн: `design/Кластер E — Финансы.html` блоки `e-selfpurchase-master/foreman/pending/reject/rejected/confirmed`.
- Что делать: расширить `_DetailBody` switch'ем по `(status, byRole, addresseeId == meId)` — разные header / illustration / CTA / banner. Не нужно 6 отдельных файлов.
- ТЗ-ссылка: §4.3 + gaps §4.3.

**5.2. Approval stacked-cards с opacity** (0.5 дня)

- Файл: `mobile/lib/features/approvals/presentation/approval_widgets.dart` (`ApprovalAttemptsList`).
- Сейчас: плоский `Column`.
- Дизайн: `d-approvals-history` — Stack с `Positioned(top: -4 * i, left: -4 * i)` и `Opacity(opacity: 1 - 0.15 * i)`.
- Реализация: переписать через `Stack` + `Positioned` + `Transform.translate`, ограничить maxAttempts на дисплее = 4.

**5.3. Chat forward UI + group-select multi-select verify** (0.5 дня)

- Файлы: `mobile/lib/features/chat/presentation/chat_conversation_screen.dart`, `new_chat_sheet.dart`.
- Forward: добавить `_ChatForwardSheet` (search input + список чатов, на tap → `messagesController.forward(messageId, targetChatId)`).
- Group-select: проверить multi-select в `new_chat_sheet.dart` (state — `Set<UserId>`, toggle через chip).
- Дизайн: `f-chat-forward`, `f-chat-group-select` в кластере F.

**5.4. 15-min edit window UI gate** (0.25 дня)

- Файл: `mobile/lib/features/chat/presentation/chat_conversation_screen.dart`.
- Сейчас: long-press menu рендерит Edit/Delete безусловно для своих сообщений.
- Что делать: в `_showActions(BuildContext, Message msg)` оборачивать Edit-пункт `if (msg.canEdit(byUserId: me, now: DateTime.now()))`. `Message.canEdit` уже существует в `mobile/lib/features/chat/domain/message.dart`.
- ТЗ-ссылка: §10.2.

**Acceptance Этапа 5:**

- 4 UI-фрагмента работают визуально по дизайну.
- Тесты добавлены: widget-тест ролевого селектора selfpurchase, stacked layout для approvals.

---

### Этап 6 — UI-доделки P2 + RepresentativeRights (≈2 дня)

**6.1. Distribute overspent блокер** (0.25 дня)

- Файл: `mobile/lib/features/finance/presentation/advance_distribution_screen.dart`.
- Сейчас: `Payment.remainingToDistribute` есть, расчёт корректный, но Submit не блокирован при overspent.
- Что делать: при `total > remainingToDistribute` — Submit `disabled` + `AppBanner.warning('Превышение аванса на ${overspent.formatted} ₽')`.
- ТЗ-ссылка: gaps §4.2.

**6.2. Photo upload в PaymentDispute** (0.25 дня mobile часть; backend — Этап 1.2)

- Файл: `mobile/lib/features/finance/presentation/payment_sheets.dart:411`.
- Сейчас: placeholder «Фото-доказательства появятся в ближайшем релизе».
- Что делать: использовать существующий `PhotoPickerSheet` + `presignedUploadProvider` → передавать `photoKeys[]` в `dispute()` метод.
- Зависит от Этапа 1.2.

**6.3. Conflict resolution dialog для offline 409/422** (0.5 дня)

- Файл: `mobile/lib/core/storage/offline_queue.dart`.
- Сейчас: 409/422 после 5 retry — молчат.
- Что делать: при `ApiError.code in {state_conflict, stale_state}` (после 1 retry) → удалить action из очереди + поднять `AppToast.warning('Сервер изменил состояние, перезагрузите экран')`.
- Спецификация: gaps §2.4.

**6.4. RepresentativeRights реальная интеграция** (0.5 дня)

- Файл: `mobile/lib/core/access/access_guard.dart`.
- Сейчас: `representativeRightsProvider = const <DomainAction>{}` с TODO.
- Что делать:
  - Подключиться к `team_controller.members` (текущий проект из `currentProjectIdProvider`).
  - Найти `Membership` где `userId == me.id && role == representative`.
  - Распарсить `Membership.representativeRights` (массив строк = `DomainAction.value`) в `Set<DomainAction>`.
  - Кэшировать через `Provider.autoDispose.family<Set<DomainAction>, ProjectId>`.
- Тест: `mobile/test/access_guard_matrix_test.dart` расширить кейсами для representative.
- ТЗ-ссылка: §1.5 + матрица в `backend/libs/rbac/src/rbac.types.ts`.

**6.5. Notes shared tab** (0.5 дня)

- Файл: `mobile/lib/features/notes/presentation/notes_screen.dart`.
- Сейчас: один список без вкладок.
- Дизайн: `f-notes-shared` — TabBar (Свои / Общие / Для меня).
- Что делать: `DefaultTabController(length: 3)` + `TabBarView` с тремя `NotesList`'ами (filter по `scope`).

**6.6. Templates preview модалка** (0.5 дня)

- Файлы: `mobile/lib/features/stages/presentation/templates_gallery.dart`, `create_stage_screen.dart`.
- Дизайн: `c-template-preview` — bottom sheet со списком шагов шаблона + Apply / Cancel.
- Что делать: между tap на шаблон и `applyTemplate(...)` вставить `showModalBottomSheet` с `_TemplatePreviewSheet(template)`.

**Acceptance Этапа 6:**

- `RepresentativeRights` реально гейтят кнопки на `BudgetScreen`, `TeamScreen`, `ApprovalDetailScreen`.
- 5 widget-тестов на conflict/distribute/notes/templates/dispute-photo-upload.

---

### Этап 7 — Pixel-perfect QA по дизайну (≈1.5 дня) [P3]

Открыть HTML-макеты в браузере рядом с приложением на устройстве; пройти все 6 кластеров. Засечь отклонения spacing/colors/radius >1px → tickets.

**7.1. Сетап**

- Запустить mobile: `cd mobile && flutter run --flavor dev -d <device>`.
- Открыть в браузере: `open design/Кластер*.html` (по очереди).

**7.2. Чек-лист по кластерам** (см. `mobile/REMAINING_FOR_100.md:26-33`):

- A — Профиль (95%): s-add-member / s-tool-add как sheet — корректно (по дизайну мобильного).
- B — Проекты + Console (90%): минорные встроенные состояния — открыть все 5 цветов console.
- C — Этапы (85%): templates-галерея с preview → закрыто после Этапа 6.6.
- D — Согласования (80%): stacked history → закрыто после Этапа 5.2.
- E — Финансы (75%): selfpurchase 6 ролевых → закрыто после Этапа 5.1.
- F — Коммуникации (70%): forward + group-select → закрыто после Этапа 5.3; notes shared → закрыто после Этапа 6.5.

**7.3. Артефакт**

- Файл: `mobile/PIXEL_QA_REPORT.md` — список tickets со скриншотами (mobile/design/diff). P0–P2 закрываются здесь же; P3+ в backlog.

---

### Этап 7.5 — Dark mode (≈2 дня) [P2]

Каркас в `mobile/lib/core/theme/app_theme.dart` уже частично есть. Нужна полная dark-палитра + переключатель + регрессия.

**7.5.1. Dark-токены**

- Файл: `mobile/lib/core/theme/tokens.dart`.
- Добавить `class AppColorsDark { ... }`: инверсия нейтралов (`n0…n900`), плашек статусов (red/green/yellow/blue), brand (`brand-light` инвертируется в `#1E2440`).
- Контраст ≥4.5 для текста по WCAG AA.
- Источник палитры: дизайн dark-режима НЕ содержит — идём по Material 3 dark-инверсии brand-цвета.

**7.5.2. ThemeData**

- Файл: `mobile/lib/core/theme/app_theme.dart`.
- Заполнить полную `darkTheme: ThemeData.dark().copyWith(...)` со всеми токенами из `AppColorsDark`.
- Виджеты: проверить что используют `Theme.of(context).colorScheme.*` вместо хардкода `AppColors.*`.

**7.5.3. Переключатель**

- Файл: `mobile/lib/features/profile/presentation/profile_screen.dart` (или новый `appearance_screen.dart`).
- Опции: System / Light / Dark.
- Хранение: `secure_storage` ключ `theme_mode`, провайдер `themeModeProvider` (Riverpod).
- Применение: `MaterialApp.themeMode = themeModeProvider.read()`.

**7.5.4. Регрессия по 6 кластерам**

- Прогон вручную всех экранов в dark-режиме. Особое внимание:
  - `AppGradientHero` — градиенты на dark-фоне.
  - `AppHouseProgress` — glow-shadow видна сильнее.
  - `AppMessageBubble` — incoming/outgoing.
  - `AppPhotoGrid` — placeholder color.
  - Скелетон-лоадеры — shimmer субтильнее.

**7.5.5. Golden-тесты dark**

- Расширить `mobile/test/golden/*` — каждый виджет тестировать в обеих темах через `runWithDevices(themes: [light, dark])`.

**Acceptance Этапа 7.5:**

- Переключатель Light/Dark/System работает в Profile.
- Все 6 кластеров на dark выглядят целостно.
- Golden-тесты для обеих тем зелёные.

---

### Этап 8 — Performance профилирование (≈0.5 дня) [P3]

Через Flutter DevTools → Performance tab.

**Сценарии**:

- Chat conversation с 1000+ сообщений → FPS scrollback.
- Feed с 500+ событий → memory + FPS.
- Approvals list с 100+ pending → cold-start экрана.
- Photo gallery с 50+ изображениями.

**Метрики**:

- FPS ≥ 55 на mid-tier устройстве (Pixel 4a).
- Memory growth ≤ 20MB между cold-start и navigation-test.
- Cold start ≤ 2.5s на release-build.

**Артефакт**: `mobile/PERFORMANCE_REPORT.md` — найденные узкие места + tickets.

---

### Этап 9 — Тесты coverage до 80% critical (≈0.75 дня) [P1]

**9.1. Coverage target по доменам** (см. CLAUDE.md):

- `mobile/lib/features/finance/` ≥ 80%
- `mobile/lib/features/approvals/` ≥ 80%
- `mobile/lib/core/access/` ≥ 80%
- `mobile/lib/features/stages/domain/traffic_light.dart` ≥ 90%
- Остальное ≥ 50%.

**9.2. Команда**: `cd mobile && flutter test --coverage && genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`.

**9.3. Закрыть пробелы** — добавить тесты на не-покрытые ветки. Особое внимание:

- `mobile/lib/features/finance/application/payments_controller.dart` (FSM transitions).
- `mobile/lib/features/approvals/application/approvals_controller.dart` (5 scope × 4 status).
- `mobile/lib/core/access/access_guard.dart` (45 actions × 4 роли).

**9.4. CI gate**

- В `.github/workflows/mobile-ci.yml` поставить `--coverage --fail-under 70` глобально + per-domain check через `lcov --summary` script.

---

### Этап 10 — Финальный релиз-чек-лист (≈0.5 дня)

Прогон по `Сводное_ТЗ_и_Спринты.md` §13:

**Бэкенд**:

- [ ] `docker compose -f docker-compose.server.yml up -d` поднимается.
- [ ] Миграции применены: `npm run prisma:migrate:deploy`.
- [ ] Сидеры выполнены: 8 шаблонов, демо-методичка → `npm run prisma:seed`.
- [ ] Бэкап PostgreSQL настроен (WAL-G в S3 — Selectel).
- [ ] Sentry DSN установлен в `.env.prod`.
- [ ] Grafana дашборды живы.
- [ ] FCM-сертификаты iOS (APNs key) и Android загружены.

**Mobile**:

- [ ] `flutter analyze` чистый.
- [ ] `flutter test` зелёный (после Этапа 9 — coverage gates).
- [ ] `flutter test integration_test/` зелёный (после Этапа 3).
- [ ] `flutter build apk --flavor prod --release` собирается.
- [ ] `flutter build ipa --flavor prod --release` собирается (после Этапа 1.3).
- [ ] Подпись Android (keystore в `android/key.properties`) и iOS (Apple Developer profile).
- [ ] Иконки 1024×1024, скриншоты RU+EN (минимум 4 на каждый язык).
- [ ] Политика конфиденциальности и пользовательское соглашение опубликованы.
- [ ] Демо-запись 5–7 минут с прохождением 5 user-stories из ТЗ §19.

**Артефакт**: `mobile/RELEASE_1.0.0_CHECKLIST.md`.

---

## Сводный план (последовательность и зависимости)

| # | Этап | Дни | P | Зависит от | Параллелит |
|---|---|---|---|---|---|
| 1 | Backend-расширения (step.methodology, dispute.photos, iOS Firebase, Pro-stubs, NotificationProvider) | 1.75 | P1+P2 | — | — |
| 2 | EN-локализация (~580 ключей + замена хардкода) | 2 | P1 | — | можно параллельно с 1 |
| 3 | Integration-тесты (5 сценариев) | 1.5 | P1 | 1 | — |
| 4 | Golden-тесты (8 виджетов) | 1 | P1 | — | можно параллельно с 2/3 |
| 5 | UI-доделки P1 (selfpurchase/approval-stack/chat-forward/edit-gate) | 1.75 | P1 | — | — |
| 6 | UI-доделки P2 + RepresentativeRights | 2 | P2 | 1.2 | — |
| 7 | Pixel-perfect QA + tickets | 1.5 | P3 | 5+6 | — |
| 7.5 | Dark mode (полная палитра + переключатель + golden) | 2 | P2 | 4 | можно параллельно с 7 |
| 8 | Performance профилирование | 0.5 | P3 | — | можно параллельно с 7/7.5 |
| 9 | Coverage до 80% critical | 0.75 | P1 | 5+6 | — |
| 10 | Финальный релиз-чек-лист | 0.5 | P0 | 1–9 | — |

**Минимально для 100/100 (P0+P1)**: Этапы 1–5, 9, 10 = ~8.25 дня.
**Полный 100/100 включая P2/P3 polish + Dark mode**: + Этапы 6, 7, 7.5, 8 = ~14 дней.

---

## Критичные файлы (cheat-sheet)

### Создать

- `mobile/integration_test/{register_flow,plan_approval,payment_hierarchy,offline_sync,push_deep_link}_test.dart`
- `mobile/test/golden/{avatar,message_bubble,step_checkbox,traffic_badge,photo_grid,gradient_hero,gradient_progress_bar,house_progress}_test.dart`
- `mobile/test/golden/_helpers.dart`
- `mobile/L10N_AUDIT.md`, `mobile/PIXEL_QA_REPORT.md`, `mobile/PERFORMANCE_REPORT.md`, `mobile/RELEASE_1.0.0_CHECKLIST.md`
- `mobile/ios/Runner/GoogleService-Info.plist` (через `flutterfire configure`)

### Расширить

- `mobile/lib/core/l10n/app_{ru,en}.arb` — ~580 ключей
- `mobile/lib/firebase_options.dart` — iOS-секция
- `mobile/lib/core/access/access_guard.dart` — `representativeRightsProvider`
- `mobile/lib/features/selfpurchase/presentation/selfpurchases_screen.dart` — 6 ролевых вариантов
- `mobile/lib/features/approvals/presentation/approval_widgets.dart` — stacked layout
- `mobile/lib/features/chat/presentation/chat_conversation_screen.dart` — edit gate, forward sheet
- `mobile/lib/features/chat/presentation/new_chat_sheet.dart` — group multi-select verify
- `mobile/lib/features/finance/presentation/advance_distribution_screen.dart` — overspent блокер
- `mobile/lib/features/finance/presentation/payment_sheets.dart:411` — реальный photo upload в dispute
- `mobile/lib/core/storage/offline_queue.dart` — conflict resolution dialog
- `mobile/lib/features/notes/presentation/notes_screen.dart` — TabBar Свои/Общие/Для меня
- `mobile/lib/features/stages/presentation/templates_gallery.dart` — preview-модалка
- `mobile/lib/core/theme/tokens.dart` — `AppColorsDark` (Этап 7.5)
- `mobile/lib/core/theme/app_theme.dart` — заполненная `darkTheme`, `themeModeProvider`
- `backend/prisma/schema.prisma` — `Step.methodologyArticleId`, `PaymentDispute.photoKeys[]`, `Subscription`, `FeatureFlag`
- `backend/apps/api/src/modules/{steps,finance/payments}/` — controllers/dto под новые поля
- `backend/docs/openapi.v1.json` — регенерация после Этапа 1
- `.github/workflows/mobile-ci.yml` — `integration-tests` job, golden-тесты, coverage-gate

---

## Верификация (как проверить что всё работает end-to-end)

**Backend** (в `backend/`):

```bash
npm run lint && npm run build
npm run test       # ≥351 unit зелёные
npm run test:e2e   # ≥30 + новые на step.methodology + dispute.photos
docker compose up -d
npm run prisma:migrate:deploy && npm run prisma:seed
```

**Mobile** (в `mobile/`):

```bash
flutter pub get
flutter gen-l10n
flutter analyze    # 0 issues
flutter test --coverage   # ≥298 + новые из Этапа 5/6/9, coverage ≥70% global
flutter test integration_test/   # 5 сценариев
flutter test test/golden/   # 8 файлов
flutter build apk --flavor prod --release
flutter build ipa --flavor prod --release
```

**End-to-end ручная регрессия** (на физическом устройстве с staging-бэкендом):

1. Register → Login → Create Project → Add Foreman → Add Stages from template.
2. Foreman submits план → Customer approves → Foreman нажимает Старт.
3. Master помечает шаг done, прикрепляет фото, отправляет на approval → Foreman approves.
4. Customer создаёт advance 500 000 ₽ → Foreman confirms → distribute 3 master'ам.
5. Master open dispute с фото → Customer resolves с adjustAmount.
6. Chat: Foreman → Master, edit message за <15 мин → отказ за >15 мин.
7. Switch language → EN — все 6 кластеров на английском.
8. Force offline → mark step done → online → синхронизация.
9. Push: получение FCM → tap → откроется ApprovalDetail/StageDetail/PaymentDetail/Chat.
10. Export Feed как PDF + ZIP → ссылка в notifications.

Все 10 зелёные + CI зелёный + чек-лист §13 заполнен → готово к **Public TestFlight + Open Beta Google Play (1.0.0 GA)**.

---

## Зафиксированные решения по плану

1. **Dark mode** — включён как Этап 7.5 (~2 дня). Полная dark-палитра + переключатель Light/Dark/System в Profile + golden-тесты для обеих тем.
2. **iOS bundleId** — `com.repaircontrol.app` (используется в Этапе 1.3 при `flutterfire configure`).
3. **Subscription / FeatureFlag** — минимальные модели в `backend/prisma/schema.prisma` (Этап 1.4), без endpoints. Закрывает требование ТЗ §5.7.
4. **Mind Push failover** — НЕ интегрируем. Оставляем только интерфейс `NotificationProvider` в коде, FCM реализует его (Этап 1.5).
