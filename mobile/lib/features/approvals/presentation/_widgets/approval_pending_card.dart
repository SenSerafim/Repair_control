import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/approval.dart';

/// Pending-карточка согласования — c-stage-approval (yellow card).
///
/// Yellow surface (#FFFBEB) + yellow border, заголовок с иконкой/типом, sum
/// (для extra_work / payment-связанных), автор + дата, две кнопки 36px:
/// success «Одобрить» и destructive «Отклонить».
class ApprovalPendingCard extends StatelessWidget {
  const ApprovalPendingCard({
    required this.approval,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final Approval approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'ru');
    final amount = _amountKopecks();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.yellowText,
              ),
              const SizedBox(width: AppSpacing.x6),
              Expanded(
                child: Text(
                  '${approval.scope.displayName}: ${_titleHint()}',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.yellowText,
                  ),
                ),
              ),
            ],
          ),
          if (amount != null) ...[
            const SizedBox(height: AppSpacing.x6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Сумма: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.n600,
                    ),
                  ),
                  TextSpan(
                    text: Money.format(amount),
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.n900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Запрос от ${df.format(approval.createdAt)}',
            style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Одобрить',
                  variant: AppButtonVariant.success,
                  size: AppButtonSize.sm,
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: AppButton(
                  label: 'Отклонить',
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleHint() {
    final p = approval.payload;
    if (p['title'] is String) return p['title'] as String;
    if (p['stepTitle'] is String) return p['stepTitle'] as String;
    return approval.scope.shortHint;
  }

  int? _amountKopecks() {
    final p = approval.payload;
    final raw = p['priceKopecks'] ?? p['amount'] ?? p['price'];
    if (raw is num) return raw.toInt();
    return null;
  }
}
