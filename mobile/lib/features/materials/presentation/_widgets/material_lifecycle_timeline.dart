import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Состояние шага в timeline.
enum LifecycleStepState { done, active, pending }

/// Элемент жизненного цикла (вертикальный timeline) — для material/selfpurchase.
/// Отображает шаги: каждый шаг — dot + title + sub-date.
/// `immutable=true` подсвечивает дату зелёным с пометкой «(неизменяемая)».
class MaterialLifecycleTimeline extends StatelessWidget {
  const MaterialLifecycleTimeline({required this.steps, super.key});

  final List<LifecycleStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _Step(
              step: steps[i],
              divider: i < steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class LifecycleStep {
  const LifecycleStep({
    required this.title,
    required this.state,
    this.dateLabel,
    this.immutable = false,
  });

  final String title;
  final LifecycleStepState state;
  final String? dateLabel;
  final bool immutable;
}

class _Step extends StatelessWidget {
  const _Step({required this.step, required this.divider});

  final LifecycleStep step;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final isPending = step.state == LifecycleStepState.pending;
    return Container(
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.n100)),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Dot(state: step.state),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: isPending ? AppColors.n400 : AppColors.n800,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (step.dateLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.immutable
                        ? '${step.dateLabel} (неизменяемая)'
                        : step.dateLabel!,
                    style: AppTextStyles.tiny.copyWith(
                      color: step.immutable
                          ? AppColors.greenDark
                          : AppColors.n400,
                      fontWeight: step.immutable
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final LifecycleStepState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          LifecycleStepState.done => AppColors.greenDot,
          LifecycleStepState.active => AppColors.brand,
          LifecycleStepState.pending => Colors.transparent,
        },
        border: Border.all(
          color: switch (state) {
            LifecycleStepState.done => AppColors.greenDark,
            LifecycleStepState.active => AppColors.brandDark,
            LifecycleStepState.pending => AppColors.n200,
          },
          width: 2,
        ),
      ),
    );
  }
}
