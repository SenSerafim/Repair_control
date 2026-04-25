import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Линейный прогресс с gradient-fill из дизайна `Кластер E` budget.
///
/// CSS:
/// - height: 4-5px
/// - track bg: n100 (#F1F4FD)
/// - fill: linear-gradient(90deg, …)
/// - radii: 2-3px
///
/// 4 палитры:
/// - green: `#34D399 → #059669`
/// - yellow: `#FEF08A → #FBBF24`
/// - blue: `brandMid → brand` (#6B83F5 → #4F6EF7)
/// - red (overspent): `#F87171 → #DC2626`
enum ProgressPalette {
  green,
  yellow,
  blue,
  red;

  List<Color> get colors => switch (this) {
        ProgressPalette.green => const [Color(0xFF34D399), Color(0xFF059669)],
        ProgressPalette.yellow => const [Color(0xFFFEF08A), Color(0xFFFBBF24)],
        ProgressPalette.blue => const [Color(0xFF6B83F5), AppColors.brand],
        ProgressPalette.red => const [Color(0xFFF87171), Color(0xFFDC2626)],
      };
}

class AppGradientProgressBar extends StatelessWidget {
  const AppGradientProgressBar({
    required this.progress,
    this.palette = ProgressPalette.blue,
    this.height = 5,
    this.overspentThreshold = 1.0,
    super.key,
  });

  /// 0..1 (overspent — > 1 заваливается в красный, см. [overspentThreshold]).
  final double progress;
  final ProgressPalette palette;
  final double height;

  /// При progress > этого порога — автоматически переключаем палитру на red,
  /// игнорируя [palette]. Для бюджета `1.0` означает «потрачено больше плана».
  final double overspentThreshold;

  @override
  Widget build(BuildContext context) {
    final overspent = progress > overspentThreshold;
    final colors =
        overspent ? ProgressPalette.red.colors : palette.colors;
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: AppColors.n100,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}
