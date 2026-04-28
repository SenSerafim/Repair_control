import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Карточка-ряд языка: флаг (emoji) + label + sub + чекбокс справа.
///
/// Дизайн `Кластер A` (s-language / s-language-en).
class AppFlagCheckbox extends StatelessWidget {
  const AppFlagCheckbox({
    required this.flag,
    required this.label,
    required this.sub,
    required this.selected,
    this.onTap,
    super.key,
  });

  /// Emoji-флаг (🇷🇺 / 🇬🇧).
  final String flag;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.n200,
              width: selected ? 2 : 1,
            ),
            borderRadius: AppRadius.card,
            color: selected ? AppColors.brandLight : AppColors.n0,
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
              _Check(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.n300,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: selected
          ? const Icon(
              PhosphorIconsBold.check,
              size: 12,
              color: AppColors.n0,
            )
          : null,
    );
  }
}
