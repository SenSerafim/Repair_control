import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Нижняя навигация по мотивам `.bnav` из HTML-макетов:
/// - фон с полупрозрачным blur
/// - активная иконка brand, неактивная — n400
/// - индикатор-точка под активным табом (gradient + glow)
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
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0D1229),
            offset: Offset(0, -1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x0A0D1229),
            offset: Offset(0, -8),
            blurRadius: 24,
          ),
        ],
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
  const _Item({required this.item, required this.active, required this.onTap});

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
                AnimatedSlide(
                  duration: AppDurations.normal,
                  curve: AppCurves.spring,
                  offset: active ? const Offset(0, -0.04) : Offset.zero,
                  child: Icon(item.icon, size: 22, color: color),
                ),
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
              duration: AppDurations.normal,
              curve: AppCurves.spring,
              scale: active ? 1.0 : 0.0,
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brandMid, AppColors.brand],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x294F6EF7),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: Color(0x4D4F6EF7),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
