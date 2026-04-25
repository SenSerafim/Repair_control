# Release 1.0.0 — Final Checklist

Финальный чек-лист релиза 1.0.0 (Public TestFlight + Open Beta Google Play).

Источник истины: `Сводное_ТЗ_и_Спринты.md` §13 + `mobile/README_RELEASE.md`.

## Backend

### Инфраструктура
- [ ] `docker compose -f backend/docker-compose.server.yml up -d` поднимается без ошибок.
- [ ] Postgres + Redis + MinIO healthy.
- [ ] `docker compose ps` показывает все сервисы UP.

### Миграции и сидеры
- [ ] `npm run prisma:migrate:deploy` применяется на чистой prod-БД.
- [ ] Миграция `20260425000000_road_to_100` (Step.methodologyArticleId, PaymentDispute.photoKeys, Subscription, FeatureFlag) применилась.
- [ ] `npm run prisma:seed` загружает 8 шаблонов + демо-методичку.

### Тесты
- [ ] `npm run lint` зелёный.
- [ ] `npm run build` зелёный.
- [ ] `npm run test` — 351+ unit зелёные.
- [ ] `npm run test:e2e` — 30+ e2e зелёные (включая новые на step.methodology + payment.dispute.photoKeys).

### OpenAPI
- [ ] `npm run openapi:export` генерирует обновлённый `backend/docs/openapi.v1.json`.
- [ ] Mobile retrofit-клиенты регенерированы из последнего OpenAPI.

### Бэкап и наблюдаемость
- [ ] WAL-G в S3 (Selectel) настроен и пишется.
- [ ] Sentry DSN установлен в `.env.prod` (PROD-проект, не staging).
- [ ] Grafana дашборды (`api-latency`, `feed-publisher`, `push-queue`) живы.
- [ ] Healthcheck алёрты в Telegram настроены.

### Push
- [ ] FCM-сертификат iOS (APNs auth key) загружен в Firebase Console → Cloud Messaging.
- [ ] FCM-сертификат Android (`google-services.json`) в `mobile/android/app/`.

## Mobile

### Базовые проверки
- [ ] `flutter analyze` — `No issues found!`
- [ ] `flutter test` — все 344+ unit/widget/golden зелёные.
- [ ] `flutter test test/golden/` — 44 golden зелёные.
- [ ] `flutter test integration_test/` — smoke-тесты зелёные (skip-помеченные требуют staging).

### Сборки
- [ ] `flutter build apk --flavor prod --release` собирается (≤25MB).
- [ ] `flutter build ipa --flavor prod --release` собирается **после Этапа 1.3 iOS Firebase**.
- [ ] APK устанавливается на физическом Android-устройстве и стартует без crash.
- [ ] IPA устанавливается через TestFlight на физическом iOS-устройстве.

### Подпись
- [ ] Android keystore в `mobile/android/key.properties` (НЕ committed, в gitignore).
- [ ] iOS provisioning profile + signing certificate в Apple Developer.

### Ассеты сторов
- [ ] Иконка 1024×1024 (PNG, alpha=0).
- [ ] Скриншоты RU (минимум 4 для каждого: iPhone 6.7"/6.5"/5.5", Android Pixel-size).
- [ ] Скриншоты EN (после полного перевода UI).
- [ ] Описание для App Store / Play Store (RU + EN).

### Юридическое
- [ ] Политика конфиденциальности (152-ФЗ) опубликована, URL в `mobile/lib/features/auth/presentation/legal_screen.dart`.
- [ ] Пользовательское соглашение опубликовано.
- [ ] Согласие на обработку ПДн при регистрации (чекбокс) корректно блокирует submit без отметки.

### iOS Firebase (Этап 1.3 ROAD_TO_100)
- [ ] iOS app зарегистрирован в Firebase Console (bundleId: `com.repaircontrol.app`).
- [ ] `GoogleService-Info.plist` в `mobile/ios/Runner/`.
- [ ] `mobile/lib/firebase_options.dart` обновлён через `flutterfire configure -p mobile/ -i com.repaircontrol.app`.
- [ ] APNs auth key загружен.
- [ ] Test push на TestFlight-сборке доходит за ≤30s.

### Релиз UX
- [ ] Demo-запись 5–7 минут с прохождением 5 user-stories из ТЗ §19.
- [ ] Test account credentials готовы для модераторов App Store / Play Store.
- [ ] Crash-free rate в Sentry ≥ 99% за неделю до релиза (Internal Testing).

## Финальная регрессия

10 сценариев из ROAD_TO_100 §verification:

1. [ ] Register → Login → Create Project → Add Foreman → Add Stages from template.
2. [ ] Foreman submits план → Customer approves → Foreman нажимает Старт.
3. [ ] Master помечает шаг done, прикрепляет фото, отправляет на approval → Foreman approves.
4. [ ] Customer создаёт advance 500 000 ₽ → Foreman confirms → distribute 3 master'ам.
5. [ ] Master open dispute с фото → Customer resolves с adjustAmount.
6. [ ] Chat: Foreman → Master, edit message за <15 мин → отказ за >15 мин.
7. [ ] Switch language → EN — все 6 кластеров на английском (после Этапа 2 — частично, оставшиеся хардкоды зафиксированы в `L10N_AUDIT.md`).
8. [ ] Force offline → mark step done → online → синхронизация без ошибок.
9. [ ] Push: получение FCM → tap → откроется ApprovalDetail/StageDetail/PaymentDetail/Chat/Material/Document (6 типов).
10. [ ] Export Feed как PDF + ZIP → ссылка приходит в notifications.

## Sign-off

- [ ] Backend lead: __________ Date: __________
- [ ] Mobile lead: __________ Date: __________
- [ ] QA: __________ Date: __________
- [ ] Product: __________ Date: __________

---

**Готово к release 1.0.0 GA после прохождения всех чек-боксов.**
