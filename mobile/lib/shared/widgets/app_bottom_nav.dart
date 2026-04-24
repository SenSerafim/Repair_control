import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Нижняя навигация по мотивам `.bnav` из HTML-макетов:
/// - фон с полупрозрачным blur
/// - активная иконка brand, неактивная — n400
/// - индикатор-точка под активным табом
/// - опциональный бэйдж непрочитанных (красный dot с цифрой)
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _Item(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : AppColors.n400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 22, color: color),
                if (item.badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.redDot,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.n0, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                        style: const TextStyle(
                          color: AppColors.n0,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTextStyles.tiny.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: active ? 1.0 : 0.0,
              alignment: Alignment.center,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
