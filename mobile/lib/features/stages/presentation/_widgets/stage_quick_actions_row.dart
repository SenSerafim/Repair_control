import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';

/// NEWFIX Task 2.2 — фиксированный ряд из двух кнопок на экране этапа.
/// TZ-фронт §6: «💬 Чат этапа» + «₽ Бюджет этапа» располагаются между
/// исполнителями (StageExecutorsRow) и табами (StageTabsBar).
///
/// Зачем отдельный виджет: до этой ревизии «Бюджет этапа» жил в `actions`
/// шапки (Icon-кнопкой ₽), а чат этапа открывался кружным путём через
/// сводный список чатов проекта из status-баннера. Оба входа были
/// сильно неравнозначны — бюджет терялся в шапке, чат был доступен только
/// из конкретных состояний этапа. Дублируем оба действия здесь, чтобы:
///   1) точка входа в чат этапа была статичной (а не зависела от
///      overdue-баннера),
///   2) бюджет получил видимую CTA-кнопку и его иконку из шапки можно
///      было убрать без потери функциональности.
///
/// Виджет состояния не держит — оба колбэка прокидывает родитель.
class StageQuickActionsRow extends StatelessWidget {
  const StageQuickActionsRow({
    required this.onOpenChat,
    required this.onOpenBudget,
    super.key,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        0,
        AppSpacing.x16,
        AppSpacing.x12,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              key: const ValueKey('stage_quick_chat_button'),
              label: 'Чат этапа',
              icon: PhosphorIconsRegular.chatCircle,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.sm,
              onPressed: onOpenChat,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: AppButton(
              key: const ValueKey('stage_quick_budget_button'),
              label: 'Бюджет этапа',
              icon: PhosphorIconsRegular.currencyRub,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.sm,
              onPressed: onOpenBudget,
            ),
          ),
        ],
      ),
    );
  }
}
