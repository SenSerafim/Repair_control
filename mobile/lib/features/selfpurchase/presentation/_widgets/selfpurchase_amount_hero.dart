import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/self_purchase.dart';

/// Большой centered hero для SelfPurchaseDetailScreen — сумма + status-text.
class SelfPurchaseAmountHero extends StatelessWidget {
  const SelfPurchaseAmountHero({required this.sp, super.key});

  final SelfPurchase sp;

  @override
  Widget build(BuildContext context) {
    final color = _amountColor(sp.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
      child: Column(
        children: [
          Text(
            Money.format(sp.amount),
            style: AppTextStyles.screenTitle.copyWith(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(sp.status),
            style: AppTextStyles.body.copyWith(
              color: sp.status.semaphore.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _amountColor(SelfPurchaseStatus s) => switch (s) {
        SelfPurchaseStatus.pending => AppColors.n900,
        SelfPurchaseStatus.approved => AppColors.greenDark,
        SelfPurchaseStatus.rejected => AppColors.redDot,
      };

  String _subtitle(SelfPurchaseStatus s) => switch (s) {
        SelfPurchaseStatus.pending => 'Ожидает подтверждения',
        SelfPurchaseStatus.approved => 'Самозакуп подтверждён',
        SelfPurchaseStatus.rejected => 'Самозакуп отклонён',
      };
}
