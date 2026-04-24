import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Базовая карточка списка. Соответствует `.stg`/`.step-item` из макетов:
/// padding 14, radius 16, border n200 1.5px, shadow sh1.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardInset,
    this.accentColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  /// Цвет 3px-верхней полосы (::before у `.stg`). null = без полосы.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppDurations.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
        boxShadow: AppShadows.sh1,
      ),
      child: accentColor == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: AppSpacing.x10),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child,
              ],
            ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
