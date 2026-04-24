# Repair Control — mobile release checklist

Чек-лист Sprint 17 (релиз). Используется при подготовке первого публичного
билда в TestFlight Internal / Google Play Internal Testing.

## Перед релизом

### Код
- [ ] `flutter analyze` — `No issues found!`
- [ ] `flutter test` — все тесты зелёные (≥ 176 тестов)
- [ ] Version bump в `mobile/pubspec.yaml` (`version: 1.0.0+1`)
- [ ] Ветка `main` — прогон `mobile-ci` зелёный
- [ ] Sentry DSN прописан в `.env.staging` / `.env.prod` (не коммитим)

### Firebase / FCM
- [ ] `mobile/android/app/google-services.json` (из Firebase Console)
- [ ] `mobile/ios/Runner/GoogleService-Info.plist` (из Firebase Console)
- [ ] APNs key загружен в Firebase → Cloud Messaging
- [ ] Test push через `POST /me/devices` + cloud function отправителя
- [ ] Deep-link payloads вручную проверены для 6 типов (approval / payment /
      chat / material / stage / step)
- [ ] `NotificationSettings` — «Критичные» disabled, lock-иконка есть

### iOS
- [ ] Apple Developer аккаунт настроен
- [ ] Bundle ID: `com.repaircontrol.app`
- [ ] Сертификаты (Distribution + Push) в Keychain
- [ ] Provisioning profiles обновлены (dev + distribution)
- [ ] `ios/Runner/Info.plist` — описания permissions:
      Camera, Photo Library, Microphone, Notifications
- [ ] TestFlight Internal build поднят из CI / Fastlane
- [ ] ≥ 5 тестовых пользователей добавлены в TestFlight Internal
- [ ] `flutter build ipa --flavor prod` отработал локально

### Android
- [ ] Keystore (`repair_control.jks`) сохранён в менеджере паролей команды
- [ ] `android/key.properties` — пути к keystore, алиас, пароли
      (файл в `.gitignore`)
- [ ] `applicationId`: `com.repaircontrol.app`
- [ ] `versionCode` / `versionName` синхронизированы с iOS
- [ ] `flutter build appbundle --flavor prod` отработал локально
- [ ] Google Play Console — Internal testing trek открыт
- [ ] ≥ 5 тестовых пользователей в Internal Testing

### Бекенд / staging
- [ ] `backend` staging поднят и отвечает `GET /api/health`
- [ ] Демо-аккаунты (`+7999000000X` / `staging-demo-12345`) работают
- [ ] Seed включает 4 роли × 1 проект
- [ ] `backend/load/` — нагрузочный тест параллельно 50 клиентов без деградации

## E2E smoke (4 роли × happy-path)

### Customer (`+79990000001`)
- [ ] Логин → активная роль → список проектов
- [ ] Создать проект (3-step wizard) → пригласить подрядчика
- [ ] Согласовать план → светофор становится зелёным
- [ ] Отправить аванс → подтвердить получение

### Foreman (`+79990000002`)
- [ ] Принять приглашение → консоль открыта
- [ ] Создать этап из шаблона → старт
- [ ] Добавить мастера → распределить аванс
- [ ] Отметить этап на приёмке → принять у заказчика

### Master (`+79990000003`)
- [ ] Открыть активный этап → отметить шаг
- [ ] Приложить фото (2–3 шт.) → `photos/presign` + `confirm`
- [ ] Подать заявку «доп. работа» → одобрение пришло push
- [ ] Получить выплату → подтвердить получение

### Representative (`+79990000004`)
- [ ] Открыть проект заказчика (делегирование)
- [ ] Согласовать план за заказчика (если rep_right выдан)
- [ ] Попытка согласовать без права → запрет на клиенте + 403 на сервере

## Наблюдаемость / метрики
- [ ] Sentry получает события (проверь release tag)
- [ ] Grafana dashboards зелёные 24 ч (API latency, WS connections)
- [ ] Load test `k6` parallel 50 — нет 5xx, p95 < 800 ms
- [ ] Оффлайн тест: выключить сеть → отметить шаг → включить сеть →
      `offline_queue` дренирует без ошибок

## Документация
- [ ] `CLAUDE.md` обновлён (статусы спринтов S6–S17)
- [ ] `Сводное_ТЗ_и_Спринты.md` §9 синхронизирован с фактом
- [ ] OpenAPI `backend/docs/openapi.v1.json` заморожен в 1.0.0
- [ ] Этот чек-лист приложен к release tag

## Риски на день релиза

1. **FCM санкционный риск** — `NotificationProvider` абстракция в `fcm_service.dart`
   оставляет failover на Mind Push (S17 backlog, не блокирует релиз).
2. **Оффлайн-конфликты 409** — last-write-wins с предупреждением; в
   конфликтных кейсах серверная версия побеждает, клиент показывает
   toast «ваше изменение отменено».
3. **iOS сертификаты** — при истечении Distribution certificate TestFlight
   откажется принимать билд. План Б: hot-fix через Fastlane `match`.

## Команды

```bash
# Локальный запуск dev на симуляторе
cd mobile
flutter pub get
flutter run --flavor dev -t lib/main.dart

# Staging на локальном backend
cd backend && docker compose -f docker-compose.yml \
  -f docker-compose.staging.yml --env-file .env.staging up -d
cd mobile
flutter run --flavor staging -t lib/main_staging.dart

# Production билды
flutter build ipa --flavor prod -t lib/main_prod.dart
flutter build appbundle --flavor prod -t lib/main_prod.dart
```
