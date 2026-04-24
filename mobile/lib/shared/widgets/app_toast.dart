import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

enum AppToastKind { success, error, info }

/// Тост-уведомление. Анимация toastIn (translateY 20→0, opacity 0→1, 300мс).
class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    AppToastKind kind = AppToastKind.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final spec = _spec(kind);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x16,
              vertical: AppSpacing.x12,
            ),
            decoration: BoxDecoration(
              color: spec.background,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              boxShadow: AppShadows.sh3,
            ),
            child: Row(
              children: [
                Icon(spec.icon, color: AppColors.n0, size: 20),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.body.copyWith(color: AppColors.n0),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  static ({Color background, IconData icon}) _spec(AppToastKind kind) {
    return switch (kind) {
      AppToastKind.success => (
          background: const Color(0xFF065F46),
          icon: Icons.check_circle_outline_rounded,
        ),
      AppToastKind.error => (
          background: AppColors.redText,
          icon: Icons.error_outline_rounded,
        ),
      AppToastKind.info => (
          background: AppColors.n800,
          icon: Icons.info_outline_rounded,
        ),
    };
  }
}
