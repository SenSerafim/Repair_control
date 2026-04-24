# Repair Control

Мобильное приложение для контроля ремонтных работ — 4 роли (заказчик / представитель / бригадир / мастер).

**Структура монорепо:**

- [`backend/`](./backend) — NestJS + Prisma + PostgreSQL + Redis + Selectel S3 + Socket.IO + BullMQ. **S1–S5 закрыты.** API v1.0.0 заморожен.
- [`mobile/`](./mobile) — Flutter 3.35 + Riverpod + go_router. **S6–S17 закрыты.** 192 теста, `flutter analyze` — No issues.
- `design/` — 6 HTML-кластеров макетов (~180 экранов). Источник дизайн-токенов.
- [`Сводное_ТЗ_и_Спринты.md`](./Сводное_ТЗ_и_Спринты.md) — главный рабочий документ.
- [`AUDIT_TO_100.md`](./AUDIT_TO_100.md) — полный аудит + чек-лист готовности к релизу.

## Быстрый старт

### Backend (NestJS)

```bash
cd backend
docker compose up -d postgres redis
cp .env.example .env          # для dev с локальным MinIO
npm ci
npx prisma migrate deploy
npm run prisma:seed:staging   # 5 демо-пользователей
npm run start:dev
```

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run --flavor dev -t lib/main.dart
```

Демо-аккаунты (после seed): `+79990000001` .. `+79990000004` / `staging-demo-12345`.

## Технологии

| Слой | Стек |
|---|---|
| Backend | NestJS 10, Prisma 5, PostgreSQL 16, Redis 7, BullMQ, Socket.IO |
| Хранилище | Selectel Object Storage (ru-7), MinIO для dev |
| Auth | JWT (access 15m / refresh 30d), bcrypt 12 |
| Push | Firebase Cloud Messaging (project `repaircontrol-22bd3`) |
| Monitoring | Sentry + Prometheus + Grafana |
| Mobile | Flutter 3.35, Dart 3.11, Riverpod 2, freezed, go_router 14 |
| Local storage | drift (SQLite) + flutter_secure_storage |
| Тесты | Jest (backend, 404), flutter_test (mobile, 192) |

## Workflow

Рабочая ветка — `dev_v1`. `main` принимает только зелёные спринты.

CI: `.github/workflows/mobile-ci.yml` (analyze → test → build APK).

## Документация

- [`backend/ARCHITECTURE.md`](./backend/ARCHITECTURE.md) — архитектурные решения
- [`backend/README.md`](./backend/README.md) — старт, миграции, staging
- [`mobile/README.md`](./mobile/README.md) — структура клиента
- [`mobile/README_RELEASE.md`](./mobile/README_RELEASE.md) — чек-лист TestFlight / Play Internal
- OpenAPI v1.0.0: `backend/docs/openapi.v1.json` (148 endpoints, 32 модуля)
- Postman: `backend/postman/repair-control.v1.json`
