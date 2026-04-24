import 'package:flutter/material.dart' hide Step;

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/step.dart';

class StepStatusBadge extends StatelessWidget {
  const StepStatusBadge({required this.status, super.key});

  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: status.displayName,
      semaphore: status.semaphore,
    );
  }
}

/// Строка шага в списке на StageDetail. Checkbox для быстрой отметки
/// + типизация extra с ₽.
class StepRow extends StatelessWidget {
  const StepRow({
    required this.step,
    required this.onTap,
    this.onToggleDone,
    this.canToggle = true,
    super.key,
  });

  final Step step;
  final VoidCallback onTap;
  final VoidCallback? onToggleDone;
  final bool canToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            if (canToggle && onToggleDone != null)
              _CheckBubble(
                isDone: step.isDone,
                onTap: onToggleDone!,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: step.status.semaphore.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.isDone
                      ? Icons.check_rounded
                      : Icons.pending_outlined,
                  size: 14,
                  color: step.status.semaphore.text,
                ),
              ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (step.isExtra) ...[
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 14,
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          step.title,
                          style: AppTextStyles.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StepStatusBadge(status: step.status),
                      if (step.isExtra && step.price != null) ...[
                        const SizedBox(width: AppSpacing.x8),
                        Text(
                          Money.format(step.price!),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (step.substepsCount > 0) ...[
                        const SizedBox(width: AppSpacing.x8),
                        _MiniChip(
                          icon: Icons.checklist_rounded,
                          label:
                              '${step.substepsDone}/${step.substepsCount}',
                        ),
                      ],
                      if (step.photosCount > 0) ...[
                        const SizedBox(width: AppSpacing.x6),
                        _MiniChip(
                          icon: Icons.photo_outlined,
                          label: '${step.photosCount}',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.n300,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  const _CheckBubble({required this.isDone, required this.onTap});

  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isDone ? AppColors.greenDot : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDone ? AppColors.greenDot : AppColors.n300,
            width: 2,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: AppColors.greenDot.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isDone
            ? const Icon(
                Icons.check_rounded,
                color: AppColors.n0,
                size: 14,
              )
            : null,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.n500),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: AppColors.n600),
          ),
        ],
      ),
    );
  }
}
