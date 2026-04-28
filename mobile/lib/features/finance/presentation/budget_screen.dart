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
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../application/budget_controller.dart';
import '../application/payments_controller.dart';
import '../domain/budget.dart';
import '../domain/payment.dart';
import '_widgets/budget_hero_card.dart';
import '_widgets/budget_materials_table.dart';
import '_widgets/budget_stages_card.dart';
import '_widgets/budget_tabs_bar.dart';
import '_widgets/date_range_sheet.dart';
import '_widgets/money_summary_chip.dart';
import '_widgets/payment_row_card.dart';

/// Активный таб бюджета — хранится в ProviderScope `_budgetTabProvider`.
final _budgetTabProvider =
    StateProvider.autoDispose<BudgetTab>((ref) => BudgetTab.payments);

/// Активный date-range для таба «Материалы». Пустой = «Весь проект».
final _materialsRangeProvider =
    StateProvider.autoDispose<DateRange>((ref) => const DateRange());

/// e-budget — главный экран бюджета: hero + 3 таба.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectBudgetProvider(projectId));
    final tab = ref.watch(_budgetTabProvider);
    final canCreatePayment = ref.watch(canInProjectProvider(
      (action: DomainAction.financePaymentCreate, projectId: projectId),
    ));
    final canEditBudget = ref.watch(canInProjectProvider(
      (action: DomainAction.financeBudgetEdit, projectId: projectId),
    ));

    return AppScaffold(
      showBack: true,
      title: 'Бюджет проекта',
      padding: EdgeInsets.zero,
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
                  ? () => context.push(AppRoutes.projectEditWith(projectId))
                  : null,
            );
          }
          return Column(
            children: [
              _Header(budget: b),
              BudgetTabsBar(
                selected: tab,
                onChanged: (t) =>
                    ref.read(_budgetTabProvider.notifier).state = t,
                paymentsCount: 0, // обновится ниже после загрузки выплат
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(projectBudgetProvider(projectId)),
                  child: switch (tab) {
                    BudgetTab.payments => _PaymentsTab(projectId: projectId),
                    BudgetTab.stages => _StagesTab(
                        projectId: projectId,
                        stages: b.stages,
                      ),
                    BudgetTab.materials => _MaterialsTab(projectId: projectId),
                  },
                ),
              ),
              if (tab == BudgetTab.payments && canCreatePayment)
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x16,
                    AppSpacing.x12,
                    AppSpacing.x16,
                    AppSpacing.x16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.n0.withValues(alpha: 0.96),
                    border: const Border(
                      top: BorderSide(color: AppColors.n200),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: AppButton(
                      label: 'Новая выплата',
                      icon: Icons.add_rounded,
                      onPressed: () => context
                          .push('/projects/$projectId/payments/new'),
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

/// Hero (общий бюджет + 2 mini-card).
class _Header extends StatelessWidget {
  const _Header({required this.budget});

  final ProjectBudget budget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      child: BudgetHeroCard(
        total: budget.total,
        work: budget.work,
        materials: budget.materials,
      ),
    );
  }
}

/// Таб «Выплаты»: sub-summary chip + список выплат.
class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsControllerProvider(projectId));
    final approvalsAsync = ref.watch(approvalsControllerProvider(projectId));
    return paymentsAsync.when(
      loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить выплаты',
        onRetry: () =>
            ref.invalidate(paymentsControllerProvider(projectId)),
      ),
      data: (payments) {
        final confirmed = payments
            .where((p) => p.status == PaymentStatus.confirmed)
            .fold<int>(0, (a, p) => a + p.effectiveAmount);
        final pending = payments
            .where((p) => p.status == PaymentStatus.pending)
            .fold<int>(0, (a, p) => a + p.effectiveAmount);
        final total = payments.fold<int>(0, (a, p) => a + p.effectiveAmount);

        // Pending-extras (доп.работы) уведомление.
        final pendingExtras = approvalsAsync.value?.pending
                .where((a) => a.scope == ApprovalScope.extraWork)
                .toList() ??
            const <Approval>[];
        final extrasTotal = pendingExtras.fold<int>(
          0,
          (acc, a) => acc + (a.extraPrice ?? 0),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.x10, 0, 100),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
              child: MoneySummaryChip(
                title: 'Итого выплат',
                total: total,
                confirmed: confirmed,
                pending: pending,
              ),
            ),
            if (pendingExtras.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
                child: _PendingExtrasBanner(
                  count: pendingExtras.length,
                  total: extrasTotal,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.x12),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x16,
                  vertical: AppSpacing.x40,
                ),
                child: Text(
                  'Выплат пока нет',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.n400),
                ),
              )
            else
              for (final p in payments) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x16,
                  ),
                  child: PaymentRowCard(
                    payment: p,
                    recipientName: _shorten(p.toUserId),
                    onTap: () =>
                        context.push(AppRoutes.paymentDetailWith(p.id)),
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
          ],
        );
      },
    );
  }

  String _shorten(String userId) =>
      userId.length <= 12 ? userId : '${userId.substring(0, 12)}…';
}

class _PendingExtrasBanner extends StatelessWidget {
  const _PendingExtrasBanner({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
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
            Icons.schedule_rounded,
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
                  '$count запрос(ов) · ${Money.format(total)} — попадут в '
                  'бюджет после согласования заказчиком',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.yellowText,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
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

/// Таб «По этапам»: hero work-only + список этапов.
class _StagesTab extends ConsumerWidget {
  const _StagesTab({required this.projectId, required this.stages});

  final String projectId;
  final List<StageBudget> stages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final statusByStageId = <String, StageStatusBadge>{};
    if (stagesAsync.value != null) {
      for (final s in stagesAsync.value!) {
        statusByStageId[s.id] = _badgeForStatus(s);
      }
    }
    final totalSpent = stages.fold<int>(
      0,
      (acc, s) => acc + s.work.spent + s.materials.spent,
    );
    final totalPlanned = stages.fold<int>(
      0,
      (acc, s) => acc + s.total.planned,
    );
    final totalRemaining = stages.fold<int>(
      0,
      (acc, s) => acc + s.total.remaining,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        BudgetStagesCard(
          stages: stages,
          statusByStageId: statusByStageId,
          onStageTap: (stageId) =>
              context.push('/projects/$projectId/stages/$stageId'),
        ),
        const SizedBox(height: AppSpacing.x12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: AppRadius.card,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Итого по этапам',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.brandDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    Money.format(totalSpent),
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.brandDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: totalPlanned == 0
                      ? 0
                      : (totalSpent / totalPlanned).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Потрачено: ${Money.format(totalSpent)}',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.n500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Остаток: ${Money.format(totalRemaining)}',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x40),
      ],
    );
  }

  StageStatusBadge _badgeForStatus(Stage s) => switch (s.status) {
        StageStatus.done => StageStatusBadge.done,
        StageStatus.active => StageStatusBadge.active,
        StageStatus.paused => StageStatusBadge.paused,
        StageStatus.review => StageStatusBadge.review,
        StageStatus.pending => StageStatusBadge.pending,
        StageStatus.rejected => StageStatusBadge.pending,
      };
}

/// Таб «Материалы»: search + filter chips + date-range chip + table.
class _MaterialsTab extends ConsumerStatefulWidget {
  const _MaterialsTab({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<_MaterialsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(_materialsRangeProvider);
    final query = MoneyFlowQuery(
      projectId: widget.projectId,
      from: range.from,
      to: range.to,
    );
    final flowAsync = ref.watch(moneyFlowFilteredProvider(query));
    return flowAsync.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить',
        onRetry: () => ref.invalidate(moneyFlowFilteredProvider(query)),
      ),
      data: (flow) {
        final allRows = flow.materialPurchases
            .map(
              (m) => BudgetMaterialsRow(
                title: m.title,
                subtitle: '${m.itemCount} позиций',
                qtyLabel: '${m.itemCount}',
                amount: m.totalSpent,
              ),
            )
            .toList();
        final spRows = flow.approvedSelfpurchases
            .map(
              (sp) => BudgetMaterialsRow(
                title: 'Самозакуп: ${sp.byUserName}',
                subtitle: sp.comment ?? 'самозакуп',
                qtyLabel: '—',
                amount: sp.amount,
                highlight: true,
              ),
            )
            .toList();
        final rows = [...allRows, ...spRows]
            .where((r) =>
                _search.isEmpty ||
                r.title.toLowerCase().contains(_search.toLowerCase()) ||
                r.subtitle.toLowerCase().contains(_search.toLowerCase()))
            .toList();
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.x16),
          children: [
            // Search
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.n0,
                border: Border.all(color: AppColors.n200, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppColors.n400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Поиск по материалам',
                        hintStyle: AppTextStyles.caption.copyWith(
                          color: AppColors.n400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            // Date-range chip
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () async {
                    final picked = await showDateRangeSheet(
                      context,
                      initial: range,
                    );
                    if (picked != null) {
                      ref.read(_materialsRangeProvider.notifier).state =
                          picked;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      border:
                          Border.all(color: AppColors.n200, width: 1.5),
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.n600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          range.label(),
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.n600,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x10),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x40),
                child: Text(
                  'Нет покупок за выбранный период',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.n400),
                ),
              )
            else
              BudgetMaterialsTable(rows: rows),
            const SizedBox(height: AppSpacing.x16),
            AppButton(
              label: 'Скачать отчёт по материалам',
              icon: Icons.file_download_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => _showExportSoon(context),
            ),
            const SizedBox(height: AppSpacing.x40),
          ],
        );
      },
    );
  }

  void _showExportSoon(BuildContext context) {
    AppToast.show(
      context,
      message: 'Экспорт отчёта подключим в следующей итерации',
    );
  }
}
