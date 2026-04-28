import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Шаговый индикатор (3 точки/тире) — Recovery 1→2→3 и любой 2-3-step wizard.
///
/// Дизайн `Кластер A` (s-recovery-phone / s-recovery / s-recovery-newpass):
/// — высота 4, gap 6, radius 2; неактивная n200, активная brand 28pt, done brand 24pt.
class AppStepDots extends StatelessWidget {
  const AppStepDots({
    required this.total,
    required this.current,
    super.key,
  });

  /// Сколько всего шагов (обычно 3).
  final int total;

  /// 0-based индекс активного шага.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        final width = isActive ? 28.0 : 24.0;
        final color = (isActive || isDone) ? AppColors.brand : AppColors.n200;
        return Padding(
          padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            width: width,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
