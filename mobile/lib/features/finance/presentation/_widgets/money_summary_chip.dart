import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';

/// Sub-summary chip-card для табов бюджета (e-budget): brandLight-фон,
/// слева — итоговая сумма, справа — раскладка confirmed/pending/selfpurchase.
class MoneySummaryChip extends StatelessWidget {
  const MoneySummaryChip({
    required this.title,
    required this.total,
    this.confirmed,
    this.pending,
    this.selfPurchase,
    super.key,
  });

  final String title;
  final int total;

  /// Подтверждённые — зелёный.
  final int? confirmed;

  /// Ожидающие — жёлтый.
  final int? pending;

  /// Самозакуп — brand.
  final int? selfPurchase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Money.format(total),
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (confirmed != null && confirmed! > 0)
                _Line(
                  label: 'Подтверждено',
                  amount: confirmed!,
                  color: AppColors.greenDark,
                ),
              if (pending != null && pending! > 0) ...[
                const SizedBox(height: 2),
                _Line(
                  label: 'Ожидает',
                  amount: pending!,
                  color: AppColors.yellowText,
                ),
              ],
              if (selfPurchase != null && selfPurchase! > 0) ...[
                const SizedBox(height: 2),
                _Line(
                  label: 'Самозакуп',
                  amount: selfPurchase!,
                  color: AppColors.brand,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${Money.format(amount)}',
      style: AppTextStyles.tiny.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    );
  }
}
