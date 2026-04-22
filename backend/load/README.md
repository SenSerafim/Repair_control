# Load tests

## s5-load.js

Сценарии k6 для Спринта 5 (чаты, лента, этапы). Пороги:
- `chat_hot` (POST /api/chats/:id/messages): p95 < 300ms
- `feed_cursor` (GET /api/projects/:id/feed): p95 < 200ms
- `stage_detail` (GET /api/stages/:id): p95 < 500ms (общий порог)
- ошибок < 1%

## Запуск

```bash
# Поднимаем staging
docker compose -f docker-compose.yml -f docker-compose.staging.yml --env-file .env.staging up -d

# Посев (если первый раз)
npm run prisma:seed:staging

# Нагрузка
k6 run backend/load/s5-load.js \
  -e API_URL=http://localhost:3000 \
  -e PHONE=+79990000001 \
  -e PASSWORD=staging-demo-12345
```

Установка k6: `brew install k6` (macOS) или `apt install k6` (Linux).

**Не в CI** — ресурсоёмко, запускать вручную перед релизом.
