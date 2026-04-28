# Yandex Object Storage — настройка для Repair Control

Backend (`backend/libs/files`) работает с любым S3-совместимым провайдером
через переменные `MINIO_*`. Ниже — пошаговая настройка под Yandex Cloud
Object Storage (рекомендуемый prod-провайдер для РФ).

## 1. Создать бакет

1. `https://console.cloud.yandex.ru` → **Object Storage** → **Создать бакет**.
2. Имя бакета — глобально уникальное (`repair-control-<env>` например).
3. Класс хранилища: **Стандартное**.
4. Доступ: **Закрытый** (presigned URL дают временный доступ — публичный
   ACL не нужен).
5. Возраст версий, шифрование — по желанию.

## 2. Сервисный аккаунт + HMAC-ключи

1. **IAM → Сервисные аккаунты → Создать**.
   Роли:
   - `storage.editor` — на каталог (или конкретный бакет).
2. У созданного аккаунта → **Создать новый ключ → Статический ключ доступа**.
   Скопировать **Access Key ID** и **Secret Key** — они показываются один раз.
3. Эти значения положить в:
   ```
   MINIO_ACCESS_KEY=<Access Key ID>
   MINIO_SECRET_KEY=<Secret Key>
   ```

## 3. CORS-политика

Прямой PUT с мобильного клиента и `<img src>` из admin-web блокируются
без CORS-заголовков. Залить политику из `backend/docs/yandex-s3-cors.json`:

```bash
yc storage bucket update --name <bucket> \
  --cors-from-file backend/docs/yandex-s3-cors.json
```

или через консоль: **Object Storage → бакет → Настройки → CORS-политика →
вставить JSON**.

## 4. Переменные окружения

```env
MINIO_ENDPOINT=storage.yandexcloud.net
MINIO_PORT=443
MINIO_USE_SSL=true
MINIO_REGION=ru-central1
MINIO_PATH_STYLE=true
MINIO_BUCKET=<имя бакета>
MINIO_ACCESS_KEY=<Access Key ID>
MINIO_SECRET_KEY=<Secret Key>
MINIO_PRESIGN_TTL_SECONDS=300
```

После старта API увидите в логах:
```
ensureBucket: bucket <name> ok
```
Если не ok — проверьте роль `storage.editor` сервисного аккаунта.

## 5. Проверка

```bash
# Health-check включает minio.listBuckets (degraded vs healthy)
curl https://<api-host>/healthz | jq
```

```bash
# Endpoint /api/projects/:id/documents/presign-upload должен вернуть
# uploadUrl с хостом storage.yandexcloud.net
curl -H "Authorization: Bearer <token>" \
  -X POST https://<api-host>/api/projects/<pid>/documents/presign-upload \
  -d '{"category":"photo","title":"test.jpg","mimeType":"image/jpeg","sizeBytes":1024}'
```

## Lifecycle-политика (опционально)

Для перевода старых файлов в холодное/ледяное хранилище можно добавить
lifecycle через `yc storage bucket update --lifecycle-rule ...`.
По ТЗ §5.4 — `STANDARD → COLD` через 1 год, `COLD → ICE` через 3.

## Troubleshooting

- **403 на upload (PUT presigned URL)** — проверьте CORS-политику бакета,
  Access Key (надо HMAC, не OAuth).
- **403 на download** — TTL у presigned (`MINIO_PRESIGN_TTL_SECONDS`)
  истёк, либо у мобильного устройства расходится системное время с
  сервером больше чем на 15 минут.
- **`signature does not match`** — `MINIO_REGION` отличается от региона
  бакета (`ru-central1` для Yandex).
