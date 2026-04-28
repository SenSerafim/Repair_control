import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Стандартные причины отклонения самозакупа (e-selfpurchase-reject).
enum RejectReason {
  notAgreed('not_agreed', Icons.highlight_off_rounded, 'Не согласована закупка'),
  overpriced('overpriced', Icons.trending_up_rounded, 'Завышена цена'),
  noReceipt('no_receipt', Icons.receipt_long_outlined, 'Нет чека / плохое фото'),
  other('other', Icons.edit_outlined, 'Другая причина');

  const RejectReason(this.apiValue, this.icon, this.label);

  final String apiValue;
  final IconData icon;
  final String label;
}

/// Список 4 radio-card. Selected — destructive-вариант (red border + redBg).
class RejectReasonsPicker extends StatelessWidget {
  const RejectReasonsPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final RejectReason selected;
  final ValueChanged<RejectReason> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in RejectReason.values) ...[
          _Tile(
            reason: r,
            selected: selected == r,
            onTap: () => onChanged(r),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final RejectReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.redBg : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.redDot : AppColors.n200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(
              reason.icon,
              size: 16,
              color: selected ? AppColors.redDot : AppColors.n500,
            ),
            const SizedBox(width: AppSpacing.x10),
            Text(
              reason.label,
              style: AppTextStyles.subtitle.copyWith(
                color: selected ? AppColors.redText : AppColors.n700,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
