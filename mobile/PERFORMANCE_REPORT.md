# Performance Report

Шаблон для прохождения performance-профилирования через Flutter DevTools.

## Как запускать

```bash
cd mobile
flutter run --flavor prod --release -d <device>
# Открыть DevTools → Performance tab
```

## Сценарии (запускать по очереди, каждый ~2 минуты профилирования)

### 1. Chat conversation (1000+ messages)

- Открыть проектный чат с большим количеством сообщений (создать через staging-seed).
- Скроллить вверх до конца истории.
- **Метрика**: average frame time ≤ 18ms (≥55 FPS).
- **Watch**: missed frames, jank, image-decode pauses на attachments.

### 2. Feed с 500+ событий

- Открыть `s-feed` для проекта со множественными FeedEvent.
- Прокрутка вверх с infinite-load (cursor pagination).
- **Метрика**: memory growth ≤ 20MB, FPS ≥ 55.
- **Watch**: GC-pauses, redundant rebuilds.

### 3. Approvals list (100+ pending)

- `d-approvals` со множественными pending.
- Cold-start экрана.
- **Метрика**: cold-start ≤ 2.5s.
- **Watch**: время до first-frame.

### 4. Photo gallery (50+ images)

- `s-step-detail` с большим photo-grid.
- Тап на фото → photo_view → swipe.
- **Метрика**: memory growth ≤ 50MB при просмотре галереи.
- **Watch**: image cache eviction, GPU memory.

## Таргеты (mid-tier device — Pixel 4a / iPhone SE 2020)

| Метрика | Цель | Метод измерения |
|---|---|---|
| FPS scrollback | ≥ 55 | DevTools Performance frame chart |
| Cold start | ≤ 2.5s | flutter_driver / `time flutter run --release` |
| Memory growth (5min nav) | ≤ 20MB | DevTools Memory tab |
| App size (release APK) | ≤ 25MB | `flutter build apk --release` + `du -h` |
| Photo gallery 50 images | ≤ 50MB peak | DevTools Memory snapshots |

## Найденные узкие места (заполнять при профилировании)

- _(Заполнить после прохода)_

## Backlog tickets

- [ ] Проверить `cached_network_image` cache size limits.
- [ ] FeedEvent rendering — consider `RepaintBoundary` per item.
- [ ] Замерить cold-start с `--trace-startup`.
- [ ] Проверить sentry overhead в release-сборке.

## Подпись

Профилировано: __________  
Дата: __________  
Устройство: __________  
Flutter: __________
