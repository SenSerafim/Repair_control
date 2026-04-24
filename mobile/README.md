# Repair Control — Mobile (Flutter)

Flutter-клиент для Repair Control. Реализация идёт итеративно по плану спринтов S6–S17 (см. `../CLAUDE.md` → Flutter roadmap).

## Стек

- Flutter 3.35+ / Dart 3.11
- `flutter_riverpod` 2 + `riverpod_generator`
- `freezed` + `json_serializable`
- `dio` + `openapi_generator_cli` (Dart-Dio клиент из `backend/docs/openapi.v1.json`)
- `go_router` 14
- `drift` (SQLite) + `flutter_secure_storage`
- `socket_io_client` 2 (namespace `/chats` backend-gateway)
- `firebase_messaging` + `flutter_local_notifications`
- `very_good_analysis` (строгий линтер)

## Структура

```
lib/
├── core/              инфра: theme, network, storage, routing, realtime, push, l10n, access
├── api/               СГЕНЕРИРОВАННЫЙ dart-dio клиент (build-scripts/gen_api.sh) — в .gitignore
├── features/<domain>/ domain / data / application / presentation (Clean Architecture)
└── shared/widgets/    AppButton, AppInput, AppCard, StatusPill, AppScaffold, AppStates, AppToast
```

## Запуск

```bash
# dev — backend на localhost:3000
flutter run -t lib/main.dart

# staging — backend на docker-compose staging
flutter run -t lib/main_staging.dart

# prod
flutter run -t lib/main_prod.dart --release
```

Через корневой скрипт: `../dev.sh mobile`.

## Генерация кода

```bash
# 1. API клиент из backend/docs/openapi.v1.json (Docker + openapi-generator-cli)
bash build-scripts/gen_api.sh

# 2. freezed / riverpod / drift
dart run build_runner build --delete-conflicting-outputs

# 3. l10n (lib/core/l10n/*.arb → lib/core/l10n/gen/app_localizations.dart)
flutter gen-l10n
```

## Тесты

```bash
flutter analyze         # строгий линтер (very_good_analysis)
flutter test            # unit + widget
flutter test integration_test/   # e2e (S7+)
```

## Demo-аккаунты (staging, из `backend/README.md`)

| Роль | Телефон | Пароль |
|---|---|---|
| admin | `+79990000000` | `staging-demo-12345` |
| customer | `+79990000001` | `staging-demo-12345` |
| representative | `+79990000002` | `staging-demo-12345` |
| foreman | `+79990000003` | `staging-demo-12345` |
| master | `+79990000004` | `staging-demo-12345` |

## Дизайн-токены

Источник — `design/Кластер *.html` (CSS-переменные). Реализация: `lib/core/theme/tokens.dart`, `text_styles.dart`, `app_theme.dart`. **Никакого хардкода цветов/радиусов/теней** в виджетах.

## Статус спринтов

| Sprint | Что закрыто |
|---|---|
| **S6** (foundation) | Scaffold, design-tokens, shared widgets, Dio+refresh+idempotency, Riverpod+go_router, l10n RU/EN, OpenAPI gen script |
| S7 | Auth (register/login/refresh/recovery), legal-acceptance, device register — **следующий** |
| S8–S17 | См. `../CLAUDE.md` § Flutter roadmap |
