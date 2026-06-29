import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// 4 ячейки статистики в шапке детали этапа: % / X из Y / фото / доработки.
///
/// Дизайн c-stage-active: surface n50, border n200, разделители n200.
///
/// Task 1.4 (TZ-фронт §6.2): ячейка «Файлов» заменена на счётчик
/// доработок `reworkOpen/reworkTotal` — приходит из approvals scope=extraWork
/// для этого этапа (pending → open, pending+history → total).
class StageStatsRow extends StatelessWidget {
  const StageStatsRow({
    required this.progressPct,
    required this.progressColor,
    required this.stepsDone,
    required this.stepsTotal,
    required this.photosCount,
    required this.reworkOpen,
    required this.reworkTotal,
    super.key,
  });

  final int progressPct;
  final Color progressColor;
  final int stepsDone;
  final int stepsTotal;
  final int photosCount;
  final int reworkOpen;
  final int reworkTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.surfaceCard,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
        boxShadow: AppShadows.shCard,
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
            _Cell(value: '$reworkOpen/$reworkTotal', label: 'Доработок'),
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
        // Компактная стат-ячейка (Егор 29.06.2026): vertical x8→x4,
        // fontSize 18→15, gap 2→0 — сэкономили ~30px высоты шапки.
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color ?? AppColors.n800,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
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
