import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;

import '../../core/theme/tokens.dart';

/// Анимированная кнопка отправки сообщения. Показывает send → check,
/// с плавной заменой иконки и 180° rotate.
class AppAnimatedSendButton extends StatelessWidget {
  const AppAnimatedSendButton({
    required this.onTap,
    this.sending = false,
    this.sent = false,
    super.key,
  });

  final VoidCallback? onTap;
  final bool sending;
  final bool sent;

  @override
  Widget build(BuildContext context) {
    final icon = sent
        ? Icons.check_rounded
        : (sending ? Icons.hourglass_top_rounded : Icons.send_rounded);
    return IconButton.filled(
      onPressed: sending || sent ? null : onTap,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween<double>(begin: 0.5, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(icon, key: ValueKey(icon), size: 20),
      ),
      style: IconButton.styleFrom(
        backgroundColor: sent ? AppColors.greenDot : AppColors.brand,
        foregroundColor: AppColors.n0,
      ),
    );
  }
}

/// Полоса прогресса загрузки с анимированным shimmer при активном
/// значении (определённый/неопределённый).
class AppUploadProgressBar extends StatelessWidget {
  const AppUploadProgressBar({
    required this.progress,
    super.key,
  });

  /// Значение 0.0–1.0 или null (неопределённый progress).
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.n100,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
        ),
      ),
    ).animate(onPlay: (c) => progress == null ? c.repeat() : null).shimmer(
          duration: 1200.ms,
          color: AppColors.brand.withValues(alpha: 0.15),
        );
  }
}
