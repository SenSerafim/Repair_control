import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Спецификация одного фильтр-чипа Cluster F.
class AppFilterPillSpec {
  const AppFilterPillSpec({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
}

/// Bar пилл-чипов из дизайна `Кластер F`.
///
/// Отличается от `AppFilterChips`: inactive — `n0 bg + 1.5px n200 border`,
/// active — `gradient brandButton + n0 text`. Без счётчика.
/// Использовать в feed/notifications/documents-upload-categories.
class AppFilterPillBar extends StatelessWidget {
  const AppFilterPillBar({
    required this.chips,
    required this.activeId,
    required this.onSelect,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    super.key,
  });

  final List<AppFilterPillSpec> chips;
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
            if (i > 0) const SizedBox(width: 6),
            AppFilterPill(
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

class AppFilterPill extends StatelessWidget {
  const AppFilterPill({
    required this.spec,
    required this.active,
    required this.onTap,
    super.key,
  });

  final AppFilterPillSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.n0 : AppColors.n600;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? null : AppColors.n0,
            gradient: active ? AppGradients.brandButton : null,
            border: active
                ? null
                : Border.all(color: AppColors.n200, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
