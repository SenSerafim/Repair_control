import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/payment.dart';

/// Hero для PaymentDetailScreen (e-pay-pending/confirmed/disputed):
/// центрированная крупная сумма + sub-text с цветом по статусу.
class PaymentAmountHero extends StatelessWidget {
  const PaymentAmountHero({required this.payment, super.key});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final color = _amountColor(payment.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
      child: Column(
        children: [
          Text(
            Money.format(payment.effectiveAmount),
            style: AppTextStyles.screenTitle.copyWith(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(payment.status),
            style: AppTextStyles.body.copyWith(
              color: payment.status.semaphore.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (payment.resolvedAmount != null &&
              payment.resolvedAmount != payment.amount) ...[
            const SizedBox(height: 6),
            Text(
              'Изначально было ${Money.format(payment.amount)}',
              style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
            ),
          ],
        ],
      ),
    );
  }

  Color _amountColor(PaymentStatus s) => switch (s) {
        PaymentStatus.pending => AppColors.n900,
        PaymentStatus.confirmed => AppColors.greenDark,
        PaymentStatus.disputed => AppColors.redDot,
        PaymentStatus.resolved => AppColors.n800,
        PaymentStatus.cancelled => AppColors.n400,
      };

  String _subtitle(PaymentStatus s) => switch (s) {
        PaymentStatus.pending => 'Ожидает подтверждения подрядчика',
        PaymentStatus.confirmed => 'Обе стороны подтвердили',
        PaymentStatus.disputed => 'Выплата оспорена',
        PaymentStatus.resolved => 'Спор разрешён',
        PaymentStatus.cancelled => 'Отменено',
      };
}
