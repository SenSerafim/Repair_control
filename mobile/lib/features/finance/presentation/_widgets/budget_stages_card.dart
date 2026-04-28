import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/budget.dart';

/// Список этапов в табе «По этапам» (e-budget-stages):
/// единая card-обёртка с разделителями. Каждая строка — title + статус-точка,
/// сумма spent, sub «из planned».
class BudgetStagesCard extends StatelessWidget {
  const BudgetStagesCard({
    required this.stages,
    required this.statusByStageId,
    required this.onStageTap,
    super.key,
  });

  final List<StageBudget> stages;

  /// Маппинг stageId → (label, color) для статус-точки рядом с названием.
  /// Если null — точка не рисуется.
  final Map<String, StageStatusBadge> statusByStageId;
  final ValueChanged<String> onStageTap;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < stages.length; i++)
            _Row(
              stage: stages[i],
              status: statusByStageId[stages[i].stageId],
              divider: i < stages.length - 1,
              onTap: () => onStageTap(stages[i].stageId),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.stage,
    required this.divider,
    required this.onTap,
    this.status,
  });

  final StageBudget stage;
  final bool divider;
  final VoidCallback onTap;
  final StageStatusBadge? status;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x14,
        ),
        decoration: BoxDecoration(
          border: divider
              ? const Border(
                  bottom: BorderSide(color: AppColors.n100),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.n900,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status!.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status!.label,
                          style: AppTextStyles.tiny.copyWith(
                            color: status!.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(stage.work.spent + stage.materials.spent),
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.n900,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'из ${Money.formatCompact(stage.total.planned)}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StageStatusBadge {
  const StageStatusBadge(this.label, this.color);
  final String label;
  final Color color;

  static const done = StageStatusBadge('Завершён', AppColors.greenDark);
  static const active = StageStatusBadge('В работе', AppColors.brand);
  static const paused = StageStatusBadge('На паузе', AppColors.yellowText);
  static const review = StageStatusBadge('На проверке', AppColors.purple);
  static const pending = StageStatusBadge('Запланирован', AppColors.n400);
}
