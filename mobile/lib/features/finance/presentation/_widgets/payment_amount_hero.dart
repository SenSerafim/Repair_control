import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/payment.dart';

/// Hero для PaymentDetailScreen: центрированная крупная сумма + sub-text
/// с типом платежа. В упрощённой модели (2026-05-12) платёж = факт
/// передачи денег, статусов больше нет.
class PaymentAmountHero extends StatelessWidget {
  const PaymentAmountHero({required this.payment, super.key});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x24),
      child: Column(
        children: [
          Text(
            Money.format(payment.amount),
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.n900,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            payment.kind.displayName,
            style: AppTextStyles.body.copyWith(
              color: AppColors.n500,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
