import 'package:flutter/material.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../domain/budget.dart';

/// Плашка бюджетного bucket'а — planned / spent / remaining + progress.
class BudgetBucketCard extends StatelessWidget {
  const BudgetBucketCard({
    required this.title,
    required this.bucket,
    this.icon,
    this.accentColor = AppColors.brand,
    super.key,
  });

  final String title;
  final BudgetBucket bucket;
  final IconData? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final overSpent = bucket.overSpent;
    final progressColor =
        overSpent ? AppColors.redDot : accentColor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.x10),
              ],
              Expanded(
                child: Text(title, style: AppTextStyles.subtitle),
              ),
              if (overSpent)
                const _OverBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Money.format(bucket.spent),
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 22,
                  color: overSpent ? AppColors.redDot : AppColors.n800,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ' / ${Money.format(bucket.planned)}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: bucket.progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Text(
                'Осталось ${Money.format(bucket.remaining)}',
                style: AppTextStyles.caption.copyWith(
                  color: overSpent ? AppColors.redDot : AppColors.n500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverBadge extends StatelessWidget {
  const _OverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Перерасход',
        style: AppTextStyles.tiny.copyWith(color: AppColors.redText),
      ),
    );
  }
}

/// Строка этапа в бюджете — компактный вид.
class StageBudgetRow extends StatelessWidget {
  const StageBudgetRow({
    required this.stageBudget,
    required this.onTap,
    super.key,
  });

  final StageBudget stageBudget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = stageBudget.total;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stageBudget.title,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  Money.format(total.spent),
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Из ${Money.format(total.planned)} · ${(total.progress * 100).round()}%',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.x8),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: total.overSpent
                        ? AppColors.redDot
                        : AppColors.brand,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
