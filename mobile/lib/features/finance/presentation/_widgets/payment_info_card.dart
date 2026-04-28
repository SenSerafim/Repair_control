import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Универсальная dl-rows карточка для выплаты/материала/самозакупа.
/// Каждый ряд: [label слева — серый, value справа — n800 bold; цвет value
/// можно переопределить для статус-полей].
class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({required this.rows, super.key});

  final List<PaymentInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      widgets.add(_render(rows[i]));
      if (i < rows.length - 1) {
        widgets.add(const SizedBox(height: AppSpacing.x10));
      }
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }

  Widget _render(PaymentInfoRow row) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.n500,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: row.valueColor ?? AppColors.n800,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentInfoRow {
  const PaymentInfoRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}
