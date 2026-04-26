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
    final canCreatePayment = ref.watch(canInProjectProvider(
      (action: DomainAction.financePaymentCreate, projectId: projectId),
    ));
    final canEditBudget = ref.watch(canInProjectProvider(
      (action: DomainAction.financeBudgetEdit, projectId: projectId),
    ));

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
                      // P1.5: «Движение средств» — для customer / canSeeBudget.
                      _MoneyFlowSection(projectId: projectId),
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

/// P1.5: «Движение средств» — детальный money-flow для customer/canSeeBudget.
/// Показывает 4 секции: авансы → распределения → одобренный самозакуп →
/// закупки материалов; внизу — итоги (включая «остаток у бригадира»).
/// Если бекенд вернул пустой объект (роль не имеет права) — секция скрыта.
class _MoneyFlowSection extends ConsumerWidget {
  const _MoneyFlowSection({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(moneyFlowProvider(projectId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (flow) {
        if (flow.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.x16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppRadius.card,
              boxShadow: AppShadows.sh1,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x16,
              ),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.x12),
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.brand,
                  ),
                  SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child:
                        Text('Движение средств', style: AppTextStyles.h2),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Авансы ${Money.format(flow.totals.advances)} · '
                  'Распределено ${Money.format(flow.totals.distributed)}',
                  style: AppTextStyles.caption,
                ),
              ),
              children: [
                if (flow.advances.isNotEmpty)
                  _FlowGroup(
                    title: 'Авансы бригадиру',
                    total: flow.totals.advances,
                    rows: flow.advances
                        .map(
                          (a) => _FlowRow(
                            primary: a.toUserName,
                            secondary: _statusRu(a.status),
                            amount: a.amount,
                          ),
                        )
                        .toList(),
                  ),
                if (flow.distributions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x12),
                  _FlowGroup(
                    title: 'Распределено мастерам',
                    total: flow.totals.distributed,
                    rows: flow.distributions
                        .map(
                          (d) => _FlowRow(
                            primary: d.toUserName,
                            secondary: _statusRu(d.status),
                            amount: d.amount,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (flow.totals.advances > 0) ...[
                  const SizedBox(height: AppSpacing.x10),
                  _RemainderRow(
                    label: 'Остаток у бригадира',
                    amount: flow.totals.undistributed,
                  ),
                ],
                if (flow.approvedSelfpurchases.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x12),
                  _FlowGroup(
                    title: 'Одобренный самозакуп',
                    total: flow.totals.approvedSelfpurchases,
                    rows: flow.approvedSelfpurchases
                        .map(
                          (sp) => _FlowRow(
                            primary: sp.byUserName,
                            secondary: sp.comment ?? '',
                            amount: sp.amount,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (flow.materialPurchases.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x12),
                  _FlowGroup(
                    title: 'Закупки материалов',
                    total: flow.totals.materials,
                    rows: flow.materialPurchases
                        .map(
                          (m) => _FlowRow(
                            primary: m.title,
                            secondary: '${m.itemCount} позиций',
                            amount: m.totalSpent,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusRu(String s) => switch (s) {
        'pending' => 'Ожидает',
        'confirmed' => 'Подтверждено',
        'disputed' => 'Спор',
        'resolved' => 'Закрыто',
        'cancelled' => 'Отменено',
        _ => s,
      };
}

class _FlowGroup extends StatelessWidget {
  const _FlowGroup({
    required this.title,
    required this.total,
    required this.rows,
  });

  final String title;
  final int total;
  final List<_FlowRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.subtitle),
            ),
            Text(
              Money.format(total),
              style: AppTextStyles.subtitle
                  .copyWith(color: AppColors.brandDark),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x6),
        for (final row in rows) ...[
          row,
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.primary,
    required this.secondary,
    required this.amount,
  });

  final String primary;
  final String secondary;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 6),
          child: Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 14,
            color: AppColors.n400,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primary, style: AppTextStyles.body),
              if (secondary.isNotEmpty)
                Text(secondary, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(Money.format(amount), style: AppTextStyles.body),
      ],
    );
  }
}

class _RemainderRow extends StatelessWidget {
  const _RemainderRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final color = isNegative ? AppColors.redText : AppColors.n600;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: isNegative ? AppColors.redBg : AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.caption),
          ),
          Text(
            Money.format(amount),
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
