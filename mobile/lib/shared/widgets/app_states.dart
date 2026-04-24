import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'app_button.dart';

/// Обёртка для одного из 4 состояний экрана (ТЗ v3 §21).
/// Используется через `AppStateBuilder<T>(asyncValue, ...)` или напрямую
/// виджеты AppLoadingState / AppEmptyState / AppErrorState.

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({this.skeleton, this.branded = false, super.key});

  /// Skeleton-виджет, имитирующий финальный UI.
  final Widget? skeleton;

  /// Показать брендовый анимированный spinner с двумя кольцами.
  final bool branded;

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) {
      return Skeletonizer(
        effect: const ShimmerEffect(
          baseColor: AppColors.n100,
          highlightColor: AppColors.n200,
        ),
        child: skeleton!,
      );
    }
    if (branded) {
      return const Center(child: _BrandSpinner());
    }
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
        ),
      ),
    );
  }
}

class _BrandSpinner extends StatelessWidget {
  const _BrandSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.brandLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              size: 16,
              color: AppColors.brand,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.05, 1.05),
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(AppRadius.r24),
            ),
            child: Icon(icon, size: 32, color: AppColors.n400),
          )
              .animate()
              .fadeIn(duration: 260.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 380.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(color: AppColors.n700),
          ).animate().fadeIn(delay: 120.ms, duration: 280.ms),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.x8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 260.ms),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.x20),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.ghost,
              fullWidth: false,
            ).animate().fadeIn(delay: 280.ms, duration: 260.ms),
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel = 'Повторить',
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: BorderRadius.circular(AppRadius.r24),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 34,
              color: AppColors.redDot,
            ),
          ).animate().shake(
                delay: 80.ms,
                hz: 3,
                offset: const Offset(4, 0),
                duration: 420.ms,
              ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(color: AppColors.n700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.x8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.x20),
            AppButton(
              label: retryLabel,
              onPressed: onRetry,
              variant: AppButtonVariant.secondary,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Красный inline-банер ошибки под формой. Используется create_*
/// экранами и edit_profile.
class AppInlineError extends StatelessWidget {
  const AppInlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.redDot,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.redText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(
          begin: -0.2,
          end: 0,
          duration: 220.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Small animated success checkmark — подходит для подтверждений
/// (submit forms, successful action, confirm-delete).
class AppSuccessBurst extends StatelessWidget {
  const AppSuccessBurst({
    this.size = 72,
    this.color = AppColors.greenDot,
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                begin: 0.6,
                end: 1.3,
                duration: 1200.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 1200.ms, curve: Curves.easeOut),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.n0,
              size: 28,
            ),
          ).animate().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}
