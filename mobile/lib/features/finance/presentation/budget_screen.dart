import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/budget_controller.dart';
import 'budget_widgets.dart';

/// e-budget / e-budget-empty / e-budget-stages / e-budget-materials.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectBudgetProvider(projectId));

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
              subtitle:
                  'Укажите бюджет работ и материалов в настройках проекта.',
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: 'Открыть проект',
              onAction: () =>
                  context.push('/projects/$projectId/edit'),
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
