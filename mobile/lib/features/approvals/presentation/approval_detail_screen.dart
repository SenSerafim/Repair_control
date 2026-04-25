import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/approvals_controller.dart';
import '../domain/approval.dart';
import 'approval_sheets.dart';
import 'approval_widgets.dart';

/// d-approval-detail / d-approval-extra / d-plan-approval / d-stage-accept /
/// d-deadline-change — унифицированный экран, варьирует тело по scope.
class ApprovalDetailScreen extends ConsumerWidget {
  const ApprovalDetailScreen({
    required this.projectId,
    required this.approvalId,
    super.key,
  });

  final String projectId;
  final String approvalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalDetailProvider(approvalId));

    return AppScaffold(
      showBack: true,
      title: 'Согласование',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(approvalDetailProvider(approvalId)),
        ),
        data: (approval) {
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(approvalDetailProvider(approvalId)),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    children: [
                      Hero(
                        tag: 'approval-${approval.id}',
                        flightShuttleBuilder:
                            (_, __, dir, fromCtx, toCtx) {
                          final hero = (dir == HeroFlightDirection.push
                                  ? fromCtx
                                  : toCtx)
                              .widget as Hero;
                          return hero.child;
                        },
                        child: const SizedBox(height: 1),
                      ),
                      _Header(approval: approval),
                      if (approval.requiresReassign) ...[
                        const SizedBox(height: AppSpacing.x12),
                        _RequiresReassignBanner(approval: approval),
                      ],
                      const SizedBox(height: AppSpacing.x16),
                      _ScopeBody(approval: approval),
                      if (approval.decisionComment?.isNotEmpty ??
                          false) ...[
                        const SizedBox(height: AppSpacing.x16),
                        _DecisionBlock(approval: approval),
                      ],
                      const SizedBox(height: AppSpacing.x16),
                      if (approval.attempts.isNotEmpty) ...[
                        const Text(
                          'История',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: AppSpacing.x8),
                        ApprovalAttemptsList(
                          attempts: approval.attempts,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.x24),
                    ],
                  ),
                ),
              ),
              _BottomActions(approval: approval),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approval.scope.displayName,
                      style: AppTextStyles.h2,
                    ),
                    Text(
                      approval.scope.shortHint,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (approval.attemptNumber > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.n100,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '#${approval.attemptNumber}',
                    style: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              StatusPill(
                label: approval.status.displayName,
                semaphore: approval.status.semaphore,
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                DateFormat('d MMM HH:mm', 'ru').format(approval.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionBlock extends StatelessWidget {
  const _DecisionBlock({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final isApproved = approval.status == ApprovalStatus.approved;
    final color = isApproved ? AppColors.greenDark : AppColors.redDot;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isApproved ? 'Комментарий одобрившего' : 'Причина отказа',
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Text(approval.decisionComment!, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

/// Тело экрана — зависит от scope.
class _ScopeBody extends StatelessWidget {
  const _ScopeBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    switch (approval.scope) {
      case ApprovalScope.plan:
        return _PlanBody(approval: approval);
      case ApprovalScope.step:
        return _StepBody(approval: approval);
      case ApprovalScope.extraWork:
        return _ExtraBody(approval: approval);
      case ApprovalScope.deadlineChange:
        return _DeadlineBody(approval: approval);
      case ApprovalScope.stageAccept:
        return _StageAcceptBody(approval: approval);
    }
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final stages = approval.planStages;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('План этапов', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.x8),
          if (stages.isEmpty)
            const Text(
              'В payload нет списка этапов — согласуется план в целом.',
              style: AppTextStyles.caption,
            )
          else
            for (var i = 0; i < stages.length; i++) ...[
              _PlanStageRow(
                index: i + 1,
                data: stages[i],
              ),
              if (i < stages.length - 1)
                const Divider(height: AppSpacing.x16, color: AppColors.n100),
            ],
        ],
      ),
    );
  }
}

class _PlanStageRow extends StatelessWidget {
  const _PlanStageRow({required this.index, required this.data});

  final int index;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Этап $index';
    final start = data['plannedStart']?.toString();
    final end = data['plannedEnd']?.toString();
    final dateLine = [
      if (start != null) DateFormat('d MMM', 'ru').format(DateTime.parse(start)),
      if (end != null) DateFormat('d MMM', 'ru').format(DateTime.parse(end)),
    ].join(' — ');
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          child: Text(
            '$index',
            style: AppTextStyles.micro.copyWith(color: AppColors.brand),
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.subtitle),
              if (dateLine.isNotEmpty)
                Text(dateLine, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Отметка шага',
      hint: approval.stepId == null
          ? 'Шаг не привязан'
          : 'ID: ${approval.stepId}',
    );
  }
}

class _ExtraBody extends StatelessWidget {
  const _ExtraBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final price = approval.extraPrice;
    final description = approval.extraDescription;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Доп.работа', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.x10),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                price == null ? '—' : Money.format(price),
                style: AppTextStyles.h1.copyWith(color: AppColors.purple),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x12),
            Text(description, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

class _DeadlineBody extends StatelessWidget {
  const _DeadlineBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final newEnd = approval.newEnd;
    return _InfoCard(
      title: 'Перенос дедлайна',
      hint: newEnd == null
          ? 'Новая дата не указана'
          : 'Новая дата: ${DateFormat('d MMMM y', 'ru').format(newEnd)}',
    );
  }
}

class _StageAcceptBody extends StatelessWidget {
  const _StageAcceptBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final photos = approval.acceptPhotoCount ?? 0;
    return _InfoCard(
      title: 'Приёмка этапа',
      hint: photos > 0
          ? 'Этап готов · $photos фото к приёмке'
          : 'Этап готов · без фото',
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(hint, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  const _BottomActions({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[];
    final canDecide = ref.watch(canProvider(DomainAction.approvalDecide));
    final canRequest = ref.watch(canProvider(DomainAction.approvalRequest));

    switch (approval.status) {
      case ApprovalStatus.pending:
        if (canDecide) {
          actions
            ..add(
              AppButton(
                label: 'Одобрить',
                variant: AppButtonVariant.success,
                onPressed: () =>
                    showApproveSheet(context, ref, approval: approval),
              ),
            )
            ..add(const SizedBox(height: AppSpacing.x8))
            ..add(
              AppButton(
                label: 'Отклонить',
                variant: AppButtonVariant.destructive,
                onPressed: () =>
                    showRejectSheet(context, ref, approval: approval),
              ),
            )
            ..add(const SizedBox(height: AppSpacing.x8));
        }
        if (canRequest) {
          actions.add(
            AppButton(
              label: 'Отменить заявку',
              variant: AppButtonVariant.ghost,
              onPressed: () => _cancel(context, ref),
            ),
          );
        }
      case ApprovalStatus.rejected:
        if (canRequest) {
          actions.add(
            AppButton(
              label: 'Отправить повторно',
              onPressed: () =>
                  showResubmitSheet(context, ref, approval: approval),
            ),
          );
        }
      case ApprovalStatus.approved:
      case ApprovalStatus.cancelled:
        return const SizedBox.shrink();
    }
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(approvalsControllerProvider(approval.projectId).notifier)
        .cancel(approval);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null ? 'Заявка отменена' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}

/// Баннер «Бригадир удалён со стадии» — требует переназначения, иначе
/// approval не сможет быть закрыт нормальным flow (gaps §3.3).
class _RequiresReassignBanner extends StatelessWidget {
  const _RequiresReassignBanner({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.redDot.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.redDot,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Бригадир удалён со стадии',
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.redText),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Согласование зависло — переназначьте бригадира в команде '
                  'проекта, чтобы можно было одобрить или отклонить.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.x10),
                AppButton(
                  label: 'Открыть команду',
                  variant: AppButtonVariant.destructive,
                  onPressed: () => context.push(
                    '/projects/${approval.projectId}/team',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
