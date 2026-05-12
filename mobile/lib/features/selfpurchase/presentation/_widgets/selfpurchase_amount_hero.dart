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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
      child: Column(
        children: [
          Text(
            Money.format(sp.amount),
            style: AppTextStyles.screenTitle.copyWith(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle(sp.status),
            style: AppTextStyles.body.copyWith(
              color: sp.status.semaphore.text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
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
