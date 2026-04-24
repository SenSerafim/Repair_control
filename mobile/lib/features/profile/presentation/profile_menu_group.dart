import 'package:flutter/material.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';

/// Группа меню (prof-group из макетов): белая карточка с вложенными ячейками.
class ProfileMenuGroup extends StatelessWidget {
  const ProfileMenuGroup({required this.items, super.key});

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: Divider(height: 1, color: AppColors.n100),
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: BorderRadius.circular(AppRadius.r20),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(children: children),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.hint,
    this.onTap,
    this.isDestructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.redDot : AppColors.n700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDestructive ? AppColors.redBg : AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive ? AppColors.redDot : AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.subtitle.copyWith(color: color),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(hint!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n300,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
