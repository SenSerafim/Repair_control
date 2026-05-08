# IMPLEMENTATION_TODO v1 — Repair_control до 100/100

> Машинно-исполнимая спецификация для ИИ-агента в Claude Code.
> Источник: `Сводное_ТЗ_и_Спринты.md` + `design/Кластер*.html` + аудит `git status`.
> Дата создания: 2026-04-26. Автор: предыдущая агент-сессия (план в `~/.claude/plans/...moonlit-dawn.md`).

---

## 0. Как читать (для ИИ-агента)

### 0.1 Порядок выполнения
1. **S0** (системные предусловия) — выполнять В ПЕРВУЮ ОЧЕРЕДЬ. Снимают корневые причины 80% багов.
2. **P0** (критичные баги, включая P0.7 — 5 backend-дыр в видимости) — после S0.
3. **P1** (UX, тексты, иерархия отчётности UI, прозрачность бюджета) — после P0.
4. **P2** (multi-team invite-by-code) — последним.

**ОБЯЗАТЕЛЬНО** прочитать §2A (матрица иерархии и видимости) ПЕРЕД P0.7 / P1.4 / P1.5 — без этой матрицы решения по фильтрам и UI будут нелогичными.

### 0.2 Формат каждой задачи

```
### <ID> <Название>
**Status:** ☐ todo / ⏳ in-progress / ✅ done
**🎯 Цель**: что должно быть в результате.
**📍 Где**: ТЗ, дизайн, файлы backend / mobile.
**🔗 Зависит от**: ID других задач, выполняемых первыми.
**✅ Pre-conditions**: проверки ПЕРЕД началом (grep, file:line).
**🛠 Steps**: точные действия (Read, Edit, Write).
**🧪 Verify**: команды и smoke-сценарии для подтверждения.
**📝 Notes**: подводные камни, известные особенности.
```

### 0.3 Точки запуска тестов
- После каждого блока (S0, P0, P1, P2) — `cd backend && pnpm test` + `cd mobile && flutter analyze && flutter test`.
- Smoke-проверки — отдельным циклом в конце по разделу 7.

### 0.4 Безопасные модификации
- НЕ менять структуру `freezed`-моделей без `flutter pub run build_runner build --delete-conflicting-outputs`.
- НЕ удалять модифицированные файлы из `git status` без понимания, что в diff (использовать `git diff <file>` сначала).
- НЕ амендить чужие коммиты, создавать новые.

---

## 1. Контекст и корневые причины

Пользователь сообщил **11 проблем** в работающем приложении. Аудит выявил **4 системные корневые причины**:

| # | Корневая причина | Кратко | Затронутые проблемы |
|---|---|---|---|
| 1 | **RBAC-рефакторинг не завершён** | Бекенд переехал на JSONB булевы флаги. Mobile парсинг частично унифицирован (`mobile/lib/features/projects/domain/membership.dart:79-94`), но `_expandFlag` дублируется в access_guard. | Команда, права представителя, переключение ролей |
| 2 | **AuthInterceptor добавляет JWT к presigned URL** | `AuthInterceptor` УЖЕ имеет `noAuth` флаг (`mobile/lib/core/network/interceptors/auth_interceptor.dart:16`), но репозитории его не передают. S3 отклоняет запросы с двойной авторизацией. | Загрузка фото, отображение, скачивание |
| 3 | **Недоделанные локальные правки** | В `documents_repository.dart` confirm потерял `fileKey` payload. В `tool_issuances_screen.dart` нет валидации до открытия sheet. | Документы, краш на инструменте |
| 4 | **Отсутствие invite UI и user-search** | Бекенд имеет `ProjectInvitation` модель, фильтрует `GET /projects` корректно по membership. Но в UI нет ни ввода кода, ни кнопки генерации, ни user-search. | Multi-team, добавление в команду |

---

## 2. Маппинг файлов

### Backend
| Назначение | Путь |
|---|---|
| Files (upload/download) | `backend/apps/api/src/modules/files/files-api.controller.ts` |
| Projects (CRUD, members) | `backend/apps/api/src/modules/projects/projects.controller.ts` |
| Invitations | `backend/apps/api/src/modules/projects/invitations.service.ts` |
| Stages FSM | `backend/apps/api/src/modules/stages/stages.controller.ts` |
| Methodology | `backend/apps/api/src/modules/methodology/methodology.controller.ts` |
| Tools + ToolIssuance | `backend/apps/api/src/modules/tools/tools.controller.ts` |
| Self-purchase | `backend/apps/api/src/modules/selfpurchases/selfpurchases.controller.ts` |
| Notifications | `backend/apps/api/src/modules/notifications/notifications.controller.ts` |
| RBAC | `backend/libs/rbac/src/rbac.types.ts`, `rbac.matrix.ts` |
| DB schema | `backend/prisma/schema.prisma` |
| Methodology seed | `backend/prisma/seeds/` (проверить наличие) |

### Mobile (правки)
| Назначение | Путь |
|---|---|
| RBAC client matrix | `mobile/lib/core/access/access_guard.dart` |
| Domain actions enum | `mobile/lib/core/access/domain_actions.dart` |
| Auth interceptor (УЖЕ есть noAuth) | `mobile/lib/core/network/interceptors/auth_interceptor.dart` |
| Dio factory | `mobile/lib/core/network/dio_factory.dart` |
| Deep-link router | `mobile/lib/core/routing/` (искать deep_link_router.dart или эквивалент) |
| Membership domain | `mobile/lib/features/projects/domain/membership.dart` |
| Documents repo | `mobile/lib/features/documents/data/documents_repository.dart` |
| Profile repo | `mobile/lib/features/profile/data/profile_repository.dart` |
| Steps repo | `mobile/lib/features/steps/data/steps_repository.dart` |
| Team screen | `mobile/lib/features/team/presentation/team_screen.dart` |
| Rep rights sheet | `mobile/lib/features/team/presentation/rep_rights_sheet.dart` |
| Rep rights screen (профиль) | `mobile/lib/features/profile/presentation/rep_rights_screen.dart` |
| Roles screen | `mobile/lib/features/profile/presentation/roles_screen.dart` |
| Tools UI | `mobile/lib/features/tools/presentation/{my_tools_screen,tool_issuances_screen}.dart` |
| Self-purchase UI | `mobile/lib/features/selfpurchase/presentation/selfpurchases_screen.dart` |
| Console screen | `mobile/lib/features/projects/presentation/console_screen.dart` |
| Projects screen | `mobile/lib/features/projects/presentation/projects_screen.dart` |
| Notifications | `mobile/lib/features/notifications/presentation/notifications_screen.dart` |
| Notif settings | `mobile/lib/features/profile/presentation/notification_settings_screen.dart` |
| Methodology screens | `mobile/lib/features/methodology/presentation/{methodology,article,methodology_search,methodology_section}_screen.dart` |
| Stages screens | `mobile/lib/features/stages/presentation/` |

### Mobile (новые файлы)
| Файл | Назначение |
|---|---|
| `mobile/lib/features/team/domain/representative_rights_l10n.dart` | Карта DomainAction → RU title+description |
| `mobile/lib/features/notifications/domain/notification_l10n.dart` | Карта NotificationKind → RU title+body |
| `mobile/lib/features/projects/presentation/join_by_code_screen.dart` | Ввод кода приглашения |
| `mobile/lib/features/team/presentation/generate_invite_code_sheet.dart` | Генерация кода для шаринга |

### Дизайн (только чтение, референс)
- `design/Кластер A — Профиль.html` — профиль, роли, права представителя.
- `design/Кластер B — Проекты.html` — команда, AddMemberFlow, экраны s-add-member, s-member-found, s-member-not-found.
- `design/Кластер C — Этапы.html` — 8 состояний этапа, pause sheet.
- `design/Кластер D — Согласования.html` — методичка.
- `design/Кластер E — Финансы.html` — инструменты, самозакуп.
- `design/Кластер F — Коммуникации.html` — документы, уведомления.

---

## 2A. Матрица иерархии отчётности и видимости

> **Это центральный раздел.** Все правки в P0.7, P1.4, P1.5 опираются именно на эту матрицу. Источник: ТЗ §1.4–1.5, §4, §6, §10.2, gaps §3.2–3.3, §4.1, расшифровки заказчика, дизайн `Кластер C/E/F`.

### 2A.1 Иерархия отчётности (кто перед кем)

```
                  ┌─────────────────────┐
                  │   ЗАКАЗЧИК (owner)  │
                  │  представитель  ←   │ (canApprove / canCreatePayments / ...)
                  └──────────▲──────────┘
                             │
        ┌────────────────────┼─────────────────────┐
        │ план этапа         │ согласование        │ приёмка этапа
        │ дедлайн            │ доп.работа          │
        │ аванс              │                     │
        ▼                    │                     │
                  ┌─────────────────────┐
                  │  БРИГАДИР (foreman) │
                  └──────────▲──────────┘
                             │
        ┌────────────────────┤
        │ выполнение шага    │ запрос самозакупа
        │ запрос приёмки     │ запрос материалов
        ▼                    │
                  ┌─────────────────────┐
                  │   МАСТЕР (master)   │
                  └─────────────────────┘
```

**Ключевые правила** (ТЗ + расшифровки):
- **Мастер не может закрыть свой шаг сам** — отправляет в `review` бригадиру.
- **Бригадир не может одобрить свой план сам** — отправляет на `approval` заказчику (scope=plan).
- **Заказчик не может согласовывать в обход бригадира** (gaps §3.3): если есть бригадир, `Approval.requestedById` всегда foreman, а не master напрямую.
- **Распределение аванса (foreman→master) делает только бригадир**, но `parentPaymentId` связывает с авансом customer→foreman, и заказчик должен видеть распределение для прозрачности.
- **Доп.работа (extra_work)** не попадает в бюджет до approve заказчиком (gaps §4.1).
- **Самозакуп — 2 отдельных flow**:
   - `master → foreman` (бригадир approve) — закрывает свой бюджет.
   - `foreman → customer` (заказчик approve) — попадает в `budget.materials.spent`.

### 2A.2 Матрица видимости ресурсов × роль (целевое состояние)

Легенда: ✅ полный доступ | 👁 только чтение | 🔒 только своё | ❌ нет доступа

| Ресурс | Заказчик (owner) | Представитель | Бригадир (foreman) | Мастер (master) |
|---|---|---|---|---|
| **Проект** (детали) | ✅ | 👁 | 👁 | 👁 |
| **Команда (список)** | 👁 кроме мастеров чужих бригадиров¹ | 👁 (по делегированию) | ✅ свои + кросс | 👁 свой бригадир + он сам¹ |
| **Этапы (список)** | ✅ | ✅ (если canEditStages) | 👁 свои этапы² | 👁 только назначенные² |
| **Этапы (изменение)** | ✅ | если canEditStages | ✅ свои | ❌ |
| **Шаги** | 👁 | 👁 | ✅ свои этапы | 👁 свои + мастеров своего этапа³ |
| **Фото шагов** | 👁 | 👁 | ✅ свои этапы | 👁 свои шаги (не чужие)⁴ |
| **План этапа** | ✅ approve | если canApprove | ✅ create/edit | ❌ |
| **Приёмка этапа** | ✅ accept | если canApprove | ✅ запрос | ❌ |
| **Бюджет проекта (общий)** | ✅ | если canSeeBudget | 👁 свои этапы | 👁 только свои этапы (limited)⁵ |
| **Платежи (advance customer→foreman)** | ✅ | если canSeeBudget | 👁 (получатель) | ❌ |
| **Платежи (distribution foreman→master)** | 👁 (для прозрачности)⁶ | если canSeeBudget | ✅ create | 🔒 только свои |
| **Самозакуп master→foreman** | ❌ (приватно бригады)⁷ | ❌ | ✅ approve | 🔒 свои |
| **Самозакуп foreman→customer** | ✅ approve | если canApprove | ✅ create | ❌ |
| **Материалы (запросы)** | ✅ approve | если canManageMaterials | ✅ create | 👁 (для работы)⁸ |
| **Документы — contract** | ✅ | 👁 | 👁 | ❌ |
| **Документы — act** | ✅ | 👁 | 👁 | ❌ |
| **Документы — estimate (смета)** | ✅ | если canSeeBudget | 👁 | ❌ |
| **Документы — warranty** | ✅ | 👁 | 👁 | 👁 |
| **Документы — photo** | 👁 | 👁 | 👁 | 👁 |
| **Документы — blueprint (чертёж)** | 👁 | 👁 | 👁 | 👁 |
| **Документы — other** | 👁 | 👁 | 👁 | 👁 |
| **Чат проекта** | ✅ | ✅ | ✅ | ✅ |
| **Чат этапа** | если visibleToCustomer⁹ | 👁 | ✅ | 👁 свои этапы |
| **Личный чат** | ✅ свой | ✅ свой | ✅ свой | ✅ свой |
| **Лента (feed)** | ✅ всё | ✅ | ✅ свои этапы | 👁 свои этапы (filtered) |
| **Согласования (list)** | ✅ | 👁 | ✅ | 🔒 в которых участвует |
| **Заметки personal** | 🔒 свои | 🔒 свои | 🔒 свои | 🔒 свои |
| **Заметки for_me** | 👁 свои | 👁 свои | 👁 свои | 👁 свои |
| **Заметки stage** | 👁 | 👁 | ✅ | 👁 |
| **Вопросы (questions)** | ✅ | ✅ | ✅ | ✅ свои этапы |
| **Инструменты (Мои)** | ❌ | ❌ | 🔒 свои | ❌ (только в момент выдачи) |
| **ToolIssuance** | ❌ | ❌ | ✅ создаёт/возвращает | 🔒 свои выдачи |
| **Уведомления** | 🔒 свои | 🔒 свои | 🔒 свои | 🔒 свои |
| **Профиль** | 🔒 свой | 🔒 свой | 🔒 свой | 🔒 свой |

**Сноски (важные пояснения):**

¹ **Команда — иерархическая**: ТЗ §1.4 явно: «заказчик не видит мастеров, нанятых бригадиром». Заказчик видит только своих прямых invitees (бригадира, представителя). Мастер видит только своего бригадира + остальных мастеров своего этапа.

² **Этапы**: бригадир видит этапы, где он в `stage.foremanIds`. Мастер — где он в `Membership.stageIds`.

³ **Шаги мастеров**: мастер видит чужие шаги в **своём** этапе для координации, но не может их редактировать.

⁴ **Фото шагов**: мастер видит фото только своих шагов (где он в `assigneeIds`). Заказчик/бригадир — все.

⁵ **Бюджет мастера**: мастер видит только: planned для своих этапов + свои авансы (полученные от бригадира) + свои самозакупы. **Не видит** общий бюджет проекта, чужие платежи.

⁶ **Прозрачность распределения**: заказчик ДОЛЖЕН видеть, как бригадир распределил его аванс на мастеров (только агрегаты: «Бригадир распределил 50 000 ₽: Иван 30к, Пётр 20к»). Это закрывает основное требование пользователя «понимать, на что ушёл аванс».

⁷ **master→foreman приватно**: бригадирские внутренние раздачи — деловая тайна бригады. Заказчик их не видит. Если что-то выйдет на бюджет проекта — это пойдёт через foreman→customer самозакуп или через distribution-payment.

⁸ **Материалы у мастера**: мастер видит смету, чтобы знать, что устанавливать/где. Не может редактировать.

⁹ **Toggle customer visibility**: бригадир может явно открыть чат этапа заказчику (`canToggleCustomerVisibility`). По умолчанию — закрыт.

### 2A.3 Уведомления — кому отправлять

| Событие | Кому пуш |
|---|---|
| `payment.created` (advance customer→foreman) | Получателю (foreman) + автору (customer) |
| `payment.created` (distribution foreman→master) | Получателю (master) + автору (foreman) + customer (для прозрачности, NORMAL) |
| `payment.confirmed` | Автору платежа + customer |
| `payment.disputed` | Контрагенту платежа + customer (если involves customer) |
| `step.completed` | Бригадиру этапа |
| `stage.review_requested` | Заказчику (+ представителю с canApprove) |
| `stage.approved` (приёмка) | Бригадиру + всем мастерам этапа |
| `stage.rejected` (приёмка) | Бригадиру + мастерам этапа |
| `stage.overdue` | Бригадиру + customer + представителю |
| `stage.deadline_exceeds_project` | Бригадиру + customer |
| `approval.requested` | Адресату (всегда заказчик/представитель) |
| `approval.approved/rejected` | Запросителю (бригадиру) |
| `material.request_created` | Адресату (foreman или customer по recipient) |
| `material.delivered` | Заказчику + бригадиру |
| `material.disputed` | Customer (резолвер) + автор |
| `selfpurchase.created (master→foreman)` | Бригадир |
| `selfpurchase.approved/rejected (master→foreman)` | Мастер |
| `selfpurchase.created (foreman→customer)` | Заказчик + представитель с canApprove |
| `selfpurchase.approved (foreman→customer)` | Бригадир + лента всем участникам |
| `tool.issued` | Получателю мастеру |
| `chat.message_new` | Всем участникам чата кроме отправителя |
| `note.created_for_me` | Адресату |
| `question.asked` | Назначенному отвечающему |
| `export.completed/failed` | Запросителю |
| `membership.added` | Добавленному + всем активным участникам (NORMAL) |

---

## 3. S0 — Системные предусловия (ВПЕРВУЮ)

### S0.1 Унификация RBAC-парсинга

**Status:** ☐ todo

**🎯 Цель**: единый источник истины для парсинга `representativeRights` (Map булевых флагов или массив строк) и единый способ проверки прав в UI.

**📍 Где**
- ТЗ: §1.5 (RBAC матрица 4×16+).
- Backend: `backend/libs/rbac/src/rbac.types.ts:97-106` — 8 булевых флагов `RepresentativeRights`.
- Backend: `backend/libs/rbac/src/rbac.matrix.ts` — маппинг флаг → список actions.
- Mobile: `mobile/lib/features/projects/domain/membership.dart:79-94` (`_parseRights` уже принимает оба формата).
- Mobile: `mobile/lib/core/access/access_guard.dart:161-201` (`_representativeFlagToActions` карта).

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `grep -rn "_expandFlag\|_representativeFlagToActions\|representativeRights" mobile/lib/features/` — посчитать дубликаты.
- [ ] Прочитать `git diff mobile/lib/features/projects/domain/membership.dart` — понять текущее состояние.
- [ ] Сверить маппинг `_representativeFlagToActions` (mobile access_guard.dart:161-201) с `rbac.matrix.ts` (backend) — должны совпадать ровно.

**🛠 Steps**
1. Прочитать `mobile/lib/core/access/access_guard.dart` целиком — там УЖЕ есть `_expandFlag` (line 210), `representativeRightsProvider` (line 132), `canInProjectProvider` (line 218). Карта 8 флагов на line 161-201.
2. `grep -rn "representativeRights\|RepresentativeRights" mobile/lib/features/` — найти все экраны, где эта логика дублируется.
3. Если найдены дубли `_expandFlag` или прямые проверки `rights.contains('canApprove')` в presentation/ — заменить на `ref.watch(canInProjectProvider((action: DomainAction.X, projectId: id)))`.
4. Сверить карту `_representativeFlagToActions` (access_guard.dart:161) с `backend/libs/rbac/src/rbac.matrix.ts`. Если расходится — обновить mobile-версию (бекенд — источник истины).

**🧪 Verify**
- [ ] `grep -rn "_expandFlag\|canApprove\s*==" mobile/lib/features/` — только в access_guard.dart, нигде в presentation/.
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] `cd mobile && flutter test test/features/projects/` — passing.
- [ ] Smoke: открыть Команда (после P0.3) → клик «Права представителя» → каждое право должно отображаться корректно (сейчас или будет — после P1.1).

**📝 Notes**
- `Membership.parse(...)` (membership.dart:60-76) — уже корректно парсит оба формата.
- НЕ удалять `MembershipRights` side-channel хранилище (membership.dart:96-110) — оно работающий обходной путь поверх freezed.

---

### S0.2 Использование `noAuth` для presigned URL

**Status:** ☐ todo

**🎯 Цель**: запросы к MinIO presigned URL (PUT upload, GET download/image) не должны нести `Authorization: Bearer` — это вызывает 403 от S3.

**📍 Где**
- Mobile interceptor: `mobile/lib/core/network/interceptors/auth_interceptor.dart:16` — флаг УЖЕ ЕСТЬ.
- Mobile репозитории: `documents_repository.dart`, `profile_repository.dart`, `steps_repository.dart` — нужны правки.

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `Read mobile/lib/core/network/interceptors/auth_interceptor.dart` — подтвердить, что строка 16 содержит `if (options.extra['noAuth'] == true)`.
- [ ] `grep -n "presign\|presigned\|PUT\|uploadUrl" mobile/lib/features/documents/data/documents_repository.dart` — найти PUT-вызовы.
- [ ] То же для `profile_repository.dart`, `steps_repository.dart`.

**🛠 Steps**

Для каждого PUT-запроса на presigned URL:

```dart
// БЫЛО:
await _dio.put(uploadUrl, data: bytes, options: Options(headers: {'Content-Type': mime}));

// СТАЛО:
await _dio.put(
  uploadUrl,
  data: bytes,
  options: Options(
    headers: {'Content-Type': mime},
    extra: {'noAuth': true},  // <-- добавить
  ),
);
```

Для GET presigned URL (если используется через dio):

```dart
options: Options(extra: {'noAuth': true}),
```

Для виджетов с картинками (`cached_network_image` и т.п.):
- Не передавать `httpHeaders` с авторизацией для presigned URL (там подпись уже в query string).
- Если используется собственный image-loader через dio — также добавить `noAuth: true`.

**🧪 Verify**
- [ ] `grep -rn "presign\|uploadUrl\|downloadUrl" mobile/lib/features/` — все PUT/GET-вызовы имеют `extra: {'noAuth': true}`.
- [ ] Smoke (после P0.1): загрузить JPG в Документы → видно превью без 403/AccessDenied.
- [ ] Smoke: открыть `Профиль → Изменить профиль → загрузить аватар` → видно после загрузки.

**📝 Notes**
- НЕ удалять обычный auth для не-S3 запросов (это сломает всё API).
- Презайн-URL уже несут подпись AWS V4 в query string — `Authorization: Bearer` ЛОМАЕТ их.

---

## 4. P0 — Критичные баги

### P0.1 Документы / фото — upload, download, отображение

**Status:** ☐ todo

**🎯 Цель**: пользователь может загрузить файл (фото/PDF/документ), увидеть превью, открыть/скачать его.

**📍 Где**
- ТЗ: §3.5 (документы), §6.4 (storage).
- Дизайн: `design/Кластер F — Коммуникации.html` (документы), `design/Кластер C — Этапы.html` (фото шага).
- Backend: `backend/apps/api/src/modules/files/files-api.controller.ts`.
- Backend: `backend/apps/api/src/modules/documents/` (если есть, искать).
- Mobile: `mobile/lib/features/documents/data/documents_repository.dart`.
- Mobile: `mobile/lib/features/profile/data/profile_repository.dart`.
- Mobile: `mobile/lib/features/steps/data/steps_repository.dart`.

**🔗 Зависит от**: S0.2.

**✅ Pre-conditions**
- [ ] `git diff mobile/lib/features/documents/data/documents_repository.dart` — понять, что было изменено и потеряно.
- [ ] `Read backend/apps/api/src/modules/files/files-api.controller.ts` — есть ли `download` endpoint? Какой TTL у presign?
- [ ] Проверить, что MinIO bucket работает: `docker compose ps` (если локально).

**🛠 Steps**

**Backend (если нет download endpoint):**
1. В `files-api.controller.ts` добавить:
   ```typescript
   @Get(':fileKey/download')
   @UseGuards(JwtAuthGuard)
   async downloadPresign(@Param('fileKey') fileKey: string, @Req() req) {
     // Проверить ownership/membership через FilesService
     const url = await this.filesService.presignGet(fileKey, { ttl: 300 });
     return { url, expiresAt: new Date(Date.now() + 300_000).toISOString() };
   }
   ```
2. `FilesService.presignGet` — реализовать через MinIO SDK.
3. Authz: убедиться, что fileKey доступен только тому, кто видит соответствующий ресурс (Document/StepPhoto/Avatar) — связать с его ProjectMembership.

**Mobile (документы):**
1. `Read mobile/lib/features/documents/data/documents_repository.dart` целиком.
2. Найти confirm-метод (после upload presigned PUT приходит подтверждение в API). Восстановить `fileKey` в payload, если он был потерян:
   ```dart
   await _dio.post(
     '/api/documents/$documentId/confirm',
     data: {'fileKey': fileKey, 'mime': mime, 'size': size},  // <-- fileKey ДОЛЖЕН быть тут
   );
   ```
3. Все PUT на presigned URL — добавить `extra: {'noAuth': true}` (S0.2).
4. В виджете отображения документа (`document_detail_screen.dart` или эквивалент): сначала `GET /api/documents/:id/download` → получить URL → показать через `cached_network_image` (для фото) или `open_filex` (для PDF/DOCX).

**Mobile (фото шага):**
1. То же для `steps_repository.dart`. Photo upload flow в S12 уже реализован — проверить, что `extra: {'noAuth': true}` есть на PUT-presigned.

**Mobile (аватар):**
1. То же для `profile_repository.dart`.

**🧪 Verify**
- [ ] `cd backend && pnpm test files` — passing.
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: войти как заказчик → проект → документы → загрузить JPG → видно превью.
- [ ] Smoke 2: тап по превью → видно полноэкранно (или в open_filex для PDF).
- [ ] Smoke 3: войти на другом устройстве/выйти-войти → фото всё ещё отображается (presigned не expired до клика).
- [ ] Smoke 4: загрузить PDF → нажать «открыть» → файл открывается во внешнем app.

**📝 Notes**
- Презайн TTL = 5 минут. Если пользователь долго смотрит экран до клика — может expire. Решение: при клике на «открыть» — заново запрашивать presigned URL (не кешировать дольше 4 минут).
- EXIF-clearing — на бекенде (`exifCleared` в schema). Mobile только compress 1920px/80%.

---

### P0.2 Tools — краш при добавлении инструмента

**Status:** ☐ todo

**🎯 Цель**: пользователь (бригадир) может добавить инструмент в «Мои инструменты» без краша приложения.

**📍 Где**
- ТЗ: §4.5 (инструменты).
- Дизайн: `design/Кластер E — Финансы.html` (s-profile-tools, e-my-tools-add).
- Backend: `backend/apps/api/src/modules/tools/tools.controller.ts`.
- Mobile: `mobile/lib/features/tools/presentation/my_tools_screen.dart` (где FAB/кнопка add).
- Mobile: `mobile/lib/features/tools/presentation/tool_issuances_screen.dart` (модифицирован — diff содержит частичную форму).

**🔗 Зависит от**: S0.2 (если фото инструмента грузится через presigned URL).

**✅ Pre-conditions**
- [ ] `git diff mobile/lib/features/tools/presentation/tool_issuances_screen.dart` — что изменилось.
- [ ] `Read mobile/lib/features/tools/presentation/my_tools_screen.dart` — где именно открывается add-форма.
- [ ] `grep -n "ImagePicker\|image_picker\|pickImage" mobile/lib/features/tools/` — есть ли image-picker в add-flow?
- [ ] `Read backend/apps/api/src/modules/tools/tools.controller.ts` — какие поля required в `CreateToolDto`.

**🛠 Steps**

**Mobile (защита от краша):**
1. В файле, где открывается add-tool-форма: завернуть весь flow в try/catch с показом `AppErrorState` или `ScaffoldMessenger.showSnackBar` вместо полного краша.
2. Если используется `image_picker` для фото инструмента:
   ```dart
   try {
     final picked = await picker.pickImage(source: ImageSource.gallery);
     if (picked == null) return;
     // ...
   } on PlatformException catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось открыть галерею: ${e.message}')));
     return;
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка при выборе фото')));
     return;
   }
   ```
3. Перед вызовом `POST /me/tools` — валидация полей формы:
   - `name` не пустое.
   - `totalQty > 0`.
   - `unit` не пустое (default 'шт').
   - Если фото опционально — пропускать `photoKey` если не выбрано.
4. В sheet-форме (`tool_issuances_screen.dart` lines 84-197 по diff): добавить early return и показ ошибки если `toolId == null || toUserId == null || qty == null`:
   ```dart
   if (toolId == null) {
     showSnackBar('Выберите инструмент');
     return;
   }
   if (toUserId == null) {
     showSnackBar('Выберите получателя');
     return;
   }
   ```

**Backend:**
1. Подтвердить, что `CreateToolDto` имеет class-validator декораторы (`@IsString()`, `@IsInt()`, `@Min(1)`, `@IsOptional()`).
2. Если `photoKey` опционален — `@IsOptional() @IsString() photoKey?`.
3. Возвращать `400 Bad Request` (не 500) при невалидных данных.

**🧪 Verify**
- [ ] `cd backend && pnpm test tools` — passing.
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: войти как бригадир → Профиль → Мои инструменты → FAB → ввести только название и кол-во → сохранить → НЕ КРАШИТ, инструмент появляется в списке.
- [ ] Smoke 2: тот же flow, но добавить фото → сохранить → нет краша, фото отображается.
- [ ] Smoke 3: тот же flow, но не вводить ничего → нажать сохранить → видна валидация «Введите название».
- [ ] Smoke 4: выдать инструмент мастеру → подтверждение → возврат → подтверждение возврата (FSM 4 состояния).

**📝 Notes**
- Если краш на iOS из-за `NSPhotoLibraryUsageDescription` — проверить `mobile/ios/Runner/Info.plist`.
- Если краш на Android из-за permissions — проверить `mobile/android/app/src/main/AndroidManifest.xml` для `READ_MEDIA_IMAGES`.

---

### P0.3 Команда — ошибка при открытии

**Status:** ☐ todo

**🎯 Цель**: открыть «Команда» в проекте — видно список участников + их роли + блок «Права представителя» (если роль representative).

**📍 Где**
- ТЗ: §1.5 (команда), §6.1 (Membership).
- Дизайн: `design/Кластер B — Проекты.html` (s-team).
- Backend: `backend/apps/api/src/modules/projects/projects.controller.ts:108-149` (members).
- Mobile: `mobile/lib/features/team/presentation/team_screen.dart` (модифицирован).

**🔗 Зависит от**: S0.1.

**✅ Pre-conditions**
- [ ] `git diff mobile/lib/features/team/presentation/team_screen.dart` — что изменилось.
- [ ] `Read mobile/lib/features/team/data/team_repository.dart` — какой endpoint зовётся.
- [ ] Реальный сетевой ответ: `curl -H "Authorization: Bearer <jwt>" http://localhost:3000/api/projects/<id>/members | jq` — структура responses.

**🛠 Steps**
1. Прочитать `team_screen.dart` целиком.
2. Найти точку, где парсится Membership (вероятно через `Membership.parse(json)` из data layer). Подтвердить, что используется `Membership.parse` (membership.dart:60-76) — она УЖЕ обрабатывает оба формата прав.
3. Если `team_screen.dart` напрямую обращается к `representativeRights` как к `Map` — убрать. Использовать extension `member.representativeRights` (List<String>) и при необходимости `_expandFlag`.
4. Если есть provider `teamControllerProvider` и он падает с FormatException — добавить `error: (err, _) => AppErrorState(...)` в `.when()`.
5. Проверить, что endpoint `GET /api/projects/:id/members` доступен для всех ролей (а не только owner) — ТЗ §1.5: команду видят все участники.

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] `cd mobile && flutter test test/features/team/` — passing.
- [ ] Smoke 1: заказчик открывает Команда → видно себя + участников.
- [ ] Smoke 2: бригадир открывает Команда → видно весь состав.
- [ ] Smoke 3: представитель открывает Команда → видно состав + блок «Мои права» (даже если P1.1 ещё не сделан, рендер не должен крашить).
- [ ] Smoke 4: представитель → клик на «Права» → не крашит (P1.1 даст человеческий текст).

**📝 Notes**
- Если бекенд возвращает `permissions: null` для не-представителя — в `_parseRights(null)` уже возвращается `const []`.
- В `members.service.ts` подтвердить, что выборка включает `user` join (firstName, lastName, phone, avatarUrl) — иначе UI покажет "Unknown".

---

### P0.4 Методичка — ошибки при открытии

**Status:** ☐ todo

**🎯 Цель**: открыть «Методичка» → видны секции → клик → видна статья. Поиск работает.

**📍 Где**
- ТЗ: §3.3 (методичка, FTS).
- Дизайн: `design/Кластер D — Согласования.html` (методичка).
- Backend: `backend/apps/api/src/modules/methodology/methodology.controller.ts`.
- Backend: `backend/prisma/seeds/` (искать methodology seed).
- Mobile: `mobile/lib/features/methodology/presentation/methodology_screen.dart`, `article_screen.dart`, `methodology_search_screen.dart`, `methodology_section_screen.dart`.

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `curl http://localhost:3000/api/methodology/sections | jq` — есть ли секции в БД?
- [ ] `ls backend/prisma/seeds/` — есть ли seed для методички?
- [ ] `grep -rn "methodology" backend/prisma/` — где seed.

**🛠 Steps**

**Backend:**
1. Если БД пуста (нет секций) — добавить базовый seed:
   - 5 секций: «Подготовка», «Демонтаж», «Электрика», «Сантехника», «Отделка».
   - В каждой 2-3 статьи (title + body в Markdown + 1-2 referencePhotos через MinIO).
   - На основе `design/Кластер D` — какие именно темы заказчик хочет.
2. Запустить seed: `cd backend && pnpm prisma db seed` (или конкретная команда).

**Mobile:**
1. `Read mobile/lib/features/methodology/presentation/methodology_screen.dart`.
2. В `.when()` для async-провайдера добавить:
   - `loading: () => AppLoadingState()`,
   - `error: (e, _) => AppErrorState(message: 'Не удалось загрузить методичку', onRetry: ...)`,
   - `data: (sections) => sections.isEmpty ? AppEmptyState(...) : ListView(...)`.
3. То же для `article_screen.dart`, `methodology_search_screen.dart`.

**🧪 Verify**
- [ ] `cd backend && pnpm test methodology` — passing.
- [ ] `cd mobile && flutter test test/features/methodology/` — passing (если тесты есть).
- [ ] Smoke 1: открыть Методичка → видно ≥ 1 секции.
- [ ] Smoke 2: клик на секцию → видны статьи.
- [ ] Smoke 3: клик на статью → видно содержимое (Markdown отрендерен).
- [ ] Smoke 4: поиск → ввод запроса (например, «гипсокартон») → видны релевантные результаты.

**📝 Notes**
- ETag-кеш реализован на бекенде (если есть). Можно не кешировать на фронте до production.
- FTS требует `to_tsvector('russian', ...)` индекс в PostgreSQL — должен быть в миграции.

---

### P0.5 Переключение ролей — не работает

**Status:** ☐ todo

**🎯 Цель**: пользователь меняет активную роль в «Профиль → Роли» → UI всех экранов перерисовывается под новую роль (видимость пунктов меню, права, фильтры) без рестарта приложения.

**📍 Где**
- ТЗ: §1.5 (multi-role users).
- Дизайн: `design/Кластер A — Профиль.html` (s-roles, s-role-switched).
- Backend: `PUT /api/me/active-role` (`backend/apps/api/src/modules/users/users.controller.ts`).
- Mobile: `mobile/lib/core/access/access_guard.dart:116` (`activeRoleProvider`).
- Mobile: `mobile/lib/features/profile/presentation/roles_screen.dart`.
- Mobile: `mobile/lib/features/auth/application/auth_controller.dart` (источник activeRole).

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `Read mobile/lib/core/access/access_guard.dart` строки 116-118.
- [ ] `Read mobile/lib/features/profile/presentation/roles_screen.dart` — найти кнопку switch.
- [ ] `Read mobile/lib/features/auth/application/auth_controller.dart` — какой тип у `authControllerProvider` (Provider или StateNotifier?), как обновляется `activeRole`.

**🛠 Steps**

**Сценарий A: `authControllerProvider` уже `StateNotifierProvider` (или AsyncNotifier).**
1. В `roles_screen.dart` после успешного API-вызова:
   ```dart
   await ref.read(authControllerProvider.notifier).setActiveRole(newRole);
   ref.invalidate(activeRoleProvider);  // явная инвалидация на всякий случай
   if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Активная роль: ${newRole.displayName}')),
     );
   }
   ```
2. Убедиться, что `authController` обновляет внутреннее состояние synchronously после API.

**Сценарий B: `authControllerProvider` возвращает immutable объект (Provider, не Notifier).**
1. Переделать на `StateNotifierProvider<AuthController, AuthState>`.
2. В `AuthState` хранить `activeRole`.
3. `AuthController.setActiveRole(role)` → `state = state.copyWith(activeRole: role)`.

**Общее:**
- В `console_screen.dart`, `projects_screen.dart` и других экранах с условной видимостью пунктов: убедиться, что они слушают `activeRoleProvider` через `ref.watch`, а не читают один раз через `ref.read`.

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] `cd mobile && flutter test test/features/auth/` — passing.
- [ ] Smoke 1: иметь юзера с 2 ролями (например, customer + foreman) → выбрать другую → видно toast → меню в console_screen перерисовалось (другие пункты).
- [ ] Smoke 2: переключиться обратно → меню вернулось к первому варианту.
- [ ] Smoke 3: убить и заново открыть приложение → роль сохранилась (бекенд хранит User.activeRole).

**📝 Notes**
- НЕ зависит от refresh JWT. Active role хранится в User.activeRole в БД, обновляется через `PUT /me/active-role`.
- Если в JWT есть поле `activeRole` — после смены нужен либо новый refresh, либо клиент игнорирует JWT-roles и использует серверный `/me`.

---

### P0.6 Самозакуп — недоступен/непонятен

**Status:** ☐ todo

**🎯 Цель**: пункт «Самозакуп» виден только тем ролям, которым он реально доступен (бригадир, мастер, admin). Не видим у заказчика. При клике никогда не показывает «Раздел недоступен» — раз пункт виден, значит должен работать.

**📍 Где**
- ТЗ: §4.4 (selfpurchase).
- Дизайн: `design/Кластер E — Финансы.html` (e-selfpurchase, e-selfpurchase-pending).
- Backend: `backend/apps/api/src/modules/selfpurchases/selfpurchases.controller.ts`.
- Mobile: `mobile/lib/features/projects/presentation/console_screen.dart` (модифицирован — diff показывает `canSelfPurchase` логику).
- Mobile: `mobile/lib/features/selfpurchase/presentation/selfpurchases_screen.dart` (модифицирован).

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `git diff mobile/lib/features/projects/presentation/console_screen.dart` — посмотреть `canSelfPurchase` секцию (строки 362-386 по аудиту).
- [ ] `git diff mobile/lib/features/selfpurchase/presentation/selfpurchases_screen.dart` — посмотреть обработку 403.

**🛠 Steps**
1. В `console_screen.dart` подтвердить логику фильтрации пункта меню:
   ```dart
   final canSelfPurchase = role == SystemRole.contractor
       || role == SystemRole.master
       || role == SystemRole.admin
       || ref.watch(canInProjectProvider(
            (action: DomainAction.selfPurchaseCreate, projectId: projectId)
          ));
   if (canSelfPurchase) ...[
     ConsoleTile(title: 'Самозакуп', icon: Icons.shopping_bag, onTap: ...),
   ],
   ```
2. В `selfpurchases_screen.dart` УБРАТЬ `AppEmptyState(title: 'Раздел недоступен')` для случая 403:
   - 403 не должен происходить, если пункт меню фильтруется правильно.
   - Если всё же случился (deeplink, race) — показать `AppErrorState` с message и кнопкой «Вернуться» (Navigator.pop).
3. Бекенд authz: подтвердить, что заказчик получает 403 на `POST /projects/:id/selfpurchases` (он не должен создавать).

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: войти как заказчик → Console → пункта «Самозакуп» НЕТ.
- [ ] Smoke 2: войти как бригадир → Console → пункт виден → клик → открывается список.
- [ ] Smoke 3: бригадир создаёт самозакуп → видит в pending → одобряет → попадает в бюджет (P0/P1 не зависят, проверяется в smoke).
- [ ] Smoke 4: войти как мастер → пункт виден → может создать (на бригадира).

**📝 Notes**
- Иерархия addressee: foreman → owner проекта; master → бригадир этапа.
- `Idempotency-Key` уже есть на бекенде.

---

### P0.7 Backend — закрыть 5 дыр видимости (СРОЧНО)

**Status:** ☐ todo

**🎯 Цель**: ни одна роль не видит ресурсов, которые ей не положены по матрице 2A.2. Сейчас 5 эндпоинтов отдают данные, нарушающие приватность.

**📍 Где**
- ТЗ: §1.4–1.5, §6, §10.2, gaps §3–4.
- Backend: `apps/api/src/modules/payments/`, `documents/`, `feed/`, `selfpurchases/`, `step-photos/`.

**🔗 Зависит от**: нет (но критично — до релиза).

**✅ Pre-conditions**
- [ ] Прочитать матрицу 2A.2 в этом файле.
- [ ] Открыть `backend/libs/rbac/src/access.guard.ts` — есть ли поля `assignedStageIds`, `membershipRole`, `userId` в AccessContext.
- [ ] `grep -rn "@RequireAccess" backend/apps/api/src/modules/payments/payments.controller.ts`.

**🛠 Steps**

#### P0.7.a — Payments: `GET /payments/:id` без guard'а

Файл: `backend/apps/api/src/modules/payments/payments.controller.ts:132-135` (приблизительно).

```typescript
// БЫЛО:
@Get('payments/:id')
async get(@Param('id') id: string) {
  return this.payments.get(id);
}

// СТАЛО:
@Get('payments/:id')
@UseGuards(JwtAuthGuard)
@RequireAccess({ action: 'finance.budget.view', loadResource: 'payment' })
async get(@Param('id') id: string, @CurrentUser() user) {
  return this.payments.get(id, { viewerId: user.id, viewerRole: user.activeRole });
}
```

В `PaymentsService.get(id, viewer)` добавить проверку: payment виден если viewer = fromUserId, toUserId, projectOwnerId, или representative.canSeeBudget. Иначе — `throw new ForbiddenException()`.

#### P0.7.b — Payments: list без фильтра по роли

Файл: `payments.service.ts:361-376`.

```typescript
async listForProject(
  projectId: string,
  viewer: { userId: string; membershipRole: MembershipRole; assignedStageIds?: string[]; isOwner: boolean; canSeeBudget?: boolean },
  filter?: { status?: PaymentStatus; kind?: PaymentKind },
) {
  const where: Prisma.PaymentWhereInput = { projectId };
  if (filter?.status) where.status = filter.status;
  if (filter?.kind) where.kind = filter.kind;

  // Видимость по ролям (см. матрицу §2A.2):
  if (viewer.isOwner || viewer.canSeeBudget) {
    // owner / representative.canSeeBudget видят все платежи
  } else if (viewer.membershipRole === 'foreman') {
    // foreman видит свои входящие (advance) + свои исходящие (distribution children)
    where.OR = [
      { toUserId: viewer.userId },
      { fromUserId: viewer.userId },
    ];
  } else if (viewer.membershipRole === 'master') {
    // master видит ТОЛЬКО свои платежи
    where.OR = [{ toUserId: viewer.userId }, { fromUserId: viewer.userId }];
  } else {
    return [];
  }

  const rows = await this.prisma.payment.findMany({ where, orderBy: { createdAt: 'desc' } });
  return rows.map((p) => this.serialize(p));
}
```

В контроллере подгружать viewer-контекст из `Membership` + `RepresentativeRights`.

#### P0.7.c — Documents: list без фильтра по category × role

Файл: `documents.service.ts:93-113`.

```typescript
const FORBIDDEN_FOR_MASTER: DocumentCategory[] = ['contract', 'act', 'estimate'];

async list(
  projectId: string,
  viewer: { userId: string; membershipRole: MembershipRole; isOwner: boolean; canSeeBudget?: boolean },
  filters: { stageId?: string; stepId?: string; category?: DocumentCategory } = {},
) {
  const where: Prisma.DocumentWhereInput = {
    projectId,
    deletedAt: null,
    ...(filters.stageId ? { stageId: filters.stageId } : {}),
    ...(filters.stepId ? { stepId: filters.stepId } : {}),
    ...(filters.category ? { category: filters.category } : {}),
  };

  // Master не видит contract/act/estimate
  if (viewer.membershipRole === 'master') {
    where.category = { notIn: FORBIDDEN_FOR_MASTER };
  }
  // Representative без canSeeBudget — не видит estimate
  if (viewer.membershipRole === 'representative' && !viewer.canSeeBudget) {
    const blocked: DocumentCategory[] = ['estimate'];
    where.category = where.category
      ? { ...where.category as object, notIn: [...((where.category as any).notIn ?? []), ...blocked] }
      : { notIn: blocked };
  }

  return this.prisma.document.findMany({ where, orderBy: { createdAt: 'desc' } });
}
```

В `documents.service.ts:get(id)` — аналогичная проверка перед возвратом.

#### P0.7.d — Feed: master видит чужие этапы

Файл: `feed.service.ts:47-53`.

Шаг 1 — миграция Prisma: добавить `stageId String?` в `FeedEvent` (если ещё нет). Бэкфилл: для существующих событий стадий проставить через job или вручную.

Шаг 2 — фильтрация:

```typescript
async listForProject(
  projectId: string,
  viewer: { userId: string; membershipRole: MembershipRole; assignedStageIds: string[]; isOwner: boolean; canSeeBudget?: boolean },
  limit = 50,
  cursor?: string,
) {
  const where: Prisma.FeedEventWhereInput = { projectId };

  if (!(viewer.isOwner || viewer.membershipRole === 'representative')) {
    if (viewer.membershipRole === 'master') {
      where.OR = [
        { stageId: null },                                        // проектные события (создание проекта, общая лента)
        { stageId: { in: viewer.assignedStageIds } },             // только свои этапы
      ];
    }
    // foreman: видит свои этапы (по stage.foremanIds) — также через OR + stageId, либо отдельная логика
  }

  // Скрыть финансовые события приватного бригадира от мастера:
  if (viewer.membershipRole === 'master') {
    where.AND = [
      { kind: { notIn: ['payment_distribution_internal', 'selfpurchase_master_to_foreman'] } as any },
    ];
  }

  return this.prisma.feedEvent.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: limit,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
  });
}
```

#### P0.7.e — SelfPurchases: master видит чужие, customer видит master→foreman

Файл: `selfpurchases.service.ts:182-194`.

```typescript
async listForProject(
  projectId: string,
  viewer: { userId: string; membershipRole: MembershipRole; isOwner: boolean; canApprove?: boolean },
  filter?: { status?: SelfPurchaseStatus; byUserId?: string },
) {
  const where: Prisma.SelfPurchaseWhereInput = { projectId };
  if (filter?.status) where.status = filter.status;

  if (viewer.isOwner || (viewer.membershipRole === 'representative' && viewer.canApprove)) {
    // Заказчик / canApprove-представитель видят ТОЛЬКО foreman→customer
    where.byRole = 'foreman';
  } else if (viewer.membershipRole === 'foreman') {
    // Бригадир видит: свои (foreman→customer) + входящие master→foreman
    where.OR = [
      { byUserId: viewer.userId },
      { addresseeId: viewer.userId },
    ];
  } else if (viewer.membershipRole === 'master') {
    where.byUserId = viewer.userId;
  } else {
    return [];
  }

  if (filter?.byUserId) where.byUserId = filter.byUserId;

  const rows = await this.prisma.selfPurchase.findMany({ where, orderBy: { createdAt: 'desc' } });
  return rows.map((r) => this.serialize(r));
}
```

#### P0.7.f — StepPhotos: мастер видит чужие шаги в этапе

Файл: `step-photos.service.ts` (точное имя — найти).

```typescript
async listForStep(
  stepId: string,
  viewer: { userId: string; membershipRole: MembershipRole; isOwner: boolean },
) {
  // Все, кроме мастера, видят все фото шага.
  if (viewer.membershipRole !== 'master') {
    return this.prisma.stepPhoto.findMany({ where: { stepId }, orderBy: { createdAt: 'desc' } });
  }
  // Мастер видит только если он assignee этого шага.
  const step = await this.prisma.step.findUnique({ where: { id: stepId }, select: { assigneeIds: true } });
  if (!step || !step.assigneeIds.includes(viewer.userId)) return [];
  return this.prisma.stepPhoto.findMany({ where: { stepId }, orderBy: { createdAt: 'desc' } });
}
```

**🧪 Verify**

Тесты добавить в:
- `payments.service.spec.ts` — 4 кейса (owner/foreman/master/outsider × visibility).
- `documents.service.spec.ts` — master не получает contract/act/estimate.
- `feed.service.spec.ts` — master не видит чужие этапы.
- `selfpurchases.service.spec.ts` — customer не видит master→foreman.
- `step-photos.service.spec.ts` — master не видит чужой шаг.

E2E:
```bash
cd backend && pnpm test
cd backend && pnpm test:e2e
```

Curl smoke:
```bash
# 1. Под мастером запросить чужой платёж по ID — должно быть 403.
curl -H "Authorization: Bearer $MASTER_JWT" http://localhost:3000/api/payments/<advance-id>
# Expected: 403 Forbidden

# 2. Под мастером запросить документ category=contract — не должно быть в списке.
curl -H "Authorization: Bearer $MASTER_JWT" http://localhost:3000/api/projects/<pid>/documents?category=contract
# Expected: []

# 3. Под мастером запросить feed — события чужого этапа отсутствуют.
curl -H "Authorization: Bearer $MASTER_JWT" http://localhost:3000/api/projects/<pid>/feed | jq '[.[] | select(.stageId != null)]'
# Expected: только события своих этапов

# 4. Под заказчиком запросить selfpurchases — без master→foreman.
curl -H "Authorization: Bearer $OWNER_JWT" http://localhost:3000/api/projects/<pid>/selfpurchases | jq '.[] | .byRole'
# Expected: только "foreman" в результатах
```

**📝 Notes**
- В `AccessGuard` (`backend/libs/rbac/src/access.guard.ts`) убедиться, что все нужные поля контекста (`assignedStageIds`, `membershipRole`, `canSeeBudget`, `canApprove`, `isOwner`) гидрируются из БД при загрузке контекста проекта/платежа/документа.
- Для feed-события `payment_distribution`: создать **2 события** — приватное `payment_distribution_internal` (видит только foreman+master) и публичное `payment_distributed_public` с агрегатом для customer (см. P1.5).

---

## 5. P1 — UX и тексты на русском

### P1.1 Карта DomainAction → RU (права представителя)

**Status:** ☐ todo

**🎯 Цель**: на экранах прав представителя (rep_rights_sheet, rep_rights_screen) пользователь видит человекочитаемые названия прав + пояснения, а не технические ключи `approval.decide`.

**📍 Где**
- ТЗ: §1.5 (RBAC).
- Дизайн: `design/Кластер B — Проекты.html` (s-rep-rights).
- Дизайн: `design/Кластер A — Профиль.html` (s-rep-rights в профиле представителя).
- Backend: `backend/libs/rbac/src/rbac.types.ts:7-74` (DOMAIN_ACTIONS).
- Backend: `backend/libs/rbac/src/rbac.types.ts:97-106` (RepresentativeRights — 8 флагов).
- Mobile: `mobile/lib/core/access/domain_actions.dart` (enum DomainAction).
- Mobile: `mobile/lib/features/team/presentation/rep_rights_sheet.dart` (где рендер прав).
- Mobile: `mobile/lib/features/profile/presentation/rep_rights_screen.dart`.

**🔗 Зависит от**: нет (но удобнее после S0.1).

**✅ Pre-conditions**
- [ ] `Read mobile/lib/core/access/domain_actions.dart` — список всех DomainAction enum значений.
- [ ] `Read mobile/lib/features/team/presentation/rep_rights_sheet.dart` — найти место рендера (по аудиту строка 179: `Text(action.value, ...)`).

**🛠 Steps**

1. Создать `mobile/lib/features/team/domain/representative_rights_l10n.dart`:

```dart
import '../../../core/access/domain_actions.dart';

class RightLabel {
  const RightLabel({required this.title, required this.description});
  final String title;
  final String description;
}

/// Карта DomainAction → русское название и пояснение.
/// Источник: ТЗ §1.5, дизайн design/Кластер B/A.
const Map<DomainAction, RightLabel> kRightsRu = {
  DomainAction.projectCreate: RightLabel(
    title: 'Создавать проекты',
    description: 'Может создавать новые ремонтные проекты от имени заказчика.',
  ),
  DomainAction.projectEdit: RightLabel(
    title: 'Редактировать проект',
    description: 'Менять название, адрес, бюджет, сроки проекта.',
  ),
  DomainAction.projectArchive: RightLabel(
    title: 'Архивировать проект',
    description: 'Переводить завершённый проект в архив.',
  ),
  DomainAction.projectInviteMember: RightLabel(
    title: 'Приглашать участников',
    description: 'Добавлять в проект бригадира, мастеров, представителей.',
  ),
  DomainAction.stageManage: RightLabel(
    title: 'Управлять этапами',
    description: 'Создавать, редактировать и закрывать этапы.',
  ),
  DomainAction.stageStart: RightLabel(
    title: 'Запускать этапы',
    description: 'Нажимать «Старт» — этап переходит в работу.',
  ),
  DomainAction.stagePause: RightLabel(
    title: 'Ставить этапы на паузу',
    description: 'Приостанавливать работы с указанием причины.',
  ),
  DomainAction.stepManage: RightLabel(
    title: 'Управлять шагами',
    description: 'Создавать и редактировать шаги внутри этапа.',
  ),
  DomainAction.stepAddSubstep: RightLabel(
    title: 'Добавлять подшаги',
    description: 'Дробить шаги на чек-лист подшагов.',
  ),
  DomainAction.stepPhotoUpload: RightLabel(
    title: 'Загружать фото к шагам',
    description: 'Прикреплять фотографии хода работ.',
  ),
  DomainAction.approvalRequest: RightLabel(
    title: 'Запрашивать согласование',
    description: 'Отправлять заказчику план, шаг или приёмку на одобрение.',
  ),
  DomainAction.approvalDecide: RightLabel(
    title: 'Принимать решения по согласованиям',
    description: 'Одобрять или отклонять планы, шаги, приёмки от имени заказчика.',
  ),
  DomainAction.approvalList: RightLabel(
    title: 'Видеть все согласования',
    description: 'Открыт раздел «Согласования» с историей решений.',
  ),
  DomainAction.financeBudgetView: RightLabel(
    title: 'Видеть бюджет',
    description: 'Открыт раздел «Финансы» и сметы по этапам.',
  ),
  DomainAction.financeBudgetEdit: RightLabel(
    title: 'Менять бюджет',
    description: 'Корректировать суммы и распределение средств.',
  ),
  DomainAction.financePaymentCreate: RightLabel(
    title: 'Создавать платежи',
    description: 'Авансы бригадиру, оплаты мастерам и поставщикам.',
  ),
  DomainAction.financePaymentConfirm: RightLabel(
    title: 'Подтверждать платежи',
    description: 'Закрывать платёж после фактического получения.',
  ),
  DomainAction.financePaymentDispute: RightLabel(
    title: 'Открывать споры по платежам',
    description: 'Если получатель не получил оплату — открыть диспут.',
  ),
  DomainAction.financePaymentResolve: RightLabel(
    title: 'Разрешать споры по платежам',
    description: 'Закрывать диспуты с решением о возврате/доплате.',
  ),
  DomainAction.materialsManage: RightLabel(
    title: 'Управлять материалами',
    description: 'Заказывать, отмечать получение, оспаривать поставки.',
  ),
  DomainAction.materialFinalize: RightLabel(
    title: 'Финализировать материалы',
    description: 'Закрывать список материалов после доставки.',
  ),
  DomainAction.selfPurchaseCreate: RightLabel(
    title: 'Создавать самозакуп',
    description: 'Заявлять о самостоятельной покупке материалов с компенсацией.',
  ),
  DomainAction.selfPurchaseConfirm: RightLabel(
    title: 'Подтверждать самозакуп',
    description: 'Одобрять заявки на самозакуп от мастеров.',
  ),
  DomainAction.toolsManage: RightLabel(
    title: 'Управлять инструментами',
    description: 'Раздел «Мои инструменты» — создание, изменение.',
  ),
  DomainAction.toolsIssue: RightLabel(
    title: 'Выдавать инструменты',
    description: 'Передавать инструмент мастеру в работу.',
  ),
  DomainAction.toolsReturn: RightLabel(
    title: 'Возвращать инструменты',
    description: 'Принимать инструмент обратно от мастера.',
  ),
  DomainAction.chatRead: RightLabel(
    title: 'Читать чаты',
    description: 'Доступ к разделу «Коммуникации».',
  ),
  DomainAction.chatWrite: RightLabel(
    title: 'Писать в чаты',
    description: 'Отправлять сообщения в проектных и этапных чатах.',
  ),
  DomainAction.chatCreatePersonal: RightLabel(
    title: 'Создавать личные чаты',
    description: 'Открывать диалоги один на один с участниками.',
  ),
  DomainAction.chatCreateGroup: RightLabel(
    title: 'Создавать групповые чаты',
    description: 'Создавать собственные группы внутри проекта.',
  ),
  DomainAction.chatToggleCustomerVisibility: RightLabel(
    title: 'Скрывать чаты от заказчика',
    description: 'Делать чат приватным внутри бригады.',
  ),
  DomainAction.chatModerate: RightLabel(
    title: 'Модерировать чаты',
    description: 'Удалять чужие сообщения, исключать участников.',
  ),
  DomainAction.documentRead: RightLabel(
    title: 'Просматривать документы',
    description: 'Открыт раздел «Документы».',
  ),
  DomainAction.documentWrite: RightLabel(
    title: 'Загружать документы',
    description: 'Прикреплять договоры, акты, сметы.',
  ),
  DomainAction.documentDelete: RightLabel(
    title: 'Удалять документы',
    description: 'Стирать ранее загруженные файлы.',
  ),
  DomainAction.feedExport: RightLabel(
    title: 'Экспортировать историю',
    description: 'Скачивать ленту проекта в PDF или ZIP.',
  ),
  DomainAction.noteManage: RightLabel(
    title: 'Управлять заметками',
    description: 'Создавать и редактировать заметки к шагам.',
  ),
  DomainAction.questionManage: RightLabel(
    title: 'Управлять вопросами',
    description: 'Задавать и отвечать на вопросы по шагам.',
  ),
  DomainAction.methodologyRead: RightLabel(
    title: 'Читать методичку',
    description: 'Открыт раздел «Методичка» с инструкциями.',
  ),
};

/// Группировка прав по логическим разделам — для UI rep_rights_sheet.
const kRightsGrouped = <String, List<DomainAction>>{
  'Проект': [
    DomainAction.projectEdit,
    DomainAction.projectArchive,
    DomainAction.projectInviteMember,
  ],
  'Этапы и работы': [
    DomainAction.stageManage,
    DomainAction.stageStart,
    DomainAction.stagePause,
    DomainAction.stepManage,
  ],
  'Согласования': [
    DomainAction.approvalRequest,
    DomainAction.approvalDecide,
  ],
  'Финансы': [
    DomainAction.financeBudgetView,
    DomainAction.financePaymentCreate,
    DomainAction.financePaymentConfirm,
    DomainAction.financePaymentDispute,
  ],
  'Материалы и инструменты': [
    DomainAction.materialsManage,
    DomainAction.toolsManage,
    DomainAction.toolsIssue,
  ],
};
```

2. В `rep_rights_sheet.dart` (строка 179 по аудиту) заменить:
   ```dart
   // БЫЛО:
   Text(action.value, style: AppTextStyles.micro),
   
   // СТАЛО:
   Builder(builder: (_) {
     final label = kRightsRu[action];
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label?.title ?? action.value, style: AppTextStyles.bodyMedium),
         if (label != null) ...[
           SizedBox(height: 4),
           Text(label.description, style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary)),
         ],
       ],
     );
   }),
   ```

3. В `rep_rights_screen.dart` (профиль представителя) — то же самое.

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: открыть Команда → представитель → «Права представителя» → видны карточки с русскими названиями + пояснениями.
- [ ] Smoke 2: тоже же из Профиль → «Мои права в проекте».

**📝 Notes**
- НЕ переводить admin.* экшены — они только для админ-панели и не должны попадать в rep_rights UI.
- Если бекенд добавит новый DomainAction — добавить и в эту карту. Иначе будет fallback на технический `action.value`.

---

### P1.2 Карта NotificationKind → RU (уведомления)

**Status:** ☐ todo

**🎯 Цель**: уведомления отображаются с понятными русскими title и body. На экране настроек у lock-иконки критичных — tooltip с пояснением.

**📍 Где**
- ТЗ: §15.2 (push-приоритеты).
- Дизайн: `design/Кластер F — Коммуникации.html` (f-notifications, s-notif-settings).
- Backend: `backend/apps/api/src/modules/notifications/` + `prisma/schema.prisma:264-293, 1079-1112` (NotificationKind enum, NotificationLog).
- Mobile: `mobile/lib/features/notifications/presentation/notifications_screen.dart`.
- Mobile: `mobile/lib/features/profile/presentation/notification_settings_screen.dart`.

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `grep -n "NotificationKind\|enum.*Notification" mobile/lib/features/notifications/domain/` — список enum.
- [ ] `Read mobile/lib/features/notifications/presentation/notifications_screen.dart` — где рендер title/body.

**🛠 Steps**

1. Создать `mobile/lib/features/notifications/domain/notification_l10n.dart`:

```dart
import 'notification_kind.dart';  // или откуда enum NotificationKind

class NotifTemplate {
  const NotifTemplate({required this.title, required this.body});
  final String title;
  /// {param} — плейсхолдеры, заполняемые из notification.payload.
  final String body;
}

/// Источник: ТЗ §15.2 + design/Кластер F.
/// Если ключа нет в карте — UI fallback на raw notification.title/body.
const Map<NotificationKind, NotifTemplate> kNotifRu = {
  NotificationKind.approvalRequested: NotifTemplate(
    title: 'Новое согласование',
    body: 'Требуется ваше решение по этапу «{stageName}»',
  ),
  NotificationKind.approvalApproved: NotifTemplate(
    title: 'Согласование одобрено',
    body: 'Заказчик одобрил «{approvalTitle}»',
  ),
  NotificationKind.approvalRejected: NotifTemplate(
    title: 'Согласование отклонено',
    body: 'Заказчик отклонил «{approvalTitle}». Причина: {reason}',
  ),
  NotificationKind.paymentCreated: NotifTemplate(
    title: 'Новая оплата',
    body: 'Создан платёж на {amount} ₽ — ожидает подтверждения',
  ),
  NotificationKind.paymentConfirmed: NotifTemplate(
    title: 'Оплата подтверждена',
    body: 'Получатель подтвердил получение {amount} ₽',
  ),
  NotificationKind.paymentDisputed: NotifTemplate(
    title: 'Открыт спор по оплате',
    body: '{actorName} открыл диспут по платежу {amount} ₽',
  ),
  NotificationKind.paymentResolved: NotifTemplate(
    title: 'Спор по оплате закрыт',
    body: 'Решение принято — {resolution}',
  ),
  NotificationKind.stageRejected: NotifTemplate(
    title: 'Этап не принят',
    body: 'Этап «{stageName}» отклонён. Замечания: {reason}',
  ),
  NotificationKind.stageOverdue: NotifTemplate(
    title: 'Просрочен этап',
    body: 'Этап «{stageName}» прошёл срок сдачи',
  ),
  NotificationKind.stageDeadlineExceedsProject: NotifTemplate(
    title: 'Срок этапа выходит за проект',
    body: 'Этап «{stageName}» — дедлайн позже окончания проекта',
  ),
  NotificationKind.stageCompleted: NotifTemplate(
    title: 'Этап завершён',
    body: 'Этап «{stageName}» отправлен на приёмку',
  ),
  NotificationKind.stagePaused: NotifTemplate(
    title: 'Этап на паузе',
    body: 'Этап «{stageName}» поставлен на паузу: {reason}',
  ),
  NotificationKind.stepCompleted: NotifTemplate(
    title: 'Шаг выполнен',
    body: 'Мастер закрыл шаг «{stepName}»',
  ),
  NotificationKind.materialRequestCreated: NotifTemplate(
    title: 'Запрошен материал',
    body: 'Бригада запросила {materialName} — требуется одобрение',
  ),
  NotificationKind.materialDelivered: NotifTemplate(
    title: 'Материал доставлен',
    body: 'Получено: {materialName}',
  ),
  NotificationKind.materialDisputed: NotifTemplate(
    title: 'Спор по материалу',
    body: 'Бригада оспаривает доставку: {materialName}',
  ),
  NotificationKind.selfpurchaseCreated: NotifTemplate(
    title: 'Заявка на самозакуп',
    body: '{actorName} запросил компенсацию {amount} ₽',
  ),
  NotificationKind.toolIssued: NotifTemplate(
    title: 'Выдан инструмент',
    body: 'Вам выдан {toolName}, {qty} шт. Подтвердите получение.',
  ),
  NotificationKind.exportCompleted: NotifTemplate(
    title: 'Экспорт готов',
    body: 'Файл «{exportName}» готов к скачиванию',
  ),
  NotificationKind.exportFailed: NotifTemplate(
    title: 'Ошибка экспорта',
    body: 'Не удалось сформировать файл — попробуйте ещё раз',
  ),
  NotificationKind.chatMessageNew: NotifTemplate(
    title: '{senderName} в «{chatName}»',
    body: '{messagePreview}',
  ),
  NotificationKind.noteCreatedForMe: NotifTemplate(
    title: 'Новая заметка',
    body: '{actorName} оставил заметку: «{notePreview}»',
  ),
  NotificationKind.questionAsked: NotifTemplate(
    title: 'Новый вопрос',
    body: '{actorName} задал вопрос по «{stepName}»',
  ),
  NotificationKind.projectArchived: NotifTemplate(
    title: 'Проект в архиве',
    body: 'Проект «{projectName}» переведён в архив',
  ),
  NotificationKind.membershipAdded: NotifTemplate(
    title: 'Вас добавили в проект',
    body: 'Вы участник «{projectName}» в роли {role}',
  ),
};

String renderBody(NotificationKind kind, Map<String, dynamic> payload, {String? fallback}) {
  final template = kNotifRu[kind]?.body ?? fallback ?? '';
  return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final key = m.group(1)!;
    return payload[key]?.toString() ?? '';
  });
}

String renderTitle(NotificationKind kind, Map<String, dynamic> payload, {String? fallback}) {
  final template = kNotifRu[kind]?.title ?? fallback ?? '';
  return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final key = m.group(1)!;
    return payload[key]?.toString() ?? '';
  });
}
```

2. В `notifications_screen.dart`: при рендере карточки уведомления использовать `renderTitle/renderBody`:
   ```dart
   final title = renderTitle(notification.kind, notification.payload, fallback: notification.title);
   final body = renderBody(notification.kind, notification.payload, fallback: notification.body);
   ```

3. В `notification_settings_screen.dart` рядом с lock-иконкой критичного уведомления добавить tooltip:
   ```dart
   if (kind.isCritical)
     Tooltip(
       message: 'Это критичное уведомление (оплаты, согласования, просрочки) — отключить нельзя.',
       child: Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
     ),
   ```

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: триггернуть уведомление на бекенде (например, создать платёж как заказчик) → у бригадира приходит уведомление с понятным RU title+body.
- [ ] Smoke 2: открыть «Уведомления» → видны карточки с человеческим текстом, не с `approval_requested`.
- [ ] Smoke 3: Профиль → Настройки уведомлений → у lock-иконок tooltip с пояснением.

**📝 Notes**
- Бекенд должен отправлять `payload: {stageName: "...", amount: 12000, ...}` в каждом уведомлении. Если payload пуст — рендер вставит пустые строки.
- Если бекенд возвращает уже локализованные `notification.title/body` — рендер использует их через fallback.

---

### P1.3 Этапы — верификация и недоделки

**Status:** ☐ todo

**🎯 Цель**: убедиться, что все 8 computed display-states этапа отображаются корректно, pause-sheet работает, create-wizard работает. Если что-то не работает — добавить подзадачи.

**📍 Где**
- ТЗ: §2.4 (светофор и состояния).
- Дизайн: `design/Кластер C — Этапы.html` (c-stage-* экраны).
- Backend: `backend/apps/api/src/modules/stages/stages.controller.ts`.
- Mobile: `mobile/lib/features/stages/`.

**🔗 Зависит от**: нет.

**🛠 Steps**
1. Запустить эмулятор/симулятор: `flutter run -d <device>` через MCP `dart` `launch_app`.
2. Создать проект, создать этап, пройти все состояния:
   - waiting (исходное)
   - active (после Старт)
   - paused (после Пауза с причиной)
   - resumed (после Возобновить)
   - review (после Сдать на приёмку)
   - done (после одобрения заказчиком)
   - rejected (после отклонения)
   - overdue (изменить дату на бекенде, дождаться cron — или мокать)
   - late-start (создать с прошедшей датой старта, не нажимать Старт)
3. Для каждого state записать наблюдение: ✅ работает / ❌ не работает.
4. Если ❌ — открыть тикет/подзадачу с file:line.

**🧪 Verify**
- [ ] Все 8 states видны корректно.
- [ ] pause-sheet с 4 причинами + обязательный комментарий для «другое».
- [ ] create-wizard: blank + 8 платформенных шаблонов + user templates.
- [ ] reorder этапов через drag-and-drop.

**📝 Notes**
- Если backend не возвращает `displayState: 'late-start'` — это computed на стороне UI или сервера? По ТЗ — на сервере.

---

### P1.4 Иерархия отчётности — UI прозрачность шагов и этапов

**Status:** ☐ todo

**🎯 Цель**: визуально показать, кто кому отчитывается. Мастер не видит «закрыть шаг» — только «отправить бригадиру»; бригадир не видит «принять этап» — только «отправить заказчику»; на каждом ресурсе — бейдж/строка «Кто запросил → кому → статус».

**📍 Где**
- ТЗ: §2.4 (FSM этапов), §6 (Approval), gaps §3.2 (блокировка Start до plan-approval), gaps §3.3 (запрет минуть бригадира).
- Дизайн: `design/Кластер C — Этапы.html` (c-step-detail, c-stage-active, c-stage-review).
- Mobile: `mobile/lib/features/steps/presentation/step_detail_screen.dart`.
- Mobile: `mobile/lib/features/stages/presentation/stage_detail_screen.dart`.
- Mobile: `mobile/lib/features/approvals/presentation/approval_detail_screen.dart` (модифицирован).

**🔗 Зависит от**: S0.1.

**✅ Pre-conditions**
- [ ] Прочитать матрицу 2A.1 — иерархия master → foreman → customer.
- [ ] `Read mobile/lib/features/steps/presentation/step_detail_screen.dart` — найти CTA-кнопки.
- [ ] `Read mobile/lib/features/stages/presentation/stage_detail_screen.dart` — найти CTA-кнопки.

**🛠 Steps**

#### P1.4.a — CTA на шаге зависит от роли

В `step_detail_screen.dart` для нижнего CTA-блока:

```dart
final role = ref.watch(activeRoleProvider);
final isStepAssignee = step.assigneeIds.contains(myUserId);
final isStageForeman = stage.foremanIds.contains(myUserId);

if (role == SystemRole.master && isStepAssignee) {
  // Мастер: только запрос к бригадиру
  return PrimaryButton(
    label: 'Отправить бригадиру на проверку',
    onPressed: () => ref.read(stepControllerProvider).requestReview(stepId),
  );
}

if ((role == SystemRole.contractor && isStageForeman) || /* canEditStages */) {
  // Бригадир: либо принять/отклонить шаг (если в review), либо закрыть
  if (step.status == StepStatus.review) {
    return Row([
      SecondaryButton(label: 'Вернуть на доработку', onPressed: ...),
      PrimaryButton(label: 'Принять шаг', onPressed: ...),
    ]);
  }
  return PrimaryButton(label: 'Отметить выполненным', onPressed: ...);
}

if (role == SystemRole.customer || /* representative.canApprove */) {
  // Заказчик: только если это extra_work, ожидающий approval
  if (step.type == StepType.extra && step.status == StepStatus.pendingApproval) {
    return Row([
      SecondaryButton(label: 'Отклонить', ...),
      PrimaryButton(label: 'Одобрить доп.работу', ...),
    ]);
  }
  return SizedBox.shrink();  // обычный шаг — заказчик читает
}
```

Под CTA добавить «отчётный» бейдж:

```dart
HierarchyBadge(
  from: step.authorName,
  fromRole: 'Мастер',
  to: stage.foremanName,
  toRole: 'Бригадир',
  status: step.status,  // pending / review / done / pending_approval
)
```

#### P1.4.b — CTA на этапе зависит от роли

В `stage_detail_screen.dart`:

```dart
if (role == SystemRole.contractor && isForeman) {
  switch (stage.status) {
    case StageStatus.pending:
      // Старт заблокирован пока план не согласован (gaps §3.2)
      if (!stage.planApproved) {
        return DisabledButton(
          label: 'Старт',
          tooltip: 'Сначала отправьте план на согласование заказчику',
        );
      }
      return PrimaryButton(label: 'Старт', onPressed: ...);
    case StageStatus.active:
      return Row([
        SecondaryButton(label: 'Пауза', onPressed: openPauseSheet),
        PrimaryButton(label: 'Отправить на приёмку', onPressed: requestStageAccept),
      ]);
    case StageStatus.paused:
      return PrimaryButton(label: 'Возобновить', onPressed: ...);
    case StageStatus.review:
      return InfoBanner(text: 'Этап ожидает приёмки заказчиком');
    case StageStatus.rejected:
      return InfoBanner(text: 'Этап отклонён. Замечания: ${stage.rejectionReason}');
    case StageStatus.done:
      return SuccessBanner(text: 'Этап принят и закрыт');
  }
}

if ((role == SystemRole.customer || canApprove) && stage.status == StageStatus.review) {
  return Row([
    SecondaryButton(label: 'Отклонить с замечаниями', onPressed: openRejectSheet),
    PrimaryButton(label: 'Принять этап', onPressed: acceptStage),
  ]);
}
```

#### P1.4.c — Approval запрос всегда от бригадира (gaps §3.3)

В `approval_detail_screen.dart` (модифицирован) убедиться:
- Если `approval.requestedById == authorMaster` И есть foreman этапа — это **некорректное состояние** (баг бекенда). Показать warning baner.
- Если `approval.scope == 'plan' || 'stage_accept'` — `requestedById` всегда бригадир.
- Backend должен валидировать (`approvals.service.ts` — добавить throw, если master пытается запросить минуя бригадира).

#### P1.4.d — Виджет HierarchyBadge

Создать `mobile/lib/shared/widgets/hierarchy_badge.dart`:

```dart
class HierarchyBadge extends StatelessWidget {
  const HierarchyBadge({
    required this.from,
    required this.fromRole,
    required this.to,
    required this.toRole,
    required this.status,
  });

  final String from;        // имя "Иван И."
  final String fromRole;    // "Мастер"
  final String to;
  final String toRole;
  final String status;      // "Ожидает проверки" / "Принято" / "На доработке"

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.person_outline, size: 14),
        SizedBox(width: 4),
        Text('$from ($fromRole)', style: AppTextStyles.micro),
        SizedBox(width: 6),
        Icon(Icons.arrow_forward, size: 12),
        SizedBox(width: 6),
        Text('$to ($toRole)', style: AppTextStyles.micro),
        Spacer(),
        StatusChip(label: status),
      ]),
    );
  }
}
```

Использовать на `step_detail_screen`, `stage_detail_screen`, `approval_detail_screen`, `payment_detail_screen`, `selfpurchase_detail_screen`.

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: мастер открывает свой шаг → видит «Отправить бригадиру на проверку» (а не «Закрыть шаг»).
- [ ] Smoke 2: мастер открывает чужой шаг (того же этапа) → НЕТ CTA-кнопок.
- [ ] Smoke 3: бригадир видит свой этап без согласованного плана → кнопка «Старт» disabled с tooltip про согласование.
- [ ] Smoke 4: бригадир отправляет план → заказчик видит approval-запрос → одобряет → бригадиру разблокирована «Старт».
- [ ] Smoke 5: бригадир отправляет этап на приёмку → заказчик видит «Принять / Отклонить с замечаниями».
- [ ] Smoke 6: на каждом экране (шаг, этап, согласование, платёж, самозакуп) виден HierarchyBadge.

**📝 Notes**
- НЕ давать заказчику кнопку «Принять шаг» — это приватная операция бригадира.
- НЕ давать мастеру кнопку «Старт этапа» — даже если он назначен на единственный шаг.

---

### P1.5 Прозрачность бюджета — заказчик видит распределение аванса

**Status:** ☐ todo

**🎯 Цель**: заказчик/представитель открывает экран бюджета или платежа и видит **полную цепочку движения денег**: «Я → Бригадир (аванс 100к) → Иван-мастер 30к, Пётр-мастер 50к, остаток у бригадира 20к». Это закрывает основной запрос пользователя «понимать, на что ушёл аванс».

**📍 Где**
- ТЗ: §4 (финансы), §6 (Payment.parentPaymentId).
- Дизайн: `design/Кластер E — Финансы.html` (e-budget, e-payment-detail, e-payment-distribution).
- Backend: `payments.service.ts`, `budget-calculator.ts`.
- Mobile: `mobile/lib/features/finance/presentation/budget_screen.dart` (модифицирован).
- Mobile: `mobile/lib/features/finance/presentation/payment_detail_screen.dart` (модифицирован).

**🔗 Зависит от**: P0.7.b (фильтр платежей должен пускать customer на distribution children).

**✅ Pre-conditions**
- [ ] `git diff mobile/lib/features/finance/presentation/budget_screen.dart`.
- [ ] `git diff mobile/lib/features/finance/presentation/payment_detail_screen.dart`.
- [ ] `Read backend/apps/api/src/modules/payments/payments.controller.ts` — есть ли endpoint для children по parentPaymentId.

**🛠 Steps**

#### P1.5.a — Backend: endpoint children по parent

Если ещё нет:
```typescript
// payments.controller.ts
@Get('payments/:parentId/children')
@UseGuards(JwtAuthGuard)
@RequireAccess({ action: 'finance.budget.view', loadResource: 'payment' })
async children(@Param('parentId') parentId: string, @CurrentUser() user) {
  return this.payments.listChildren(parentId, viewerCtx(user));
}
```

`PaymentsService.listChildren`:
- Возвращает все платежи с `parentPaymentId == parentId`.
- Customer/представитель с canSeeBudget/foreman-родителя — видят все children.
- Мастер — видит только если он `toUserId` одного из children (его собственный).

#### P1.5.b — Mobile: PaymentDetailScreen — показать children

В `payment_detail_screen.dart` для платежа `kind == advance` (customer→foreman):

```dart
// После основной информации о платеже:
final canSeeChildren = role == SystemRole.customer
    || canApprove
    || (role == SystemRole.contractor && payment.toUserId == myUserId);

if (canSeeChildren && payment.kind == PaymentKind.advance) {
  ChildrenPaymentsSection(parentPaymentId: payment.id);
}
```

`ChildrenPaymentsSection` — провайдер, который зовёт `GET /payments/:id/children`, рендерит:

```
Распределение аванса (50 000 ₽)
├ Иван И. (мастер)        20 000 ₽   ✓ подтверждено
├ Пётр П. (мастер)        15 000 ₽   ⏳ ожидает подтверждения
└ Остаток у бригадира     15 000 ₽
```

#### P1.5.c — Mobile: BudgetScreen — секция «Куда ушли деньги»

В `budget_screen.dart` для роли customer/representative:

```dart
ExpansionTile(
  title: Text('Движение средств'),
  children: [
    _MoneyFlowSection(
      title: 'Авансы бригадиру',
      total: budget.totalAdvances,
      items: budget.advances.map((a) => _AdvanceRow(payment: a)).toList(),
    ),
    _MoneyFlowSection(
      title: 'Распределено мастерам',
      total: budget.totalDistributed,
      items: budget.distributions.map((d) => _DistributionRow(...)),
    ),
    _MoneyFlowSection(
      title: 'Самозакуп материалов',
      total: budget.totalApprovedSelfpurchase,
      items: budget.approvedSelfpurchases.map((s) => _SelfpurchaseRow(...)),
    ),
    _MoneyFlowSection(
      title: 'Закупки материалов',
      total: budget.totalMaterials,
      items: budget.materialOrders.map((m) => _MaterialRow(...)),
    ),
  ],
)
```

#### P1.5.d — Backend: расширить BudgetCalculator

Если ещё нет — добавить в `budget-calculator.ts:getProjectBudget`:
- `advances: Payment[]` — все advance customer→foreman.
- `distributions: Payment[]` — все distribution foreman→master.
- `approvedSelfpurchases: SelfPurchase[]` — все foreman→customer approved (фильтр по 2A.7).
- `materialOrders: MaterialRequest[]` — для customer.
- Соответствующие totals.

**🧪 Verify**
- [ ] `cd backend && pnpm test budget` — passing.
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] Smoke 1: создать аванс 100к, бригадир распределяет 30к + 50к → заказчик открывает Бюджет → видит «Распределено: 80к (30к Иван, 50к Пётр), Остаток у бригадира: 20к».
- [ ] Smoke 2: заказчик открывает PaymentDetail аванса → видит секцию children.
- [ ] Smoke 3: мастер открывает свой PaymentDetail → НЕ видит children (это не его аванс).
- [ ] Smoke 4: одобрить самозакуп бригадира → виден в «Самозакуп материалов» в бюджете заказчика.

**📝 Notes**
- Сумма `остаток у бригадира` = parent.amount - sum(children.amount). Может быть отрицательной (warning) — показать красным.
- Если бригадир ещё не распределил — показать «Распределение в процессе» с возможностью раскрыть и увидеть текущие children (даже pending).

---

### P1.6 Прозрачность работ — лента событий с фильтрами по роли

**Status:** ☐ todo

**🎯 Цель**: каждый участник видит ленту событий, отфильтрованную по своей роли (см. матрицу 2A.2). Заказчик видит ВСЁ публичное (фото шагов, утверждения, оплаты, самозакупы approved); мастер видит только свои этапы.

**📍 Где**
- Backend: `feed.service.ts`.
- Mobile: `mobile/lib/features/feed/presentation/feed_screen.dart` (если есть).

**🔗 Зависит от**: P0.7.d.

**🛠 Steps**

1. Backend: после P0.7.d, лента уже фильтруется правильно.
2. Mobile: добавить chip-фильтры:
   - «Все события»
   - «Только этапы»
   - «Только финансы»
   - «Только фото»
3. На каждой карточке события — указание автора + ссылка на ресурс (тап → переход).
4. Заказчик видит «опубликовано бригадиром Иван И. в этапе ‘Демонтаж’» — клик ведёт в этап.

**🧪 Verify**
- [ ] Smoke: заказчик видит фото шагов в реальном времени (после upload через бригадира).
- [ ] Мастер не видит чужие этапы в ленте.

---

## 6. P2 — Multi-team приватность (invite-by-code)

### P2.1 Подтвердить приватность discovery

**Status:** ☐ todo

**🎯 Цель**: убедиться, что пользователь не может видеть проекты, в которых он не owner и не member. Это уже должно работать на бекенде — проверяем.

**📍 Где**
- Backend: `backend/apps/api/src/modules/projects/projects.service.ts:75-84` (фильтр listForUser).
- Mobile: `mobile/lib/features/projects/data/projects_repository.dart` — какой endpoint зовётся.

**🔗 Зависит от**: нет.

**🛠 Steps**
1. Bekend smoke: создать 2-х юзеров, проект под одним. Проверить:
   - `GET /api/projects` под user1 → видит свой проект.
   - `GET /api/projects` под user2 → не видит чужой.
   - `GET /api/projects/:id` под user2 → 403.
2. Если `GET /api/projects/:id` возвращает 200 с данными для не-участника — добавить guard в `ProjectsService.findOne` или добавить @RequireAccess('project.view', resourceLoader).
3. Mobile audit: убедиться, что `projects_repository.dart` НЕ зовёт админский endpoint вместо обычного.

**🧪 Verify**
- [ ] Curl-тест из Steps выше.
- [ ] Smoke в приложении: 2 юзера, видимость взаимоисключительна.

---

### P2.2 Backend: invite-by-code endpoints

**Status:** ☐ todo

**🎯 Цель**: бекенд эндпоинты для генерации 6-значного кода приглашения и присоединения по коду.

**📍 Где**
- Backend: `backend/apps/api/src/modules/projects/invitations.service.ts` (расширить).
- Backend: `backend/apps/api/src/modules/projects/projects.controller.ts` (новые endpoints).
- Backend: `backend/prisma/schema.prisma` — модель `ProjectInvitation` уже есть (token, status).

**🔗 Зависит от**: нет.

**✅ Pre-conditions**
- [ ] `Read backend/apps/api/src/modules/projects/invitations.service.ts` — что уже реализовано.
- [ ] `grep -n "ProjectInvitation\|invitation" backend/prisma/schema.prisma` — структура модели.

**🛠 Steps**

1. **DTO** (`backend/apps/api/src/modules/projects/dto.ts`):
   ```typescript
   export class GenerateInviteCodeDto {
     @IsEnum(MembershipRole) role!: MembershipRole;
     @IsOptional() @IsObject() permissions?: RepresentativeRights;
     @IsOptional() @IsArray() stageIds?: string[];
   }
   
   export class JoinByCodeDto {
     @IsString() @Length(6, 6) code!: string;
   }
   ```

2. **InvitationsService** методы:
   ```typescript
   async generateCode(projectId: string, byUserId: string, dto: GenerateInviteCodeDto) {
     const code = generate6DigitCode(); // crypto.randomInt(100000, 999999)
     const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
     return this.prisma.projectInvitation.create({
       data: {
         projectId,
         token: code,
         role: dto.role,
         permissions: dto.permissions ?? {},
         stageIds: dto.stageIds ?? [],
         expiresAt,
         status: 'pending',
         invitedBy: byUserId,
       },
     });
   }
   
   async joinByCode(userId: string, code: string) {
     const invitation = await this.prisma.projectInvitation.findFirst({
       where: { token: code, status: 'pending' },
     });
     if (!invitation) throw new NotFoundException('Код приглашения не найден');
     if (invitation.expiresAt < new Date()) {
       await this.prisma.projectInvitation.update({
         where: { id: invitation.id },
         data: { status: 'expired' },
       });
       throw new GoneException('Срок действия кода истёк');
     }
     // Проверить, что этого юзера ещё нет в проекте.
     const existing = await this.prisma.membership.findFirst({
       where: { projectId: invitation.projectId, userId },
     });
     if (existing) throw new ConflictException('Вы уже участник этого проекта');
     
     // Транзакция: создать Membership + закрыть invitation.
     return this.prisma.$transaction(async (tx) => {
       const membership = await tx.membership.create({
         data: {
           projectId: invitation.projectId,
           userId,
           role: invitation.role,
           permissions: invitation.permissions ?? {},
           stageIds: invitation.stageIds ?? [],
         },
       });
       await tx.projectInvitation.update({
         where: { id: invitation.id },
         data: { status: 'accepted', acceptedBy: userId, acceptedAt: new Date() },
       });
       return { membership, projectId: invitation.projectId };
     });
   }
   ```

3. **Controllers**:
   ```typescript
   // projects.controller.ts
   @Post(':id/invitations/generate-code')
   @UseGuards(JwtAuthGuard)
   @RequireAccess('project.invite_member', loadProjectContext)
   async generateInviteCode(
     @Param('id') projectId: string,
     @CurrentUser() user,
     @Body() dto: GenerateInviteCodeDto,
   ) {
     return this.invitationsService.generateCode(projectId, user.id, dto);
   }
   
   @Post('join-by-code')
   @UseGuards(JwtAuthGuard)
   async joinByCode(@CurrentUser() user, @Body() dto: JoinByCodeDto) {
     return this.invitationsService.joinByCode(user.id, dto.code);
   }
   ```

4. **Тесты** (`invitations.service.spec.ts`):
   - generate → код сохранён, status=pending.
   - join valid → membership создан, status=accepted.
   - join expired → 410.
   - join non-existent → 404.
   - join already-member → 409.

**🧪 Verify**
- [ ] `cd backend && pnpm test invitations` — passing.
- [ ] `cd backend && pnpm test e2e/projects` — добавить e2e тест на полный flow.
- [ ] Curl smoke:
   ```bash
   # 1. Owner генерирует код
   curl -X POST http://localhost:3000/api/projects/<pid>/invitations/generate-code \
     -H "Authorization: Bearer <owner-jwt>" \
     -H "Content-Type: application/json" \
     -d '{"role": "master"}'
   # → {"token": "123456", "expiresAt": "...", ...}
   
   # 2. Другой юзер присоединяется
   curl -X POST http://localhost:3000/api/projects/join-by-code \
     -H "Authorization: Bearer <user2-jwt>" \
     -H "Content-Type: application/json" \
     -d '{"code": "123456"}'
   # → {"membership": {...}, "projectId": "..."}
   ```

**📝 Notes**
- 6-значный код может коллизировать (1 на миллион). При генерации — повторить если уже существует pending invitation с таким кодом.
- Не фильтровать по phone — пусть код работает для любого зарегистрированного пользователя (по выбору пользователя из ответа).

---

### P2.3 Mobile UI: ввод кода + генерация кода

**Status:** ☐ todo

**🎯 Цель**: 
- Заказчик/представитель с правом приглашать может сгенерировать код в команде, увидеть его крупно, поделиться (sms/whatsapp/copy).
- Любой зарегистрированный пользователь может ввести 6-значный код на главном экране и присоединиться к проекту.

**📍 Где**
- Дизайн: `design/Кластер B — Проекты.html` (s-add-member-* экраны — адаптировать под код).
- Mobile: `mobile/lib/features/projects/presentation/projects_screen.dart` (FAB или кнопка «Присоединиться по коду»).
- Mobile: `mobile/lib/features/team/presentation/team_screen.dart` (кнопка «Сгенерировать код» в team).

**🔗 Зависит от**: P2.2.

**🛠 Steps**

1. **Новый файл** `mobile/lib/features/projects/presentation/join_by_code_screen.dart`:
   - 6 ячеек ввода (или один TextField с masked formatter).
   - Кнопка «Присоединиться».
   - При успехе — `Navigator.pushReplacement` на ConsoleScreen нового проекта + green toast.
   - При ошибке — красный banner с соответствующим текстом (404 → «Код не найден», 410 → «Срок действия истёк», 409 → «Вы уже участник этого проекта»).

2. **Новый файл** `mobile/lib/features/team/presentation/generate_invite_code_sheet.dart`:
   - Bottom sheet.
   - Selectов выбор роли (мастер/бригадир/представитель).
   - Если представитель — чек-лист прав (использует `kRightsRu` из P1.1).
   - Кнопка «Создать код».
   - После создания: показать код крупно (48sp моноширинный), под ним «Действителен до: <дата>».
   - Кнопки `Поделиться` (`share_plus`) и `Скопировать` (`Clipboard.setData`).

3. **Изменения в `projects_screen.dart`**:
   - Добавить FAB (или меню) «Присоединиться по коду» → push `JoinByCodeScreen`.

4. **Изменения в `team_screen.dart`**:
   - Если `ref.watch(canInProjectProvider((action: DomainAction.projectInviteMember, projectId: id)))` — кнопка «Сгенерировать код приглашения» в AppBar или snackbar-actions.
   - Открывает `GenerateInviteCodeSheet`.

5. **Repository метод** (`projects_repository.dart` или новый `invitations_repository.dart`):
   ```dart
   Future<({String code, DateTime expiresAt})> generateInviteCode(
     String projectId, MembershipRole role, {Map<String, bool>? permissions, List<String>? stageIds}
   );
   
   Future<({String projectId, Membership membership})> joinByCode(String code);
   ```

**🧪 Verify**
- [ ] `cd mobile && flutter analyze` — clean.
- [ ] `cd mobile && flutter test test/features/projects/` — passing (+ новые тесты для join_by_code).
- [ ] Smoke 1: заказчик создаёт проект → Команда → «Сгенерировать код» → выбирает роль «Мастер» → видит код 6 цифр → копирует.
- [ ] Smoke 2: мастер открывает приложение → главный экран → «Присоединиться по коду» → вводит код → попадает в проект, видит ConsoleScreen.
- [ ] Smoke 3: мастер пытается ввести код повторно → ошибка «Вы уже участник этого проекта».
- [ ] Smoke 4: ввод неверного кода → ошибка «Код не найден».

**📝 Notes**
- Использовать `share_plus: ^7.x` — он уже есть в `pubspec.yaml` (если нет — добавить).
- 6 ячеек ввода: использовать `pin_code_fields` или собственный простой TextField с inputFormatters.

---

### P2.4 Deep-link для приглашения

**Status:** ☐ todo

**🎯 Цель**: открытие ссылки `repair-control://invite/<code>` или `https://<домен>/invite/<code>` автоматически вызывает join-by-code.

**📍 Где**
- Mobile: `mobile/lib/core/routing/` — найти deep_link_router.dart.
- Mobile: AndroidManifest.xml + Info.plist — intent filters / URL schemes.

**🔗 Зависит от**: P2.3.

**🛠 Steps**
1. `Read mobile/lib/core/routing/deep_link_router.dart` (или эквивалент).
2. Добавить обработку маршрута `/invite/:code`:
   ```dart
   GoRoute(
     path: '/invite/:code',
     builder: (ctx, state) {
       final code = state.pathParameters['code'];
       return JoinByCodeScreen(prefilledCode: code);
     },
   ),
   ```
3. Если поддерживается auto-join (без подтверждения):
   - При open → сразу вызвать `joinByCode(code)`.
   - Показать loading → результат.
   - При ошибке — показать форму с предзаполненным кодом, чтобы пользователь увидел что не так.
4. Обновить AndroidManifest для intent-filter `repair-control://invite`.
5. Обновить Info.plist для CFBundleURLSchemes.

**🧪 Verify**
- [ ] Smoke: на эмуляторе `adb shell am start -W -a android.intent.action.VIEW -d "repair-control://invite/123456" com.repaircontrol.app` → открывается JoinByCodeScreen.
- [ ] iOS: `xcrun simctl openurl booted "repair-control://invite/123456"` → то же.

**📝 Notes**
- Если уже есть deep_link_router — добавить ОДИН route и не трогать остальные.

---

## 7. Verification — финальные smoke-сценарии

После выполнения S0+P0+P1+P2 — пройти полный сценарий «end-to-end ремонт».

### 7.1 Onboarding и команда
1. ☐ Заказчик регистрируется через телефон/SMS-код.
2. ☐ Заказчик создаёт проект (3-step wizard) с бюджетом 1 000 000 ₽.
3. ☐ Заказчик в Команде генерирует код приглашения для роли «Бригадир» → копирует.
4. ☐ Бригадир регистрируется на другом устройстве → главный экран → «Присоединиться по коду» → вводит → попадает в проект.
5. ☐ Бригадир приглашает 2 мастера (новые коды для роли master) — Ивана и Петра.
6. ☐ Заказчик добавляет представителя (код для роли representative с галочками `canSeeBudget`, `canApprove`).

### 7.2 Иерархия команды (приватность)
7. ☐ Заказчик открывает Команда → видит **бригадира + представителя**, **НЕ ВИДИТ мастеров**, нанятых бригадиром (ТЗ §1.4).
8. ☐ Бригадир открывает Команда → видит **всех**: заказчика, представителя, себя, обоих мастеров.
9. ☐ Мастер Иван открывает Команда → видит **бригадира и Петра** (свой этап), **НЕ ВИДИТ заказчика напрямую** (или видит ограниченно — по дизайну).

### 7.3 План этапа (gaps §3.2 — блокировка Старта)
10. ☐ Бригадир создаёт этап «Демонтаж», добавляет шаги, назначает Ивана.
11. ☐ Бригадир пробует «Старт» → кнопка disabled, tooltip «Сначала отправьте план на согласование».
12. ☐ Бригадир отправляет план на согласование → представитель получает push «Новое согласование».
13. ☐ Представитель открывает approval → одобряет → бригадир получает push «Согласование одобрено».
14. ☐ Бригадир теперь нажимает «Старт» — этап в active.

### 7.4 Работа мастера и иерархия отчётности
15. ☐ Мастер Иван открывает свой шаг → CTA = «Отправить бригадиру на проверку» (НЕ «Закрыть шаг»).
16. ☐ Мастер загружает фото шага → upload не крашит → превью видно.
17. ☐ Мастер отправляет шаг на проверку → бригадир получает push.
18. ☐ Бригадир открывает шаг → видит фото + HierarchyBadge «Иван И. (Мастер) → Бригадир | Ожидает проверки».
19. ☐ Бригадир принимает шаг → шаг done.
20. ☐ Заказчик в ленте видит «Иван И. выполнил шаг ‘Снос перегородки’» (через бригадира publish).

### 7.5 Видимость шагов (P0.7.f)
21. ☐ Мастер Пётр открывает экран этапа → видит свои шаги ✅ + видит заголовки шагов Ивана, **НО фото Ивана НЕ видны** Петру.
22. ☐ Заказчик открывает шаг Ивана → видит фото и подшаги.

### 7.6 Доп.работа (extra_work)
23. ☐ Мастер Иван обнаруживает доп.работу → создаёт extra-step → status `pending_approval`.
24. ☐ Доп.работа в бюджет НЕ добавлена пока не approved (gaps §4.1).
25. ☐ Бригадир видит запрос → отправляет заказчику на approve.
26. ☐ Заказчик одобряет → доп.работа попадает в budget.works → видна в бюджете +20 000 ₽.

### 7.7 Платежи и прозрачность (P1.5)
27. ☐ Заказчик создаёт аванс бригадиру 200 000 ₽ → бригадир получает push, подтверждает.
28. ☐ Бригадир распределяет: Иван 80к, Пётр 60к → каждый получает push, подтверждает.
29. ☐ Заказчик открывает PaymentDetail аванса → видит секцию **«Распределение»**: Иван 80к ✓, Пётр 60к ✓, Остаток у бригадира 60к.
30. ☐ Заказчик открывает Бюджет → видит секцию «Движение средств»: Авансы 200к, Распределено 140к, Остаток 60к.
31. ☐ **Мастер Иван открывает Платежи** → видит **только свой платёж 80к** (НЕ видит платёж Петру, НЕ видит общий аванс).
32. ☐ Мастер Иван открывает по ID чужой платёж (curl) → 403 (P0.7.a).

### 7.8 Самозакуп — 2 уровня
33. ☐ Мастер Иван делает самозакуп материалов 5к → отправляет бригадиру → бригадир approve.
34. ☐ Самозакуп Ивана **виден бригадиру и Ивану**, **НЕ виден Петру**, **НЕ виден заказчику** (P0.7.e — приватная бригады).
35. ☐ Бригадир делает самозакуп 30к → отправляет заказчику.
36. ☐ Заказчик одобряет → попадает в budget.materials.spent → +30к виден в Бюджете.
37. ☐ Заказчик в списке самозакупов видит **только foreman→customer**, не master→foreman.

### 7.9 Документы по category (P0.7.c)
38. ☐ Заказчик загружает контракт (category=contract).
39. ☐ Бригадир открывает Документы → видит контракт ✅.
40. ☐ Мастер Иван открывает Документы → **НЕ видит контракт**, видит только photo/blueprint/warranty/other.
41. ☐ Мастер по ID запрашивает contract.id (curl) → 403.

### 7.10 Лента (P0.7.d)
42. ☐ Заказчик открывает Лента → видит ВСЕ публичные события проекта.
43. ☐ Мастер Иван открывает Лента → видит события **только своего этапа**, НЕ видит чужие этапы или внутренние события другой бригады.

### 7.11 Этап → приёмка
44. ☐ Бригадир закрывает все шаги этапа → отправляет «На приёмку» (scope=stage_accept).
45. ☐ Заказчик получает push, открывает approval → видит сводку: фото, доп.работы, бюджет этапа.
46. ☐ Заказчик принимает этап → status=done. Бригадир + мастера получают push «Этап принят».

### 7.12 Чаты и видимость (ТЗ §10.2)
47. ☐ В проекте автоматически создан Project chat → видны: заказчик, представитель, бригадир.
48. ☐ В этапе автоматически создан Stage chat → видны: бригадир, мастера этапа.
49. ☐ Заказчик **НЕ видит Stage chat** по умолчанию.
50. ☐ Бригадир в Stage chat включает «Открыть заказчику» (`canToggleCustomerVisibility`) → заказчик видит чат.
51. ☐ Personal chat между бригадиром и Иваном — заказчик НЕ видит.

### 7.13 Инструменты
52. ☐ Бригадир добавляет инструмент в «Мои инструменты» → не крашит (P0.2).
53. ☐ Бригадир выдаёт инструмент Ивану 2 шт → Иван получает push, подтверждает.
54. ☐ Иван в «Мои выдачи» видит инструмент. Пётр НЕ видит. Заказчик НЕ видит раздел вообще.
55. ☐ Иван возвращает → бригадир подтверждает возврат → counters обновлены.

### 7.14 Уведомления и тексты (P1.1, P1.2)
56. ☐ Все push приходят с **человекочитаемым русским текстом** (не ‘approval_requested’).
57. ☐ Открыть Профиль → Права представителя → видны русские названия + пояснения (P1.1).
58. ☐ Профиль → Настройки уведомлений → у lock-иконок tooltip про критичность.

### 7.15 Переключение ролей
59. ☐ Один пользователь — заказчик в проекте А, бригадир в проекте Б → переключает активную роль → меню обновляется без рестарта (P0.5).

### 7.16 Документы / фото общее (P0.1)
60. ☐ Загрузить JPG → превью отображается → клик → полноэкранно.
61. ☐ Загрузить PDF → «Открыть» → внешнее приложение.
62. ☐ Через час открыть тот же файл → уже истёкший presigned → автозапрос нового → открывается.

### 7.17 Финальные команды
- `cd backend && pnpm test` — ≥ 360 unit + ≥ 35 e2e зелёных (новые тесты P0.7 + P2).
- `cd backend && pnpm test:e2e` — passing.
- `cd mobile && flutter analyze` — clean.
- `cd mobile && flutter test` — ≥ 180 зелёных.
- `cd mobile && flutter build apk --flavor dev --debug` — собирается.

### 7.18 Security regression check
```bash
# Все 5 P0.7 дыр должны быть закрыты:
JWT_MASTER="..."; JWT_OWNER="..."

# 1. master не получает чужой payment
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $JWT_MASTER" \
  http://localhost:3000/api/payments/<other-master-payment-id>
# Expected: 403

# 2. master не видит contract
curl -s -H "Authorization: Bearer $JWT_MASTER" \
  http://localhost:3000/api/projects/<pid>/documents?category=contract | jq 'length'
# Expected: 0

# 3. master видит только свои этапы в feed
curl -s -H "Authorization: Bearer $JWT_MASTER" \
  http://localhost:3000/api/projects/<pid>/feed | \
  jq '[.[] | select(.stageId != null and (.stageId | IN($MY_STAGE_IDS[]) | not))] | length'
# Expected: 0

# 4. owner не видит master→foreman selfpurchase
curl -s -H "Authorization: Bearer $JWT_OWNER" \
  http://localhost:3000/api/projects/<pid>/selfpurchases | \
  jq '[.[] | select(.byRole == "master")] | length'
# Expected: 0

# 5. master не видит чужие фото шага
curl -s -H "Authorization: Bearer $JWT_MASTER" \
  http://localhost:3000/api/projects/<pid>/stages/<sid>/steps/<other-step-id>/photos | jq 'length'
# Expected: 0
```

**Команды:**
- `cd backend && pnpm test` — должно быть ≥ 351 unit + ≥ 30 e2e зелёных (плюс новые на invite).
- `cd mobile && flutter analyze` — clean.
- `cd mobile && flutter test` — ≥ 176 зелёных.
- `cd mobile && flutter build apk --flavor dev --debug` — собирается.

---

## 8. Что вне scope

- **Pro-подписка, эквайринг, аннотации фото** — отложено по §11 ТЗ. Только заглушки в schema.
- **Замена FCM на Mind Push** — заложена абстракция `NotificationProvider`, переключение по необходимости.
- **Публичный каталог проектов / маркетплейс мастеров** — нет в ТЗ, не запрошен пользователем.
- **SMS-инфраструктура для приглашений** — отложено по решению пользователя (выбран invite-by-code).
- **Полноценный i18n для EN** — задел есть в RU/EN ARB, но второй язык не приоритет.

---

## Приложение A: точные line-anchors на момент создания файла

| Файл | Якорь | Строка |
|---|---|---|
| `backend/libs/rbac/src/rbac.types.ts` | DOMAIN_ACTIONS массив | 7-74 |
| `backend/libs/rbac/src/rbac.types.ts` | RepresentativeRights interface | 97-106 |
| `backend/apps/api/src/modules/projects/projects.controller.ts` | members endpoints | 108-149 |
| `mobile/lib/core/network/interceptors/auth_interceptor.dart` | noAuth flag check | 16-19 |
| `mobile/lib/core/access/access_guard.dart` | activeRoleProvider | 116-118 |
| `mobile/lib/core/access/access_guard.dart` | canInProjectProvider | 218-228 |
| `mobile/lib/core/access/access_guard.dart` | _representativeFlagToActions | 161-201 |
| `mobile/lib/features/projects/domain/membership.dart` | _parseRights | 79-94 |
| `mobile/lib/features/projects/domain/membership.dart` | Membership.parse | 60-76 |

Если строки сместились (после правок в этой же итерации) — использовать `grep -n` для поиска якоря.

---

## Приложение B: команды для частых проверок

```bash
# Чистый запуск
cd /Users/serafim/Project/Repair_control

# Backend
cd backend && pnpm install && pnpm prisma migrate dev && pnpm prisma db seed
cd backend && pnpm dev          # http://localhost:3000
cd backend && pnpm test          # unit
cd backend && pnpm test:e2e      # e2e (если есть)

# Mobile
cd mobile && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
cd mobile && flutter analyze
cd mobile && flutter test
cd mobile && flutter run -d <device-id>  # см. flutter devices
cd mobile && flutter build apk --flavor dev --debug

# Curl smoke
JWT="..."  # получить из /api/auth/login
curl -H "Authorization: Bearer $JWT" http://localhost:3000/api/me
curl -H "Authorization: Bearer $JWT" http://localhost:3000/api/projects | jq
curl -H "Authorization: Bearer $JWT" http://localhost:3000/api/methodology/sections | jq
```

---

**Конец документа.** Версия: v1. Создан: 2026-04-26.
