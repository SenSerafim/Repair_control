# Backend Deploy — CI build → GHCR → server pull

## Архитектура

Сервер `193.181.209.219` имеет 14GB root-диска — этого мало для multi-stage
Docker build (npm ci + tsc + chromium = ~5GB temp + 3GB image). При попытке
build на сервере падает с `ENOSPC: no space left on device` на стадии
export image.

**Решение**: сборка переехала в GitHub Actions, на сервер приходит готовый
образ через `docker compose pull`.

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

## Регистрация и тэги

| Ref | Tag |
|---|---|
| push в `main` | `:main` + `:latest` + `:sha-<7chars>` |
| push в `dev_v1` | `:dev_v1` + `:sha-<7chars>` |
| ручной (workflow_dispatch) | `:<branch>` + `:sha-<7chars>` |

Образ: `ghcr.io/senserafim/repair_control/backend:<tag>` (GHCR приводит owner/repo
в lowercase автоматически).

## Первичная настройка сервера

Один раз — настроить доступ к GHCR (если package приватный):

```bash
# 1. Создать GitHub Personal Access Token (classic) с scope: read:packages
#    https://github.com/settings/tokens

# 2. На сервере залогиниться:
ssh admin@193.181.209.219
echo "<PAT>" | docker login ghcr.io -u <github-username> --password-stdin

# 3. Сделать packages публичными (опционально, упрощает pull без PAT):
#    https://github.com/SenSerafim?tab=packages
#    → repair_control/backend → Package settings → Change visibility → Public
```

Если package публичный — шаги 1-2 не нужны, `docker pull` работает анонимно.

## Регулярный деплой

После каждого push в `main`:

1. **GitHub Actions** автоматически собирает и публикует образ
   (вкладка Actions → workflow `backend-image`).
2. **На сервере** запускается update-скрипт:

   ```bash
   ssh admin@193.181.209.219
   cd /home/admin/repair-control
   bash backend/scripts/server-update.sh
   ```

   Скрипт делает:
   - `git pull` (для compose-файлов и migration SQL)
   - `docker compose pull api` (тянет новый образ из GHCR)
   - `docker compose run --rm api npx prisma migrate deploy`
   - `docker compose up -d` (rolling restart)
   - Smoke `curl /healthz`
   - `docker image prune -af` (освободить место)

## Откат на конкретный SHA

Если последний build сломан, откатимся на предыдущий SHA:

```bash
# 1. Найти sha рабочего билда (https://github.com/SenSerafim/Repair_control/pkgs/container/repair_control%2Fbackend)
# 2. На сервере:
ssh admin@193.181.209.219
cd /home/admin/repair-control/backend
API_IMAGE=ghcr.io/senserafim/repair_control/backend:sha-90d0e1d \
  docker compose -f docker-compose.yml -f docker-compose.staging.yml \
  --env-file .env.staging up -d api
```

## Health checks

```bash
# API
curl -sf http://localhost:3000/healthz

# Admin UI
curl -sf http://localhost:8080/

# Логи
docker compose -f docker-compose.yml -f docker-compose.staging.yml logs -f api
```

## Метрики места

```bash
ssh admin@193.181.209.219 'df -h / && docker system df'
```

При <1GB свободно — `docker image prune -af && docker builder prune -af`.
