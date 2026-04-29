import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../approvals/application/approvals_controller.dart';
import '../../../approvals/domain/approval.dart';
import '../../../approvals/presentation/_widgets/approval_pending_card.dart';
import '../../../approvals/presentation/_widgets/approval_timeline_item.dart';
import '../../../approvals/presentation/_widgets/reject_sheet.dart';

/// Таб «Согл.» в детали этапа — показывает только согласования по текущему
/// stageId. Pending → yellow cards с inline approve/reject; история — timeline.
class StageApprovalsTab extends ConsumerWidget {
  const StageApprovalsTab({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalsControllerProvider(projectId));
    return async.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить согласования',
        onRetry: () => ref.invalidate(approvalsControllerProvider(projectId)),
      ),
      data: (buckets) {
        final pending = buckets.pending
            .where((a) => a.stageId == stageId)
            .toList();
        final history = buckets.history
            .where((a) => a.stageId == stageId)
            .toList();
        if (pending.isEmpty && history.isEmpty) {
          return const AppEmptyState(
            title: 'Согласований нет',
            subtitle: 'Здесь появятся отправленные на согласование шаги, '
                'дополнительные работы и приёмка этапа.',
            icon: Icons.fact_check_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.x16),
          children: [
            if (pending.isNotEmpty) ...[
              _SectionHeader(text: 'Ожидают решения · ${pending.length}'),
              const SizedBox(height: AppSpacing.x8),
              for (final a in pending) ...[
                ApprovalPendingCard(
                  approval: a,
                  onApprove: () => _approve(context, ref, a),
                  onReject: () => _reject(context, ref, a),
                ),
                const SizedBox(height: AppSpacing.x10),
              ],
              const SizedBox(height: AppSpacing.x8),
            ],
            if (history.isNotEmpty) ...[
              const _SectionHeader(text: 'История'),
              const SizedBox(height: AppSpacing.x12),
              for (var i = 0; i < history.length; i++)
                ApprovalTimelineItem(
                  title: '${history[i].scope.displayName} · ${_statusLabel(history[i].status)}',
                  byline:
                      '${_actorByline(history[i])} · ${DateFormat('d MMM', 'ru').format(history[i].decidedAt ?? history[i].updatedAt)}',
                  comment: history[i].decisionComment,
                  last: i == history.length - 1,
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, Approval a) async {
    final failure = await ref
        .read(approvalsControllerProvider(projectId).notifier)
        .approve(approval: a);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null ? 'Одобрено' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, Approval a) async {
    final reason = await showRejectSheet(
      context,
      entityName: a.scope.displayName,
    );
    if (reason == null || !context.mounted) return;
    final failure = await ref
        .read(approvalsControllerProvider(projectId).notifier)
        .reject(approval: a, comment: reason);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null ? 'Отклонено' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }

  String _statusLabel(ApprovalStatus s) => switch (s) {
        ApprovalStatus.approved => 'согласован',
        ApprovalStatus.rejected => 'отклонён',
        ApprovalStatus.cancelled => 'отменён',
        ApprovalStatus.pending => 'на рассмотрении',
      };

  String _actorByline(Approval a) {
    if (a.status == ApprovalStatus.approved) return 'Заказчик одобрил';
    if (a.status == ApprovalStatus.rejected) return 'Заказчик отклонил';
    return '';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.tiny.copyWith(
        color: AppColors.n400,
        letterSpacing: 0.6,
      ),
    );
  }
}
