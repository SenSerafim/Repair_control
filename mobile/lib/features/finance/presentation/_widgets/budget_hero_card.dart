import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/budget.dart';

/// Hero-карточка проекта (e-budget): крупная сумма «Общий бюджет · план»,
/// строка «Потрачено / Остаток», цветной градиент-progress + 2 mini-card
/// (Работы / Материалы) с собственными progress-полосками.
class BudgetHeroCard extends StatelessWidget {
  const BudgetHeroCard({
    required this.total,
    required this.work,
    required this.materials,
    super.key,
  });

  final BudgetBucket total;
  final BudgetBucket work;
  final BudgetBucket materials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        gradient: AppGradients.surfaceCard,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
        boxShadow: AppShadows.shCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ОБЩИЙ БЮДЖЕТ · ПЛАН',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n400,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Money.format(total.planned),
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.n900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Text(
                'Потрачено: ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.n500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                Money.format(total.spent),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.n900,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.x16),
              Text(
                'Остаток: ',
                style: AppTextStyles.caption.copyWith(
                  color: total.overSpent
                      ? AppColors.redText
                      : AppColors.greenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                Money.format(total.remaining),
                style: AppTextStyles.caption.copyWith(
                  color: total.overSpent
                      ? AppColors.redText
                      : AppColors.greenDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          // Gradient progress bar — brand → green-mid (как в дизайне).
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: total.progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: total.overSpent
                      ? const LinearGradient(
                          colors: [AppColors.redDot, AppColors.redText],
                        )
                      : const LinearGradient(
                          colors: [AppColors.brand, AppColors.greenDot],
                        ),
                  borderRadius: BorderRadius.circular(3),
                  border: const Border(
                    top: BorderSide(color: AppShadows.innerHighlight, width: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Работы',
                  bucket: work,
                  fillColor: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: _MiniCard(
                  label: 'Материалы',
                  bucket: materials,
                  fillColor: AppColors.greenDot,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.bucket,
    required this.fillColor,
  });

  final String label;
  final BudgetBucket bucket;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final color = bucket.overSpent ? AppColors.redDot : fillColor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        gradient: AppGradients.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n400,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: Money.formatCompact(bucket.spent),
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 16,
                    color: AppColors.n900,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: ' / ${Money.formatCompact(bucket.planned)}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: bucket.progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: const Border(
                    top: BorderSide(color: AppShadows.innerHighlight, width: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Остаток: ${Money.format(bucket.remaining)}',
            style: AppTextStyles.tiny.copyWith(
              color: bucket.overSpent ? AppColors.redText : AppColors.greenDark,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
