import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Спецификация одного фильтр-чипа.
class AppFilterChipSpec {
  const AppFilterChipSpec({
    required this.id,
    required this.label,
    this.icon,
    this.count,
  });

  final String id;
  final String label;
  final IconData? icon;
  final int? count;
}

/// Горизонтальный SingleChildScrollView с pill-чипами фильтров.
///
/// Дизайн `Кластер B` (s-search): активный = синий gradient, неактивный
/// = n100 фон + n700 текст. Опционально иконка-префикс и числовой счётчик.
class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    required this.chips,
    required this.activeId,
    required this.onSelect,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.x16, vertical: 8),
    super.key,
  });

  final List<AppFilterChipSpec> chips;
  final String activeId;
  final ValueChanged<String> onSelect;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.x6),
            _Chip(
              spec: chips[i],
              active: chips[i].id == activeId,
              onTap: () => onSelect(chips[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final AppFilterChipSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? null : AppColors.n100;
    final fg = active ? AppColors.n0 : AppColors.n700;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: bg,
            gradient: active ? AppGradients.brandButton : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: active ? AppShadows.shBlue : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spec.icon != null) ...[
                Icon(spec.icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                spec.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -0.1,
                ),
              ),
              if (spec.count != null && spec.count! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.n0.withValues(alpha: 0.25)
                        : AppColors.n0,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${spec.count}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: active ? AppColors.n0 : AppColors.n600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
