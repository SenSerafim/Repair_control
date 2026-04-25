#!/usr/bin/env bash
# server-update.sh — обновляет staging API на сервере, используя готовый
# образ из GHCR (без локальной сборки — на сервере 14GB диска).
#
# Запускать из корня репозитория на сервере:
#   cd /home/admin/repair-control && bash backend/scripts/server-update.sh
#
# Что делает:
#   1. git pull (новые миграции / compose-файлы)
#   2. docker compose pull api  (тянет ghcr.io/.../backend:main)
#   3. docker compose run --rm api npx prisma migrate deploy  (миграции)
#   4. docker compose up -d  (рестарт api с новым образом)
#   5. healthz smoke + cleanup старых образов
#
# Переменные окружения:
#   API_IMAGE — override образа (например, sha-abc1234 для отката).
#               По умолчанию: ghcr.io/senserafim/repair_control/backend:main

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT/backend"

COMPOSE_ARGS=(-f docker-compose.yml -f docker-compose.staging.yml --env-file .env.staging)

echo "=== [1/5] git pull (origin/main) ==="
git -C "$REPO_ROOT" fetch origin
git -C "$REPO_ROOT" reset --hard origin/main

echo "=== [2/5] docker compose pull api (GHCR) ==="
# Если pull падает с denied — package в GHCR приватный, нужен `docker login ghcr.io`
# с PAT, у которого scope read:packages.
docker compose "${COMPOSE_ARGS[@]}" pull api

echo "=== [3/5] prisma migrate deploy ==="
docker compose "${COMPOSE_ARGS[@]}" run --rm api npx prisma migrate deploy

echo "=== [4/5] docker compose up -d ==="
docker compose "${COMPOSE_ARGS[@]}" up -d api admin-web

echo "=== [5/5] smoke + cleanup ==="
# Ждём пока api станет healthy (max 60s).
for i in {1..30}; do
  if curl -sf http://localhost:3000/healthz >/dev/null; then
    echo "✓ API healthy"
    curl -s http://localhost:3000/healthz
    break
  fi
  sleep 2
done

# Освобождаем место — старые образы api + dangling layers.
docker image prune -af --filter "label!=keep" 2>&1 | tail -3

echo ""
echo "✓ Deploy complete"
df -h / | tail -1
