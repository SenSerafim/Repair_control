import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/payment.dart';

/// Строка выплаты в списке (e-budget Выплаты-tab):
/// [icon-bg по статусу] [name + meta] [amount + status-text].
/// Compact-card (radius 16) с лёгкой тенью sh1.
class PaymentRowCard extends StatelessWidget {
  const PaymentRowCard({
    required this.payment,
    required this.recipientName,
    required this.onTap,
    super.key,
  });

  final Payment payment;
  final String recipientName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semaphore = payment.status.semaphore;
    final statusColor = semaphore.text;
    final iconBg = semaphore.bg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x14,
        ),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                _iconForStatus(payment.status),
                size: 18,
                color: statusColor,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(),
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.n800,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$recipientName · ${_fmtDate(payment.createdAt)}',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.n400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(payment.effectiveAmount),
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.n900,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.status.displayName,
                  style: AppTextStyles.tiny.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title() => switch (payment.kind) {
        PaymentKind.advance => 'Аванс${payment.comment == null ? '' : ': ${payment.comment}'}',
        PaymentKind.distribution =>
          'Распределение${payment.comment == null ? '' : ': ${payment.comment}'}',
        PaymentKind.correction =>
          'Корректировка${payment.comment == null ? '' : ': ${payment.comment}'}',
      };

  IconData _iconForStatus(PaymentStatus s) => switch (s) {
        PaymentStatus.pending => Icons.schedule_rounded,
        PaymentStatus.confirmed => Icons.check_rounded,
        PaymentStatus.disputed => Icons.error_outline_rounded,
        PaymentStatus.resolved => Icons.gavel_rounded,
        PaymentStatus.cancelled => Icons.close_rounded,
      };

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}
