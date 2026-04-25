import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/approval.dart';

/// Карточка согласования для списка.
class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    required this.approval,
    required this.onTap,
    super.key,
  });

  final Approval approval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitleFor(approval);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: 'approval-${approval.id}',
        flightShuttleBuilder: (_, __, dir, fromCtx, toCtx) {
          final hero =
              (dir == HeroFlightDirection.push ? fromCtx : toCtx).widget
                  as Hero;
          return hero.child;
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: approval.status.semaphore.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                approval.scope.icon,
                color: approval.status.semaphore.text,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          approval.scope.displayName,
                          style: AppTextStyles.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (approval.attemptNumber > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.n100,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '#${approval.attemptNumber}',
                            style: AppTextStyles.tiny,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusPill(
                        label: approval.status.displayName,
                        semaphore: approval.status.semaphore,
                      ),
                      const SizedBox(width: AppSpacing.x8),
                      Text(
                        DateFormat('d MMM HH:mm', 'ru')
                            .format(approval.createdAt),
                        style: AppTextStyles.caption,
                      ),
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
          ),
        ),
    );
  }

  static String _subtitleFor(Approval a) {
    switch (a.scope) {
      case ApprovalScope.plan:
        final count = a.planStages.length;
        return count > 0 ? 'План из $count этапов' : 'Согласование плана';
      case ApprovalScope.step:
        return a.decisionComment?.isNotEmpty ?? false
            ? a.decisionComment!
            : 'Отметка шага';
      case ApprovalScope.extraWork:
        final price = a.extraPrice;
        return price == null
            ? 'Доп.работа'
            : 'Доп.работа · ${Money.format(price)}';
      case ApprovalScope.deadlineChange:
        final end = a.newEnd;
        return end == null
            ? 'Перенос дедлайна'
            : 'До ${DateFormat('d MMM y', 'ru').format(end)}';
      case ApprovalScope.stageAccept:
        return 'Приёмка этапа';
    }
  }
}

/// Таймлайн попыток — для ApprovalDetail.
///
/// Дизайн `d-approvals-history`: stacked-cards. Новейшая попытка сверху,
/// предыдущие — в стопке за ней с нарастающим offset (-4px x 2, -8px x 2...)
/// и спадающей opacity (1.0 → 0.85 → 0.70 → 0.55). Отображается до 4 попыток
/// одновременно, остальные — fade-out.
class ApprovalAttemptsList extends StatelessWidget {
  const ApprovalAttemptsList({
    required this.attempts,
    this.maxVisible = 4,
    super.key,
  });

  final List<ApprovalAttempt> attempts;
  final int maxVisible;

  static const double _cardHeight = 86;
  static const double _stepOffset = 4;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) return const SizedBox.shrink();
    // Новейшие сверху (descending по createdAt).
    final sorted = [...attempts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visible = sorted.take(maxVisible).toList();
    // Высота: основной card + (N-1) × offset за счёт хвостов.
    final stackHeight =
        _cardHeight + (visible.length - 1) * _stepOffset * 2 + AppSpacing.x6;
    return SizedBox(
      height: stackHeight,
      child: Stack(
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
            Positioned(
              top: i * _stepOffset * 2,
              left: i * _stepOffset,
              right: i * _stepOffset,
              child: Opacity(
                opacity: 1 - (i * 0.15).clamp(0.0, 0.6),
                child: _AttemptRow(attempt: visible[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt});

  final ApprovalAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (attempt.action) {
      'created' => (
          Icons.hourglass_top_outlined,
          AppColors.brand,
          'Создан',
        ),
      'approved' => (
          Icons.check_rounded,
          AppColors.greenDark,
          'Одобрен',
        ),
      'rejected' => (
          Icons.close_rounded,
          AppColors.redDot,
          'Отклонён',
        ),
      'resubmitted' => (
          Icons.refresh_rounded,
          AppColors.brand,
          'Повторно отправлен',
        ),
      'cancelled' => (
          Icons.do_disturb_alt_outlined,
          AppColors.n400,
          'Отменён',
        ),
      _ => (Icons.history_rounded, AppColors.n500, attempt.action),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.subtitle.copyWith(color: color),
                    ),
                    const Spacer(),
                    Text(
                      'Попытка №${attempt.attemptNumber}',
                      style: AppTextStyles.tiny,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM y · HH:mm', 'ru')
                      .format(attempt.createdAt),
                  style: AppTextStyles.caption,
                ),
                if (attempt.comment != null &&
                    attempt.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(attempt.comment!, style: AppTextStyles.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
