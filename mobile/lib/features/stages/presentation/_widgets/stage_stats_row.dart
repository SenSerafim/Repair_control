import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// 4 ячейки статистики в шапке детали этапа: % / X из Y / фото / файлы.
///
/// Дизайн c-stage-active: surface n50, border n200, разделители n200.
class StageStatsRow extends StatelessWidget {
  const StageStatsRow({
    required this.progressPct,
    required this.progressColor,
    required this.stepsDone,
    required this.stepsTotal,
    required this.photosCount,
    required this.filesCount,
    super.key,
  });

  final int progressPct;
  final Color progressColor;
  final int stepsDone;
  final int stepsTotal;
  final int photosCount;
  final int filesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
        boxShadow: AppShadows.sh1,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _Cell(
              value: '$progressPct%',
              label: 'Готово',
              color: progressColor,
            ),
            const _Divider(),
            _Cell(value: '$stepsDone/$stepsTotal', label: 'Шагов'),
            const _Divider(),
            _Cell(value: '$photosCount', label: 'Фото'),
            const _Divider(),
            _Cell(value: '$filesCount', label: 'Файлов'),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color ?? AppColors.n800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.tiny),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: AppColors.n100);
  }
}
