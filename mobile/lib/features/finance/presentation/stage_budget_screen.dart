import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../stages/application/stages_controller.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';
import 'add_expense_sheet.dart';

/// ТЗ NEWFIX §12: новый экран «Бюджет этапа» — фильтрованный срез
/// общего бюджета проекта по конкретному stageId. Внизу — две
/// быстрые кнопки `+ Чек` / `+ Расход` (обе открывают тот же sheet
/// что и на BudgetScreen, но с предзаполненным stageId).
class StageBudgetScreen extends ConsumerWidget {
  const StageBudgetScreen({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final stage = stagesAsync.value?.firstWhere(
      (s) => s.id == stageId,
      orElse: () => stagesAsync.value!.first,
    );
    final stageTitle = stage == null
        ? 'этап'
        : 'Этап ${stage.orderIndex + 1}: ${stage.title}';
    final filteredAsync = ref.watch(
      _stageExpensesProvider((projectId: projectId, stageId: stageId)),
    );
    return AppScaffold(
      showBack: true,
      title: 'Бюджет этапа',
      padding: EdgeInsets.zero,
      body: filteredAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(
            _stageExpensesProvider((projectId: projectId, stageId: stageId)),
          ),
        ),
        data: (items) {
          final total = items.fold<int>(0, (acc, e) => acc + e.amount);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              _stageExpensesProvider((projectId: projectId, stageId: stageId)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    children: [
                      Text(
                        stageTitle,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x8),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.x14),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ПОТРАЧЕНО НА ЭТАП',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.greenDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Money.format(total),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.n900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x16),
                      if (items.isEmpty)
                        const AppEmptyState(
                          title: 'Расходов по этапу ещё нет',
                          subtitle:
                              'Нажмите «+ Расход» внизу, чтобы записать первую трату.',
                          icon: Icons.receipt_long_outlined,
                        )
                      else
                        for (final e in items) ...[
                          _ExpenseRow(expense: e),
                          const SizedBox(height: AppSpacing.x8),
                        ],
                      const SizedBox(height: AppSpacing.x16),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x16,
                      AppSpacing.x8,
                      AppSpacing.x16,
                      AppSpacing.x12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: '+ Чек',
                            variant: AppButtonVariant.ghost,
                            onPressed: () async {
                              final ok = await showAddExpenseSheet(
                                context,
                                projectId: projectId,
                                initialStageId: stageId,
                              );
                              if (ok) {
                                ref.invalidate(
                                  _stageExpensesProvider((
                                    projectId: projectId,
                                    stageId: stageId,
                                  )),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x8),
                        Expanded(
                          child: AppButton(
                            label: '+ Расход',
                            onPressed: () async {
                              final ok = await showAddExpenseSheet(
                                context,
                                projectId: projectId,
                                initialStageId: stageId,
                              );
                              if (ok) {
                                ref.invalidate(
                                  _stageExpensesProvider((
                                    projectId: projectId,
                                    stageId: stageId,
                                  )),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM', 'ru').format(expense.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              size: 18,
              color: AppColors.n500,
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.n900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr · ${expense.category.displayName}',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Text(
            Money.format(expense.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StageExpenseKey = ({String projectId, String stageId});

final _stageExpensesProvider =
    FutureProvider.family<List<Expense>, _StageExpenseKey>((ref, key) async {
      return ref
          .read(expensesRepositoryProvider)
          .list(projectId: key.projectId, stageId: key.stageId);
    });
