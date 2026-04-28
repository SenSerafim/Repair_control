import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// dl-rows карточка метаданных заявки (этап / ответственный / поставщик).
/// e-mat-detail (нижняя часть после lifecycle).
class MaterialMetaCard extends StatelessWidget {
  const MaterialMetaCard({required this.rows, super.key});

  final List<MaterialMetaRow> rows;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      widgets.add(_render(rows[i]));
      if (i < rows.length - 1) {
        widgets.add(const SizedBox(height: AppSpacing.x8));
      }
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
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

  Widget _render(MaterialMetaRow row) {
    return Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n500,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          row.value,
          style: AppTextStyles.tiny.copyWith(
            color: row.valueColor ?? AppColors.n800,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class MaterialMetaRow {
  const MaterialMetaRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}
