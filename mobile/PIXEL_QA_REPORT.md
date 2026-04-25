# Pixel-Perfect QA Report

Шаблон для прохождения QA по 6 кластерам дизайна. Заполняется ручным сравнением `design/Кластер*.html` с приложением на устройстве.

## Как проводить

```bash
cd mobile && flutter run --flavor dev -d <device-id>
open ../design/Кластер\ *.html
```

Открыть макет и приложение рядом. Сверять spacing, color, radius, typography с инспектором. Отклонения >1px → ticket.

## Чек-лист по кластерам

### A — Профиль (текущая ~95%)

- [ ] s-welcome / s-login / s-reg / s-recovery — все 4 состояния (loading/data/error/network).
- [ ] s-profile (hero + меню) — gradients совпадают.
- [ ] s-edit-profile, s-photo-picker — кадрирование квадратом.
- [ ] s-roles, s-add-role, s-rep-rights — чек-лист 13 DomainAction visible.
- [ ] s-language — RU/EN switching.
- [ ] s-notif-settings — disabled-critical с tooltip.
- [ ] s-help, s-faq-detail, s-feedback, s-tool-add, s-tool-detail.

### B — Проекты + Console (текущая ~90%)

- [ ] s-projects (data/loading/empty per role).
- [ ] ProjectCard со светофором + AppHouseProgress + 5 фильтр-чипов.
- [ ] s-create-1/2/3 wizard.
- [ ] s-edit-project, s-copy-project, s-archive (list + empty).
- [ ] s-search.
- [ ] s-console-loading/green/yellow/red/blue/done — 6 состояний.
- [ ] Бюджет на console: progress-bars + overspent badge.
- [ ] Карусель этапов с 4 индикаторами.
- [ ] 8-кнопочная навигационная сетка.
- [ ] s-team, s-team-master (видимость по роли).
- [ ] s-representatives, s-rep-rights-inline.
- [ ] s-tools, s-tools-empty, s-tool-issue, s-tool-return.

### C — Этапы (после Этапа 6.6 ~90%)

- [ ] c-stages-list / c-stages-tile / c-stages-empty / c-stages-loading.
- [ ] Drag-and-drop reorder.
- [ ] 8 состояний этапа (computed display-states).
- [ ] c-stage-create + c-templates + **c-template-preview** (Этап 6.6).
- [ ] c-pause-sheet 4 причины + обязательный комментарий для "other".
- [ ] c-step-detail с подшагами + photo-grid + questions.
- [ ] c-camera, c-gallery, photo_view inline.
- [ ] c-extra-work — auto-approval scope=extra_work.
- [ ] c-stage-docs, c-notifications.

### D — Согласования (после Этапа 5.2 ~95%)

- [ ] d-approvals (filters + count + tabs Active/History).
- [ ] **d-approvals-history stacked-cards** (Этап 5.2): -4px offset + opacity.
- [ ] d-approval-detail со scope-dispatcher (5 типов scope-body).
- [ ] Approve/Reject sheets с обязательным comment-min-10.
- [ ] d-plan-approval (Customer screen для plan).
- [ ] d-deadline-change, d-stage-accept.
- [ ] d-question-reply.
- [ ] Methodology: ETag-cache + FTS-snippet.

### E — Финансы (после Этапа 5.1 ~95%)

- [ ] e-budget per role visibility (master видит свои выплаты).
- [ ] e-budget-stages, e-budget-materials.
- [ ] e-pay-new / pending / confirmed / disputed / dispute / resolve.
- [ ] e-advance + distribute + **overspent блокер** (Этап 6.1).
- [ ] **PaymentDispute photoKeys upload** (Этап 6.2).
- [ ] e-mat-create / detail / checklist / partial / bought / dispute.
- [ ] **Selfpurchase 6 ролевых вариантов** (Этап 5.1):
  - [ ] e-selfpurchase-master (waiting foreman)
  - [ ] e-selfpurchase-foreman (waiting customer)
  - [ ] e-selfpurchase-pending (decision required)
  - [ ] e-selfpurchase-rejected
  - [ ] e-selfpurchase-confirmed
- [ ] e-instruments / issue / return / surrender.

### F — Коммуникации (после Этапа 5.3 ~95%)

- [ ] f-chats, f-chats-empty.
- [ ] f-chat-conversation reverse-list.
- [ ] **15-min edit gate** в long-press menu (Этап 5.4).
- [ ] **f-chat-forward sheet** (Этап 5.3).
- [ ] **f-chat-group-select multi-select** (Этап 5.3).
- [ ] f-chat-attach (photo + document).
- [ ] f-docs, f-doc-detail, f-doc-viewer (PDF inline).
- [ ] f-doc-upload.

## Найденные отклонения (заполнять при QA)

_Формат: `[Кластер][Экран] описание + скриншот`._

- _(Заполнить после ручного прохода)_

## Backlog tickets (P3)

- [ ] Хардкод-строки в Semantics labels — пройти EN-локализацию (см. `L10N_AUDIT.md`).
- [ ] Проверить `AppHouseProgress` glow-shadow на dark mode.
- [ ] Проверить `AppMessageBubble` incoming/outgoing на dark.

## Подпись

QA проведён: __________  
Дата: __________  
Устройство: __________
