import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum AppNotifCtaTone {
  /// Brand-blue — основной CTA («Проверить →», «Ответить →»).
  primary,

  /// Зелёный — approve («Одобрить»).
  success,

  /// Красный — reject/dispute («Отклонить», «Разобраться →»).
  danger,

  /// Жёлтый — warning («Посмотреть этап →»).
  warning,

  /// Серый — secondary («Детали выплаты →»).
  secondary,
}

/// Inline-CTA-кнопка в notification-tile из дизайна `Кластер F`
/// (`f-notifications`). 5 цветовых вариантов.
///
/// CSS-spec: padding 4×10, radius 8, font 11/700.
class AppNotifCta extends StatelessWidget {
  const AppNotifCta({
    required this.label,
    required this.onPressed,
    this.tone = AppNotifCtaTone.primary,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final AppNotifCtaTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(tone);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.r8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.bg,
            border: palette.border == null
                ? null
                : Border.all(color: palette.border!, width: 1),
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.fg,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaPalette {
  const _CtaPalette({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
}

_CtaPalette _palette(AppNotifCtaTone tone) {
  switch (tone) {
    case AppNotifCtaTone.primary:
      return const _CtaPalette(bg: AppColors.brand, fg: AppColors.n0);
    case AppNotifCtaTone.success:
      return const _CtaPalette(bg: AppColors.greenDark, fg: AppColors.n0);
    case AppNotifCtaTone.danger:
      return const _CtaPalette(
        bg: AppColors.redBg,
        fg: AppColors.redDot,
        border: Color(0xFFFECACA),
      );
    case AppNotifCtaTone.warning:
      return const _CtaPalette(
        bg: AppColors.yellowBg,
        fg: AppColors.yellowText,
        border: Color(0xFFFCD34D),
      );
    case AppNotifCtaTone.secondary:
      return const _CtaPalette(bg: AppColors.n100, fg: AppColors.n600);
  }
}
