import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../domain/payment.dart';

/// Карточка выплаты в списке — упрощённая модель (2026-05-12):
/// иконка + цвет фона по `PaymentKind`, без status-pill.
class PaymentCard extends StatelessWidget {
  const PaymentCard({required this.payment, required this.onTap, super.key});

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (iconColor, iconBg) = _kindStyle(payment.kind);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: 'payment-${payment.id}',
        flightShuttleBuilder: (_, __, dir, fromCtx, toCtx) {
          final hero =
              (dir == HeroFlightDirection.push ? fromCtx : toCtx).widget
                  as Hero;
          return hero.child;
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.n200, width: 1.5),
              boxShadow: AppShadows.sh1,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: const Border(
                      top: BorderSide(
                        color: AppShadows.innerHighlight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Icon(payment.kind.icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payment.kind.displayName,
                              style: AppTextStyles.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            Money.format(payment.amount),
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.n900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM HH:mm', 'ru').format(
                          payment.createdAt,
                        ),
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.n300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _kindStyle(PaymentKind k) => switch (k) {
    PaymentKind.advance => (AppColors.brand, AppColors.brandLight),
    PaymentKind.distribution => (AppColors.greenDark, AppColors.greenLight),
    PaymentKind.correction => (AppColors.n700, AppColors.n100),
  };
}
