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
class ApprovalAttemptsList extends StatelessWidget {
  const ApprovalAttemptsList({required this.attempts, super.key});

  final List<ApprovalAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) return const SizedBox.shrink();
    final sorted = [...attempts]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Column(
      children: [
        for (final a in sorted) ...[
          _AttemptRow(attempt: a),
          const SizedBox(height: AppSpacing.x6),
        ],
      ],
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
