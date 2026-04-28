import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Полупрозрачный белый pill с иконкой роли + названием + caret-down.
///
/// Используется в hero-блоке Profile (`s-profile`) — клик открывает
/// `/profile/roles` для переключения активной роли.
class AppRoleChip extends StatelessWidget {
  const AppRoleChip({
    required this.label,
    required this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteGhost,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.n0),
              const SizedBox(width: AppSpacing.x6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n0,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              const Icon(
                PhosphorIconsRegular.caretDown,
                size: 12,
                color: AppColors.n0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
