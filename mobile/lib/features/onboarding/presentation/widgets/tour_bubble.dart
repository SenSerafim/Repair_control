import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Bubble с подсказкой текущего шага тура. Самостоятельный виджет,
/// чтобы можно было использовать и в spotlight-overlay, и в info-режиме
/// (по центру экрана) на Welcome / Completion шагах.
class TourBubble extends StatelessWidget {
  const TourBubble({
    required this.title,
    required this.message,
    required this.stepIndex,
    required this.totalSteps,
    required this.onSkip,
    this.onBack,
    this.onNext,
    this.onCutoutTapHint,
    super.key,
  });

  final String title;
  final String message;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  /// Если задан — показываем кнопку «Далее» (info-шаги без spotlight).
  /// Если `null` — показываем `onCutoutTapHint` («Нажмите на подсвеченное»).
  final VoidCallback? onNext;
  final String? onCutoutTapHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh3,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Прогресс «3 / 14»
            Text(
              '${stepIndex + 1} / $totalSteps',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(MaterialLocalizations.of(context)
                          .modalBarrierDismissLabel.isEmpty
                      ? 'Пропустить'
                      : 'Пропустить'),
                ),
                const Spacer(),
                if (onBack != null)
                  TextButton(
                    onPressed: onBack,
                    child: const Text('Назад'),
                  ),
                const SizedBox(width: 8),
                if (onNext != null)
                  FilledButton(
                    onPressed: onNext,
                    child: const Text('Далее'),
                  ),
              ],
            ),
            if (onCutoutTapHint != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      onCutoutTapHint!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
