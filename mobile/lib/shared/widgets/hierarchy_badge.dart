import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Бейдж иерархии отчётности (P1.4): «{from} ({fromRole}) → {to} ({toRole})  [статус]».
///
/// Используется на детальных экранах: step_detail, stage_detail, approval_detail,
/// payment_detail, selfpurchase_detail. Делает явной цепочку master → foreman → customer.
///
/// Дизайн: компактная плашка с иконкой человека, стрелкой и StatusPill.
class HierarchyBadge extends StatelessWidget {
  const HierarchyBadge({
    super.key,
    required this.from,
    required this.fromRole,
    required this.to,
    required this.toRole,
    required this.status,
    this.semaphore,
  });

  /// Имя инициатора (например, «Иван И.»).
  final String from;

  /// Роль инициатора (например, «Мастер»).
  final String fromRole;

  /// Имя адресата.
  final String to;

  /// Роль адресата.
  final String toRole;

  /// Текст статуса (например, «Ожидает проверки»).
  final String status;

  /// Семафорный цвет статуса. По умолчанию — yellow (pending/в процессе).
  final Semaphore? semaphore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: AppColors.n500,
          ),
          const SizedBox(width: AppSpacing.x6),
          Flexible(
            child: Text(
              '$from · $fromRole',
              style: AppTextStyles.micro,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.n400,
            ),
          ),
          Flexible(
            child: Text(
              '$to · $toRole',
              style: AppTextStyles.micro,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          StatusPill(
            label: status,
            semaphore: semaphore ?? Semaphore.yellow,
            showDot: false,
          ),
        ],
      ),
    );
  }
}
