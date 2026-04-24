#!/bin/bash
# deploy.sh — прод-деплой Repair Control (NestJS backend).
set -e

APP_NAME="$(basename "$(pwd)")"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=== Деплой $APP_NAME ==="

# 1. Проверка prod env
if [ ! -f ".env.prod" ]; then
    echo "ОШИБКА: нет .env.prod"
    exit 1
fi
if grep -q "CHANGE_ME" .env.prod; then
    echo "ОШИБКА: в .env.prod остались CHANGE_ME. Замени на реальные значения перед деплоем."
    grep -n "CHANGE_ME" .env.prod
    exit 1
fi

# 2. Проброс prod env в backend/.env
cp .env.prod backend/.env

# 3. Установка зависимостей и Prisma
cd backend
npm ci
npx prisma generate
npx prisma migrate deploy

# 4. Сборка
npm run build

echo ""
echo "=== $APP_NAME собран ==="
echo "Следующие шаги (вручную):"
echo "  - Запуск: cd backend && npm run start:prod (или через pm2/systemd)"
echo "  - Nginx: sudo nano /etc/nginx/sites-available/$APP_NAME"
echo "  - Включить сайт: sudo ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/"
echo "  - Reload: sudo systemctl reload nginx"
