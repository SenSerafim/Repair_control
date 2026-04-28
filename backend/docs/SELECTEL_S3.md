# Selectel Object Storage — настройка для Repair Control

Бэкенд (`backend/libs/files`) работает с любым S3-совместимым хранилищем
через переменные `MINIO_*`. Ниже — пошаговая настройка под Selectel
(prod-провайдер, который уже подключён в `.env` и `.env.staging.example`).

Официальная документация: https://docs.selectel.ru/s3/

## 1. Создать бакет

1. Панель Selectel → **Облачные сервисы → Object Storage → Бакеты → Создать**.
2. Имя бакета — глобально уникально (например `repair-control-staging`).
3. Класс хранения: **Стандартное**.
4. Тип: **Приватный** (presigned URL дают временный доступ — публичный
   ACL не нужен).
5. Регион выбираете по геоблизости — для Repair Control используется
   пул `ru-7` (Москва-2). Endpoint — `s3.ru-7.storage.selcloud.ru`.

## 2. S3-ключи (HMAC)

S3 API ожидает HMAC-ключи (Access Key ID + Secret Access Key). Выдаются
сервисному пользователю, не админу аккаунта.

1. **Аккаунт → Сервисные пользователи → Создать**.
2. На странице сервисного пользователя → вкладка **Доступ**.
3. В блоке **S3-ключи** → **Добавить ключ**:
   - Имя ключа: `repair-control-api`.
   - Проект: тот же, в котором лежит бакет.
4. Скопировать `Access Key ID` и `Secret Access Key` — Secret показывается
   один раз, после закрытия диалога его уже не посмотреть.
5. Роль на проекте — **objectstorage.user** (минимум для PUT/GET).
   Если нужно создавать/удалять бакеты из API — **objectstorage.admin**.

Прописать в `.env.staging`:

```env
MINIO_ENDPOINT=s3.ru-7.storage.selcloud.ru
MINIO_PORT=443
MINIO_USE_SSL=true
MINIO_REGION=ru-7
MINIO_PATH_STYLE=true
MINIO_BUCKET=repair-control-staging
MINIO_ACCESS_KEY=<Access Key ID>
MINIO_SECRET_KEY=<Secret Access Key>
MINIO_PRESIGN_TTL_SECONDS=300
```

## 3. CORS-политика

Прямой PUT presigned URL с мобильного клиента и `<img src>` на presigned
GET из admin-web блокируются без CORS.

### Через панель управления

1. Object Storage → ваш бакет → вкладка **CORS**.
2. **Создать правило**:
   - **Allowed methods**: `GET`, `PUT`, `HEAD`.
   - **Allowed origins**: `*` (или конкретный домен admin-web).
   - **Allowed headers**: `*`.
   - **Expose headers**: `ETag`, `x-amz-request-id`.
   - **Max age seconds**: `3600`.

> ⚠️ Для работы CORS у бакета должна быть включена **Virtual-Hosted
> адресация** (вкладка «Настройки бакета»). Без неё preflight-запросы
> отбиваются 400.

### Через AWS CLI

Готовое правило лежит в `backend/docs/selectel-s3-cors.xml`:

```bash
aws s3api put-bucket-cors \
  --bucket repair-control-staging \
  --cors-configuration file://backend/docs/selectel-s3-cors.xml \
  --endpoint-url https://s3.ru-7.storage.selcloud.ru
```

Перед этим в `~/.aws/credentials` положить `[default]` со своими S3-ключами,
а в `~/.aws/config` указать `region = ru-7`.

## 4. Проверка

```bash
# Health-check API. degraded vs healthy
curl https://<api-host>/healthz | jq
```

```bash
# Endpoint /api/projects/:id/documents/presign-upload должен вернуть
# uploadUrl с хостом s3.ru-7.storage.selcloud.ru.
curl -H "Authorization: Bearer <token>" \
  -X POST https://<api-host>/api/projects/<pid>/documents/presign-upload \
  -d '{"category":"photo","title":"test.jpg","mimeType":"image/jpeg","sizeBytes":1024}'
```

Загрузить файл по полученному `uploadUrl` (обычным `curl -X PUT --upload-file ...`),
после чего вызвать `POST /api/documents/<docId>/confirm`. Если confirm вернул
документ с непустым `url` — связка работает, мобильный клиент покажет
inline-превью.

## 5. Lifecycle (опционально)

ТЗ §5.4 требует автомиграцию старых файлов: `STANDARD → COLD` через 1 год,
`COLD → ICE` через 3. Selectel поддерживает Lifecycle через
`PUT bucket?lifecycle` (S3 API). Пример XML см. в документации Selectel
(`/s3/buckets/lifecycle/`).

## Troubleshooting

- **403 на upload (PUT presigned URL)** — проверьте CORS, убедитесь, что у
  сервисного пользователя выдана роль `objectstorage.user` на проекте бакета.
  Также проверьте, что `Content-Type` в PUT совпадает с тем, что был передан
  при создании presigned URL — Selectel включает Content-Type в подпись.
- **403 на download** — TTL у presigned (`MINIO_PRESIGN_TTL_SECONDS = 300`)
  истёк, либо время устройства расходится с сервером больше чем на 15 минут.
- **`SignatureDoesNotMatch`** — `MINIO_REGION` отличается от региона бакета
  (для нашего бакета — `ru-7`).
- **CORS preflight 400** — у бакета не включена Virtual-Hosted адресация.
