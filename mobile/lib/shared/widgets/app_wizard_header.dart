import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Header многошаговых форм (s-create-1/2/3 в Cluster B).
///
/// Структура: back-btn + title + step-label справа («Шаг 2 из 3»),
/// под этим — 3 step-pill (done/active/inactive) с разделителями,
/// и тонкий progress-bar внизу (анимируется).
class AppWizardHeader extends StatelessWidget {
  const AppWizardHeader({
    required this.title,
    required this.step,
    required this.totalSteps,
    this.onBack,
    super.key,
  });

  final String title;

  /// 1-based текущий шаг.
  final int step;

  /// Всего шагов (по дизайну — 3).
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border:
              Border(bottom: BorderSide(color: AppColors.n200, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _BackBtn(onTap: onBack),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n900,
                      letterSpacing: -0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Шаг $step из $totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x16),
            _StepPills(step: step, total: totalSteps),
            const SizedBox(height: AppSpacing.x12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedContainer(
                duration: AppDurations.normal,
                curve: Curves.easeOut,
                height: 4,
                width: double.infinity,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: (step / totalSteps).clamp(0.0, 1.0),
                  backgroundColor: AppColors.n100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brand,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r12),
            boxShadow: AppShadows.sh1,
          ),
          child: Icon(
            PhosphorIconsRegular.caretLeft,
            size: 18,
            color: AppColors.n700,
          ),
        ),
      ),
    );
  }
}

class _StepPills extends StatelessWidget {
  const _StepPills({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 1; i <= total; i++) {
      final state = i < step
          ? _PillState.done
          : i == step
              ? _PillState.active
              : _PillState.inactive;
      widgets.add(_Pill(label: '$i', state: state));
      if (i < total) {
        widgets.add(
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: i < step ? AppColors.greenDot : AppColors.n200,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }
    }
    return Row(children: widgets);
  }
}

enum _PillState { done, active, inactive }

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.state});

  final String label;
  final _PillState state;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadow) = switch (state) {
      _PillState.done => (
          const Color(0xFFDEF7EC),
          const Color(0xFF057A55),
          <BoxShadow>[],
        ),
      _PillState.active => (
          AppColors.brand,
          AppColors.n0,
          AppShadows.shBlue,
        ),
      _PillState.inactive => (
          AppColors.n100,
          AppColors.n400,
          <BoxShadow>[],
        ),
    };

    return AnimatedContainer(
      duration: AppDurations.normal,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: shadow,
      ),
      child: state == _PillState.done
          ? const Icon(PhosphorIconsBold.check, size: 14, color: Color(0xFF057A55))
          : Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
    );
  }
}
