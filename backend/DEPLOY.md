# Backend Deploy — CI build → GHCR → server pull

Production бекенд живёт на одном Ubuntu-сервере. Образ собирается в GitHub
Actions (репозиторий `SenSerafim/Repair_control`, public) и публикуется в GHCR.
На сервере мы только тянем готовый образ через `docker compose pull` — на
проде 14GB диска, multi-stage build на нём не помещается (ENOSPC при
`export image`).

## TL;DR — стандартный деплой

```bash
# 1. Дождаться зелёного workflow «backend-image» в SenSerafim/Repair_control
#    https://github.com/SenSerafim/Repair_control/actions
# 2. SSH на сервер (учётка см. backend/secrets/server-access.md)
ssh admin@193.181.209.219

# 3. Запустить идемпотентный update-скрипт
cd /home/admin/repair-control && bash backend/scripts/server-update.sh

# 4. Проверить smoke-ответ
curl -sf http://localhost:3000/healthz
```

Скрипт делает: git pull → docker pull api → prisma migrate deploy → up -d →
healthz → docker image prune. На каждый шаг печатает `=== [N/5] ... ===`.

## Архитектура

```
┌──────────────────┐       ┌──────────────┐       ┌─────────────────┐
│ Push в main      │  →    │ GH Actions   │  →    │  GHCR           │
│ (backend/**)     │       │ docker build │       │  ghcr.io/.../   │
│                  │       │ + push       │       │  backend:main   │
└──────────────────┘       └──────────────┘       └────────┬────────┘
                                                            │
                                                            ▼ pull
                                                   ┌─────────────────┐
                                                   │ Server          │
                                                   │ 193.181.209.219 │
                                                   │ docker compose  │
                                                   │ up -d           │
                                                   └─────────────────┘
```

Compose-стек на сервере: `api` (GHCR), `admin-web` (локальный nginx-build),
`postgres:16`, `redis:7`, `minio` (контейнер запущен, но api использует
внешний Selectel S3 — см. ниже).

## Где что лежит

| Что | Где |
|---|---|
| Repo на сервере | `/home/admin/repair-control` |
| Compose-файлы | `backend/docker-compose.yml` + `backend/docker-compose.staging.yml` |
| Env-файл | `backend/.env.staging` (chmod 600, не в git; пример — `.env.staging.example`) |
| Update-скрипт | `backend/scripts/server-update.sh` |
| GHCR образ | `ghcr.io/senserafim/repair_control/backend:main` (public) |
| CI workflow | `.github/workflows/backend-image.yml` |
| Бэкапы pg | `/home/admin/backup-pre-deploy-*.sql` |
| Учётка SSH | `backend/secrets/server-access.md` (gitignored) |

## Тэги образа

| Ref | Tag |
|---|---|
| push в `main` | `:main` + `:latest` + `:sha-<7chars>` |
| push в `dev_v1` | `:dev_v1` + `:sha-<7chars>` |
| ручной (workflow_dispatch) | `:<branch>` + `:sha-<7chars>` |

GHCR приводит owner/repo в lowercase автоматически — отсюда `senserafim/repair_control`.

## Регулярный деплой (подробно)

1. **Запушить в `main`** репозитория `SenSerafim/Repair_control`.
   Workflow `backend-image` запускается на изменения в `backend/**` и
   на ручной trigger в Actions.

2. **Дождаться зелёного билда** (~5–7 мин с кешем buildx, ~12 мин с холодным
   кешем). Можно проверить статус через `gh`:
   ```bash
   gh run list --workflow backend-image.yml --repo SenSerafim/Repair_control --limit 3
   ```

3. **На сервере** запустить:
   ```bash
   ssh admin@193.181.209.219
   cd /home/admin/repair-control && bash backend/scripts/server-update.sh
   ```

   Что делает скрипт:
   - `git fetch && git reset --hard origin/main` — подтягивает compose-файлы
     и SQL-миграции (важно: hard reset, локальные правки на сервере
     теряются — не редактируйте файлы прямо на проде).
   - `docker compose pull api` — тянет новый образ с GHCR. Если digest
     совпадает с локальным, no-op.
   - `docker compose run --rm api npx prisma migrate deploy` — применяет
     pending миграции. Идемпотентно: «No pending migrations to apply.» —
     норм.
   - `docker compose up -d api admin-web` — Compose сам решает: пересоздать
     контейнер (если digest сменился) или оставить.
   - Цикл `curl /healthz` 30×2с — ждём пока api ответит `db:true,redis:true`.
   - `docker image prune -af` — чистит dangling-образы. Освобождает место.

4. **Smoke-проверка** после скрипта:
   ```bash
   curl -sf http://193.181.209.219:3000/healthz
   # ожидание: {"status":"ok","db":true,"redis":true,"minio":true,...}
   ```

   Допустимо: `status:"degraded"` с `minio:false` при первом запросе после
   рестарта — Selectel `listBuckets` бывает медленный (cold). Через
   30–60 секунд должно стать `ok`.

## Откат на конкретный SHA

Если последний билд сломан, откатиться на предыдущий SHA:

```bash
# 1. Найти sha рабочего билда:
#    https://github.com/SenSerafim/Repair_control/pkgs/container/repair_control%2Fbackend
# 2. На сервере:
ssh admin@193.181.209.219
cd /home/admin/repair-control/backend
API_IMAGE=ghcr.io/senserafim/repair_control/backend:sha-90d0e1d \
  docker compose -f docker-compose.yml -f docker-compose.staging.yml \
  --env-file .env.staging up -d api
```

Чтобы зафиксировать откат на дольше — пропишите `API_IMAGE=...` в
`.env.staging` (там уже зарезервирован).

## Бэкап БД перед опасной миграцией

Скрипт автоматически миграции **не бэкапит**. Если миграция новая и
есть опаска — снимите дамп руками до запуска:

```bash
ssh admin@193.181.209.219
docker exec backend-postgres-1 pg_dump -U postgres repair_control \
  > ~/backup-pre-deploy-$(date +%Y%m%d-%H%M%S).sql
```

Восстановление:
```bash
docker exec -i backend-postgres-1 psql -U postgres -d repair_control \
  < ~/backup-pre-deploy-YYYYMMDD-HHMMSS.sql
```

## Первичная настройка сервера (one-time)

Уже сделано, шаги перечислены для воспроизводимости:

```bash
# 1. Установить docker + compose v2 (Ubuntu 24.04)
sudo apt update && sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker admin

# 2. Клонировать репо (используется SenSerafim/Repair_control,
#    т.к. именно с него собирается GHCR-образ)
git clone https://github.com/SenSerafim/Repair_control.git /home/admin/repair-control

# 3. Положить .env.staging
cp backend/.env.staging.example backend/.env.staging
chmod 600 backend/.env.staging
nano backend/.env.staging   # реальные секреты

# 4. (Опционально) Если GHCR package приватный — залогиниться:
echo "<PAT_with_read:packages>" | docker login ghcr.io -u <user> --password-stdin
# Сейчас package публичный, шаг не нужен.

# 5. Поднять стек
cd backend
docker compose -f docker-compose.yml -f docker-compose.staging.yml \
  --env-file .env.staging up -d
```

## Health checks и логи

```bash
# API
curl -sf http://localhost:3000/healthz

# Admin UI (статика)
curl -sf http://localhost:8080/

# Логи api в realtime
cd /home/admin/repair-control/backend
docker compose -f docker-compose.yml -f docker-compose.staging.yml logs -f api

# Контейнеры и место
docker ps
docker system df
df -h /
```

## Известные «гримасы» (не считать багом деплоя)

- **`backend-admin-web-1` показывает `unhealthy`.** Healthcheck использует
  `wget`, которого в alpine-nginx нет, — failing streak растёт, но nginx
  отвечает на реальные запросы 200. Косметика.
- **`status:"degraded"` с `minio:false` сразу после рестарта.** API
  пингует Selectel `s3.ru-7.storage.selcloud.ru` через `listBuckets`,
  иногда первый ответ >500ms. Через ~30с становится `ok`.
- **Свободно ~1.5GB.** Нормально, пока стек не растёт. При <1GB —
  `docker image prune -af && docker builder prune -af`. Дополнительно
  чистить старые `~/backup-pre-deploy-*.sql`.

## Troubleshooting

### `docker compose pull` падает с `denied`
GHCR package стал приватным. Залогиниться:
```bash
echo "<PAT>" | docker login ghcr.io -u <github-user> --password-stdin
```
Альтернатива — сделать package публичным:
https://github.com/SenSerafim?tab=packages → repair_control/backend →
Package settings → Change visibility → Public.

### `prisma migrate deploy` падает
Скорее всего конфликт схемы. Снимите бэкап (см. выше), посмотрите ошибку:
```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml \
  --env-file .env.staging run --rm api npx prisma migrate status
```
Если миграция упала на середине — `prisma migrate resolve --rolled-back <name>`
после починки SQL.

### API не становится healthy 60с
```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml \
  --env-file .env.staging logs --tail 200 api
```
Чаще всего — неверный `DATABASE_URL`/`REDIS_URL` или отсутствует секрет
в `.env.staging`. Перезапустить: `docker compose ... up -d --force-recreate api`.

### Сервер забит — `no space left on device`
```bash
docker image prune -af
docker builder prune -af
docker volume prune -f         # ОСТОРОЖНО: проверь сначала docker volume ls
ls -lhS ~/backup-pre-deploy-*.sql | tail -n +5 | awk '{print $NF}' | xargs rm
```

### Нужно дотянуть мобильные коммиты в SenSerafim, а не только origin
Локально настроены два remote:
- `origin` = `softspace-dev/repair-control` (команда)
- `senserafim` = `SenSerafim/Repair_control` (публичный, c GHCR Actions)

Если команда хочет, чтобы свежий main попал на прод:
```bash
git push senserafim main
```
Только после этого workflow `backend-image` запустится и образ обновится.

## Метрики места

```bash
ssh admin@193.181.209.219 'df -h / && docker system df'
```

При <1GB свободно — `docker image prune -af && docker builder prune -af`.
