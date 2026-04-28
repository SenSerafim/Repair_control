import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Per-person filter chips для tool_issuances_screen.
/// Опционально дёргает «green-dot indicator» (e-instruments-after) — для
/// пользователя, выданного в текущей сессии.
class ToolFilterBar extends StatelessWidget {
  const ToolFilterBar({
    required this.persons,
    required this.selected,
    required this.onChanged,
    this.recentlyAddedIds = const {},
    super.key,
  });

  /// Список (id, label). null id = «Все», специальное значение «warehouse» для
  /// inventory-режима.
  final List<({String? id, String label})> persons;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final Set<String> recentlyAddedIds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: persons.length,
        itemBuilder: (_, i) {
          final p = persons[i];
          final active = selected == p.id;
          final isRecent = p.id != null && recentlyAddedIds.contains(p.id);
          return _Chip(
            label: p.label,
            active: active,
            recent: isRecent,
            onTap: () => onChanged(p.id),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.recent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool recent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.brand
        : (recent ? AppColors.greenLight : AppColors.n0);
    final fg = active
        ? AppColors.n0
        : (recent ? AppColors.greenDark : AppColors.n600);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : (recent
                        ? const Color(0xFFA7F3D0)
                        : AppColors.n200),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: active ? AppShadows.shBlue : null,
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (recent)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.greenDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.n0, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
