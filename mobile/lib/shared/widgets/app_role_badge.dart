import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum AppRoleBadgeTone {
  customer, // brandLight + brand
  foreman, // greenLight + greenDark
  worker, // purpleBg + purple
  representative, // yellowBg + yellowText
  neutral,
}

/// Цветной pill-бейдж роли с опциональной inline-точкой.
///
/// Дизайн `Кластер F` (`f-team-*`, `f-notes`).
/// CSS-spec: padding 4×10, radius 8, font 11/700; либо 3×8, radius 6, 10/800
/// — переключается через [variant].
class AppRoleBadge extends StatelessWidget {
  const AppRoleBadge({
    required this.label,
    required this.tone,
    this.variant = AppRoleBadgeVariant.standard,
    this.withDot = false,
    super.key,
  });

  final String label;
  final AppRoleBadgeTone tone;
  final AppRoleBadgeVariant variant;
  final bool withDot;

  @override
  Widget build(BuildContext context) {
    final p = _palette(tone);
    final isCompact = variant == AppRoleBadgeVariant.compact;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(isCompact ? 6 : AppRadius.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: p.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: isCompact ? FontWeight.w800 : FontWeight.w700,
              color: p.fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

enum AppRoleBadgeVariant { standard, compact }

class _RolePalette {
  const _RolePalette(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

_RolePalette _palette(AppRoleBadgeTone tone) {
  switch (tone) {
    case AppRoleBadgeTone.customer:
      return const _RolePalette(AppColors.brandLight, AppColors.brand);
    case AppRoleBadgeTone.foreman:
      return const _RolePalette(AppColors.greenLight, AppColors.greenDark);
    case AppRoleBadgeTone.worker:
      return const _RolePalette(AppColors.purpleBg, AppColors.purple);
    case AppRoleBadgeTone.representative:
      return const _RolePalette(AppColors.yellowBg, AppColors.yellowText);
    case AppRoleBadgeTone.neutral:
      return const _RolePalette(AppColors.n100, AppColors.n500);
  }
}
