import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../approvals/domain/approval.dart';
import '../application/budget_controller.dart';
import 'budget_widgets.dart';

/// e-budget / e-budget-empty / e-budget-stages / e-budget-materials.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectBudgetProvider(projectId));
    final canCreatePayment =
        ref.watch(canProvider(DomainAction.financePaymentCreate));
    final canEditBudget =
        ref.watch(canProvider(DomainAction.financeBudgetEdit));

    return AppScaffold(
      showBack: true,
      title: 'Бюджет',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          tooltip: 'Выплаты',
          onPressed: () =>
              context.push('/projects/$projectId/payments'),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить бюджет',
          onRetry: () => ref.invalidate(projectBudgetProvider(projectId)),
        ),
        data: (b) {
          final isEmpty = b.total.planned == 0 &&
              b.total.spent == 0 &&
              b.stages.isEmpty;
          if (isEmpty) {
            return AppEmptyState(
              title: 'Бюджет не задан',
              subtitle: canEditBudget
                  ? 'Укажите бюджет работ и материалов в настройках проекта.'
                  : 'Заказчик ещё не задал бюджет — обратитесь к нему.',
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: canEditBudget ? 'Открыть проект' : null,
              onAction: canEditBudget
                  ? () =>
                      context.push(AppRoutes.projectEditWith(projectId))
                  : null,
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(projectBudgetProvider(projectId)),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    children: [
                      BudgetBucketCard(
                        title: 'Всего',
                        bucket: b.total,
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: AppColors.brand,
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      Row(
                        children: [
                          Expanded(
                            child: BudgetBucketCard(
                              title: 'Работы',
                              bucket: b.work,
                              icon: Icons.engineering_outlined,
                              accentColor: AppColors.greenDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x10),
                          Expanded(
                            child: BudgetBucketCard(
                              title: 'Материалы',
                              bucket: b.materials,
                              icon: Icons.inventory_2_outlined,
                              accentColor: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      _PendingExtraWorksCard(projectId: projectId),
                      if (b.stages.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x20),
                        const Text('По этапам', style: AppTextStyles.h2),
                        const SizedBox(height: AppSpacing.x10),
                        for (final s in b.stages) ...[
                          StageBudgetRow(
                            stageBudget: s,
                            onTap: () => context.push(
                              '/projects/$projectId/stages/${s.stageId}',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x8),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.x20),
                    ],
                  ),
                ),
              ),
              if (canCreatePayment)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x16),
                  decoration: const BoxDecoration(
                    color: AppColors.n0,
                    border: Border(top: BorderSide(color: AppColors.n200)),
                  ),
                  child: AppButton(
                    label: 'Новая выплата',
                    onPressed: () => context.push(
                      '/projects/$projectId/payments/new',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Сводка по pending-доп.работам. По ТЗ §4.3 + Gaps §4.1: суммы доп.работ
/// **не** входят в `BudgetBucket.spent`, пока approval не одобрен. Этот
/// блок показывает их отдельно — серым с пометкой «Ожидает одобрения».
class _PendingExtraWorksCard extends ConsumerWidget {
  const _PendingExtraWorksCard({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsControllerProvider(projectId));
    final pendingExtras = approvalsAsync.value?.pending
            .where((a) => a.scope == ApprovalScope.extraWork) ??
        const <Approval>[];
    if (pendingExtras.isEmpty) return const SizedBox.shrink();

    final total = pendingExtras.fold<int>(
      0,
      (acc, a) => acc + (a.extraPrice ?? 0),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_outlined,
            color: AppColors.yellowText,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доп.работы ожидают одобрения',
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.yellowText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pendingExtras.length} запрос(ов) · '
                  '${Money.format(total)} — попадут в бюджет после '
                  'согласования заказчиком',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.yellowText,
                    fontStyle: FontStyle.italic,
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
