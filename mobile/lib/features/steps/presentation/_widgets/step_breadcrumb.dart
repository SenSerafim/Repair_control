import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Хлебные крошки в детали шага — c-step-detail.
///
/// Две pill: brand-light с «Шаг N из M» + n100 со stage-title.
class StepBreadcrumb extends StatelessWidget {
  const StepBreadcrumb({
    required this.stepNumber,
    required this.totalSteps,
    required this.stageTitle,
    super.key,
  });

  final int stepNumber;
  final int totalSteps;
  final String stageTitle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x6,
      runSpacing: 4,
      children: [
        _Pill(
          label: 'Шаг $stepNumber из $totalSteps',
          bg: AppColors.brandLight,
          fg: AppColors.brandDark,
        ),
        _Pill(label: stageTitle, bg: AppColors.n100, fg: AppColors.n600),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
