import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Круглый чекбокс шага с анимированным переходом + green glow при checked.
/// Дизайн `Кластер C` step-check:
/// - 24×24, border-radius 50%
/// - unchecked: border 2px `n300`
/// - checked: bg `#10B981`, border transparent, shadow `0 2px 6px rgba(16,185,129,0.25)`
/// - transition: 0.15s
class AppStepCheckbox extends StatelessWidget {
  const AppStepCheckbox({
    required this.checked,
    this.onTap,
    this.size = 24,
    super.key,
  });

  final bool checked;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? AppColors.greenDot : AppColors.n0,
          shape: BoxShape.circle,
          border: checked
              ? null
              : Border.all(color: AppColors.n300, width: 2),
          boxShadow: checked ? AppShadows.glowGreen : null,
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: checked
              ? Icon(
                  Icons.check_rounded,
                  size: size * 0.6,
                  color: AppColors.n0,
                  key: const ValueKey('checked'),
                )
              : SizedBox.shrink(key: ValueKey('unchecked-$size')),
        ),
      ),
    );
  }
}
