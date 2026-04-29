import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';

/// Экран успеха после создания этапа — c-stage-created.
///
/// 72×72 green-light icon, «Этап создан!», 2 CTA: «Открыть этап» (primary) и
/// «К списку этапов» (ghost).
class StageCreatedSuccess extends StatelessWidget {
  const StageCreatedSuccess({
    required this.onOpenStage,
    required this.onBackToList,
    super.key,
  });

  final VoidCallback onOpenStage;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                size: 36,
                color: AppColors.greenDark,
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            Text(
              'Этап создан!',
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.x8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'Теперь назначьте бригадира и настройте чек-лист шагов перед '
                'запуском.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.n400,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                children: [
                  AppButton(label: 'Открыть этап', onPressed: onOpenStage),
                  const SizedBox(height: AppSpacing.x8),
                  AppButton(
                    label: 'К списку этапов',
                    variant: AppButtonVariant.ghost,
                    onPressed: onBackToList,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
