import 'package:flutter/material.dart' hide Step;
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../steps/domain/step.dart';
import '../../../steps/domain/substep.dart';
import 'substep_row.dart';

/// Аннотация под шагом: открытый вопрос или ожидающая доп.работа.
sealed class StepAnnotation {
  const StepAnnotation();
}

class OpenQuestionAnnotation extends StepAnnotation {
  const OpenQuestionAnnotation({required this.text, this.openedBy});
  final String text;
  final String? openedBy;
}

class ExtraWorkPendingAnnotation extends StepAnnotation {
  const ExtraWorkPendingAnnotation({required this.amountKopecks});
  final int amountKopecks;
}

/// Строка чек-листа этапа — c-stage-active / -paused / -done.
///
/// Слева 24×24 чекбокс (зелёный при done), eyebrow + название, опц. подзадачи
/// (раскрываются при done — chevron) и аннотация-pill (вопрос / доп.работа).
/// brand-light bg для активного шага.
class ChecklistStepRow extends StatefulWidget {
  const ChecklistStepRow({
    required this.step,
    required this.onTap,
    required this.onToggleDone,
    this.isActive = false,
    this.locked = false,
    this.executorName,
    this.completedAt,
    this.annotation,
    this.substeps = const [],
    this.onToggleSubstep,
    super.key,
  });

  final Step step;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final bool isActive;
  final bool locked;
  final String? executorName;
  final DateTime? completedAt;
  final StepAnnotation? annotation;
  final List<Substep> substeps;
  final ValueChanged<Substep>? onToggleSubstep;

  @override
  State<ChecklistStepRow> createState() => _ChecklistStepRowState();
}

class _ChecklistStepRowState extends State<ChecklistStepRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDone = widget.step.isDone;
    final hasSubsteps = widget.substeps.isNotEmpty;
    final df = DateFormat('d MMM', 'ru');
    final subtitle = isDone
        ? [
            if (widget.executorName != null) widget.executorName,
            if (widget.completedAt != null) df.format(widget.completedAt!),
          ].whereType<String>().join(' · ')
        : '';

    return Opacity(
      opacity: widget.locked ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.x8),
        decoration: BoxDecoration(
          color: widget.isActive ? AppColors.brandLight : AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: widget.isActive
                ? AppColors.brand.withValues(alpha: 0.3)
                : AppColors.n200,
          ),
          boxShadow: AppShadows.sh1,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: widget.locked ? null : widget.onTap,
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: widget.locked ? null : widget.onToggleDone,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.greenDot : null,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? Colors.transparent
                                : AppColors.n300,
                            width: 2,
                          ),
                          boxShadow:
                              isDone ? AppShadows.glowGreen : null,
                        ),
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: AppColors.n0,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.step.title,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.n800,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.n400,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: AppTextStyles.tiny.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.n400,
                              ),
                            ),
                          ],
                          if (widget.annotation != null) ...[
                            const SizedBox(height: AppSpacing.x6),
                            _AnnotationPill(annotation: widget.annotation!),
                          ],
                        ],
                      ),
                    ),
                    if (hasSubsteps)
                      IconButton(
                        onPressed: () =>
                            setState(() => _expanded = !_expanded),
                        icon: Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.n400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_expanded && hasSubsteps)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.n100),
                  ),
                ),
                child: Column(
                  children: [
                    for (final sub in widget.substeps)
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: SubstepRow(
                          substep: sub,
                          onToggle: () => widget.onToggleSubstep?.call(sub),
                        ),
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

class _AnnotationPill extends StatelessWidget {
  const _AnnotationPill({required this.annotation});

  final StepAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color, bg) = switch (annotation) {
      OpenQuestionAnnotation(:final text) => (
          Icons.help_outline_rounded,
          text.length > 60 ? '${text.substring(0, 57)}…' : text,
          AppColors.yellowText,
          AppColors.yellowBg,
        ),
      ExtraWorkPendingAnnotation(:final amountKopecks) => (
          Icons.payments_outlined,
          'Доп. ${(amountKopecks / 100).toStringAsFixed(0)} ₽ · Ожидает одобрения',
          AppColors.yellowText,
          AppColors.yellowBg,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
