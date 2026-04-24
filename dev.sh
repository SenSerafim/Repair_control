#!/bin/bash
# dev.sh — локальный запуск.
#   ./dev.sh             → backend docker + nest watch
#   ./dev.sh mobile      → flutter run (dev flavor)
#   ./dev.sh mobile:gen  → openapi gen + build_runner для mobile
#   ./dev.sh mobile:test → flutter analyze + flutter test
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

cmd="${1:-backend}"

case "$cmd" in
    backend)
        # 1. .env.dev → backend/.env
        if [ ! -L "backend/.env" ] || [ "$(readlink backend/.env)" != "../.env" ]; then
            rm -f backend/.env
            ln -s ../.env backend/.env
        fi
        echo "=== docker-compose up (postgres, redis, minio) ==="
        ( cd backend && docker compose up -d )
        echo "=== prisma generate + migrate dev ==="
        ( cd backend && npx prisma generate && npx prisma migrate dev )
        echo "=== nest start --watch ==="
        ( cd backend && npm run start:dev )
        ;;
    mobile)
        ( cd mobile && flutter run -t lib/main.dart )
        ;;
    mobile:gen)
        ( cd mobile && bash build-scripts/gen_api.sh )
        ;;
    mobile:test)
        ( cd mobile && flutter analyze && flutter test )
        ;;
    *)
        echo "Unknown command: $cmd"
        echo "Available: backend | mobile | mobile:gen | mobile:test"
        exit 1
        ;;
esac
