#!/bin/bash
# dev.sh — локальный запуск: поднимает docker-compose (pg+redis+minio) и бэкенд в watch-режиме.
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# 1. .env.dev → backend/.env (симлинк, чтобы изменения в .env.dev сразу подхватывались)
if [ ! -L "backend/.env" ] || [ "$(readlink backend/.env)" != "../.env" ]; then
    rm -f backend/.env
    ln -s ../.env backend/.env
fi

# 2. Infra
echo "=== docker-compose up (postgres, redis, minio) ==="
( cd backend && docker compose up -d )

# 3. Prisma: ждём pg, генерим клиент, применяем миграции
echo "=== prisma generate + migrate dev ==="
( cd backend && npx prisma generate && npx prisma migrate dev )

# 4. Nest dev
echo "=== nest start --watch ==="
( cd backend && npm run start:dev )
