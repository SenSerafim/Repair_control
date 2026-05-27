import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Статусный светофор проекта/этапа/выплаты.
enum Semaphore { plan, green, yellow, red, blue }

extension SemaphoreColors on Semaphore {
  Color get dot => switch (this) {
    Semaphore.plan => AppColors.n400,
    Semaphore.green => AppColors.greenDot,
    Semaphore.yellow => AppColors.yellowDot,
    Semaphore.red => AppColors.redDot,
    Semaphore.blue => AppColors.blueDot,
  };

  Color get bg => switch (this) {
    Semaphore.plan => AppColors.n100,
    Semaphore.green => AppColors.greenLight,
    Semaphore.yellow => AppColors.yellowBg,
    Semaphore.red => AppColors.redBg,
    Semaphore.blue => AppColors.blueBg,
  };

  Color get text => switch (this) {
    Semaphore.plan => AppColors.n600,
    Semaphore.green => AppColors.greenDark,
    Semaphore.yellow => AppColors.yellowText,
    Semaphore.red => AppColors.redText,
    Semaphore.blue => AppColors.blueText,
  };

  /// Stripe-градиент по статусу — для верхней полоски карточек этапов
  /// (StageStripeCard) и левой вертикальной полосы (StageRowCard).
  LinearGradient get stripe => switch (this) {
    Semaphore.plan => AppGradients.stripePlan,
    Semaphore.green => AppGradients.stripeGreen,
    Semaphore.yellow => AppGradients.stripeYellow,
    Semaphore.red => AppGradients.stripeRed,
    Semaphore.blue => AppGradients.stripeBrand,
  };
}

/// Pill-чип со статусом, аналог `.stg-badge` в макетах.
/// Высота ~24, pill-радиус, цвета — по Semaphore.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.semaphore,
    this.showDot = true,
    super.key,
  });

  final String label;
  final Semaphore semaphore;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: semaphore.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // Тонкий inset-ring цвета статуса — пилюля «отрывается» от
        // подложки в плотных списках (Cluster C: stage tile/list) и
        // там, где bg StatusPill близок к bg карточки.
        border: Border.all(color: semaphore.dot.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: semaphore.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.x6),
          ],
          Text(
            label,
            style: AppTextStyles.micro.copyWith(color: semaphore.text),
          ),
        ],
      ),
    );
  }
}
