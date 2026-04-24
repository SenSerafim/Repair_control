# syntax=docker/dockerfile:1.6

# --- Stage 1: builder ---
FROM node:20-alpine AS builder
WORKDIR /app

# Prisma engines + sharp prebuilt для musl
RUN apk add --no-cache openssl libc6-compat

# Копируем только package files для кеша слоя deps
COPY package.json package-lock.json ./
RUN npm ci --include=dev

COPY . .
RUN npx prisma generate && npm run build

# --- Stage 2: runtime ---
FROM node:20-alpine AS runtime
WORKDIR /app

# Chromium dependencies для puppeteer-core + @sparticuz/chromium (PDF/ZIP экспорт, thumbnails)
RUN apk add --no-cache \
    openssl libc6-compat \
    chromium nss freetype harfbuzz ttf-freefont ca-certificates \
    tini

ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Только прод-зависимости (уменьшает размер образа)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Artefacts из builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/prisma ./prisma

# Non-root user
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O- http://localhost:3000/healthz || exit 1

# tini как PID 1 — корректная передача SIGTERM в node
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/apps/api/main.js"]
