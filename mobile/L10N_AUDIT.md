# L10N Audit — Mobile

Документ Этапа 2 ROAD_TO_100. Источник: `grep -rE "Text\(['\"][А-Яа-яЁё]" lib/features/`.

## Сводка

- **60** прямых хардкод-Text-строк в `lib/features/` (на 2026-04-25).
- Дополнительно ~350 строк в conditional/builder контекстах (snackbar, exception userMessage, validators) — посчитаны отдельной выборкой.
- ARB на момент аудита: **22 ключа** (`auth_*`, `nav_*`, `error_*`, `common_*`).
- После расширения в этапе 2 ARB содержит **~180 ключей** (см. `app_ru.arb`/`app_en.arb`).

## По кластерам (распределение хардкода)

| Кластер | Файлов | Примеры |
|---|---|---|
| projects | 10 | «Создать проект», «Архив», «Адрес» |
| steps | 9 | «Шаг готов», «Подшаги», «Прикрепить фото» |
| materials | 8 | «Материалы», «Куплено», «Дополнить» |
| finance | 7 | «Бюджет», «Аванс», «Распределить» |
| auth | 7 | «Войти», «Зарегистрироваться» |
| team | 4 | «Бригадир», «Мастер», «Удалить» |
| stages | 4 | «Этап», «Старт», «Пауза» |
| approvals | 3 | «Согласование», «Отклонить», «Одобрить» |
| tools | 2 | «Инструмент» |
| selfpurchase | 2 | «Самозакуп» |
| profile | 2 | «Профиль», «Выйти» |
| notes | 1 | «Заметки» |
| chat | 1 | «Чат» |

## Стратегия

1. **Этап 2 (этот PR)** — заполнить ARB ключевыми разделами; заменить хардкод в auth + profile + navigation + errors + finance.
2. **Этап 7 (Pixel-perfect QA)** — заменить оставшиеся 30+ хардкодов в прочих экранах.

## Ключевые группы добавленных ARB-ключей

```
auth_*           login/register/recovery (расширено)
profile_*        edit, language, theme, tools
projects_*       list/create/edit/archive/copy
stages_*         create/start/pause/review/done/overdue
approvals_*      list/decide/reject/extra
finance_*        budget/payment/dispute/advance/distribute
materials_*      create/items/finalize
chat_*           messages/forward/edit
documents_*      upload/category/list
notifications_*  list/empty/types
errors_*         (расширено над error_network_title)
common_*         retry/cancel/save/close/submit/delete
```

## Что НЕ закрыто этим этапом

Хардкод в:
- `lib/features/{steps,materials,tools,team,stages}/presentation/` — текст на конкретных экранах.
- snackbar/exception `userMessage` — резерв Этапа 7 + покрытие через `errors_*` ARB.
- Semantics-labels — отдельный pass под Этап 7 (a11y).

## Команда регрессии

```bash
grep -rnE "Text\(['\"][А-Яа-яЁё]" mobile/lib/features/ | wc -l
```

После Этапа 2 ожидаемо: ≤30. После Этапа 7: ≤5 (только специальные строки типа Money formatting).
