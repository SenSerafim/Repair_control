import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/domain/project.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../application/approvals_controller.dart';
import '../data/approvals_repository.dart';
import '../domain/approval.dart';
import 'approval_sheets.dart';

/// d-plan-approval — согласование плана этапов проекта целиком.
///
/// Customer / representative приходят сюда из `ConsoleScreen` (баннер),
/// `ApprovalsScreen` (если есть pending plan-approval) и push-нотификации.
/// Foreman / contractor попадают сюда чтобы запросить согласование плана
/// (создать approval scope=plan).
class PlanApprovalScreen extends ConsumerWidget {
  const PlanApprovalScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectControllerProvider(projectId));
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final approvalsAsync = ref.watch(approvalsControllerProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'План работ',
      padding: EdgeInsets.zero,
      body: projectAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить проект',
          onRetry: () => ref.invalidate(projectControllerProvider(projectId)),
        ),
        data: (project) {
          final stages = stagesAsync.value ?? const <Stage>[];
          final pendingPlanApproval = approvalsAsync.value?.pending
              .where((a) => a.scope == ApprovalScope.plan)
              .firstOrNull;
          return _Body(
            projectId: projectId,
            project: project,
            stages: stages,
            pendingApproval: pendingPlanApproval,
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.projectId,
    required this.project,
    required this.stages,
    required this.pendingApproval,
  });

  final String projectId;
  final Project project;
  final List<Stage> stages;
  final Approval? pendingApproval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDecide = ref.watch(canInProjectProvider(
      (action: DomainAction.approvalDecide, projectId: project.id),
    ));
    final canRequest = ref.watch(canInProjectProvider(
      (action: DomainAction.approvalRequest, projectId: project.id),
    ));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        _StatusBanner(
          planApproved: project.planApproved,
          requiresPlanApproval: project.requiresPlanApproval,
          pendingApproval: pendingApproval,
        ),
        const SizedBox(height: AppSpacing.x16),
        _Summary(stages: stages, project: project),
        const SizedBox(height: AppSpacing.x16),
        const Text('Этапы плана', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.x10),
        if (stages.isEmpty)
          const AppEmptyState(
            title: 'Пока нет этапов',
            subtitle: 'Бригадир добавит этапы, тогда план можно согласовать.',
            icon: Icons.list_alt_rounded,
          )
        else
          for (var i = 0; i < stages.length; i++) ...[
            _PlanStageRow(index: i + 1, stage: stages[i]),
            const SizedBox(height: AppSpacing.x8),
          ],
        const SizedBox(height: AppSpacing.x16),
        _Actions(
          projectId: projectId,
          stages: stages,
          pendingApproval: pendingApproval,
          canDecide: canDecide,
          canRequest: canRequest,
          planApproved: project.planApproved,
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.planApproved,
    required this.requiresPlanApproval,
    required this.pendingApproval,
  });

  final bool planApproved;
  final bool requiresPlanApproval;
  final Approval? pendingApproval;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, color) = () {
      if (planApproved) {
        return (
          Icons.check_circle_outline,
          'План согласован',
          'Бригадир может запускать этапы по графику.',
          AppColors.greenDark,
        );
      }
      if (pendingApproval != null) {
        return (
          Icons.pending_actions_outlined,
          'Ждёт решения заказчика',
          'Заказчик может одобрить план или запросить корректировку.',
          AppColors.blueDot,
        );
      }
      if (!requiresPlanApproval) {
        return (
          Icons.info_outline,
          'Согласование не требуется',
          'Проект не требует одобрения плана — этапы запускаются сразу.',
          AppColors.n500,
        );
      }
      return (
        Icons.schedule_outlined,
        'План не согласован',
        'Отправьте план на согласование заказчику.',
        AppColors.n500,
      );
    }();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.stages, required this.project});

  final List<Stage> stages;
  final Project project;

  @override
  Widget build(BuildContext context) {
    final workBudget = stages.fold<int>(0, (sum, s) => sum + s.workBudget);
    final materialsBudget =
        stages.fold<int>(0, (sum, s) => sum + s.materialsBudget);
    final earliest = stages
        .where((s) => s.plannedStart != null)
        .map((s) => s.plannedStart!)
        .fold<DateTime?>(null,
            (acc, d) => acc == null || d.isBefore(acc) ? d : acc);
    final latest = stages
        .where((s) => s.plannedEnd != null)
        .map((s) => s.plannedEnd!)
        .fold<DateTime?>(null,
            (acc, d) => acc == null || d.isAfter(acc) ? d : acc);
    String fmt(DateTime? d) =>
        d == null ? '—' : DateFormat('d MMM y', 'ru').format(d);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        children: [
          _row('Этапов', '${stages.length}'),
          const Divider(height: AppSpacing.x16, color: AppColors.n100),
          _row('Сроки', '${fmt(earliest)} → ${fmt(latest)}'),
          const Divider(height: AppSpacing.x16, color: AppColors.n100),
          _row('Бюджет работ', Money.format(workBudget)),
          const Divider(height: AppSpacing.x16, color: AppColors.n100),
          _row('Бюджет материалов', Money.format(materialsBudget)),
        ],
      ),
    );
  }

  static Widget _row(String label, String value) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
}

class _PlanStageRow extends StatelessWidget {
  const _PlanStageRow({required this.index, required this.stage});

  final int index;
  final Stage stage;

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? d) =>
        d == null ? '—' : DateFormat('d MMM', 'ru').format(d);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Text(
              '$index',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.brand),
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: AppTextStyles.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmt(stage.plannedStart)} → ${fmt(stage.plannedEnd)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (stage.workBudget > 0 || stage.materialsBudget > 0)
            Text(
              Money.format(stage.workBudget + stage.materialsBudget),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.projectId,
    required this.stages,
    required this.pendingApproval,
    required this.canDecide,
    required this.canRequest,
    required this.planApproved,
  });

  final String projectId;
  final List<Stage> stages;
  final Approval? pendingApproval;
  final bool canDecide;
  final bool canRequest;
  final bool planApproved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (planApproved) return const SizedBox.shrink();
    final pending = pendingApproval;

    if (pending != null) {
      return Column(
        children: [
          if (canDecide) ...[
            AppButton(
              label: 'Согласовать план целиком',
              variant: AppButtonVariant.success,
              onPressed: () =>
                  showApproveSheet(context, ref, approval: pending),
            ),
            const SizedBox(height: AppSpacing.x8),
            AppButton(
              label: 'Запросить корректировку',
              variant: AppButtonVariant.destructive,
              onPressed: () =>
                  showRejectSheet(context, ref, approval: pending),
            ),
          ],
          AppButton(
            label: 'Открыть детали согласования',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.push(
              AppRoutes.approvalDetailWith(pending.id),
            ),
          ),
        ],
      );
    }

    if (!canRequest) return const SizedBox.shrink();
    if (stages.isEmpty) {
      return const AppInlineError(
        message: 'Нечего отправлять — план пуст. Сначала добавьте этапы.',
      );
    }

    return AppButton(
      label: 'Отправить план на согласование',
      onPressed: () => _sendForApproval(context, ref),
    );
  }

  Future<void> _sendForApproval(BuildContext context, WidgetRef ref) async {
    // Подсказка: бэк сам определит addresseeId по ownerId проекта.
    // Если addresseeId требуется явно (как в DTO), пробросим ownerId.
    try {
      final projectAsync = ref.read(projectControllerProvider(projectId));
      final ownerId = projectAsync.value?.ownerId;
      if (ownerId == null) {
        if (!context.mounted) return;
        AppToast.show(
          context,
          message: 'Не удалось определить заказчика проекта.',
          kind: AppToastKind.error,
        );
        return;
      }
      await ref.read(approvalsRepositoryProvider).create(
        projectId: projectId,
        scope: ApprovalScope.plan,
        addresseeId: ownerId,
        payload: {
          'stages': [
            for (final s in stages)
              {
                'stageId': s.id,
                'title': s.title,
                if (s.plannedStart != null)
                  'plannedStart': s.plannedStart!.toIso8601String(),
                if (s.plannedEnd != null)
                  'plannedEnd': s.plannedEnd!.toIso8601String(),
                'workBudget': s.workBudget,
                'materialsBudget': s.materialsBudget,
              },
          ],
        },
      );
      ref.invalidate(approvalsControllerProvider(projectId));
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: 'План отправлен заказчику',
        kind: AppToastKind.success,
      );
    } on ApprovalsException catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }
}
