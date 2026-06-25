import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../domain/expense.dart';

/// NEWFIX §5 (Егор 23.06.2026) — read-only шторка с деталями расхода/чека.
/// Открывается сразу после добавления и по тапу на расход в «Истории».
Future<void> showExpenseDetailSheet(BuildContext context, Expense expense) {
  return showAppBottomSheet<void>(
    context: context,
    child: _ExpenseDetailBody(expense: expense),
  );
}

class _ExpenseDetailBody extends ConsumerWidget {
  const _ExpenseDetailBody({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages =
        ref.watch(stagesControllerProvider(expense.projectId)).value ??
        const <Stage>[];
    final stageLabel = _stageLabel(stages, expense.stageId);
    final df = DateFormat('d MMMM y · HH:mm', 'ru');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(title: 'Расход'),
          Text(
            Money.format(expense.amount),
            style: AppTextStyles.h1.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            expense.name.isEmpty ? expense.category.displayName : expense.name,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.n600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          _Row(label: 'Категория', value: expense.category.displayName),
          const _Divider(),
          _Row(label: 'Этап', value: stageLabel),
          const _Divider(),
          _Row(label: 'Дата', value: df.format(expense.createdAt.toLocal())),
          if (expense.comment != null &&
              expense.comment!.trim().isNotEmpty) ...[
            const _Divider(),
            _Row(label: 'Комментарий', value: expense.comment!.trim()),
          ],
          if (expense.photoUrl != null) ...[
            const SizedBox(height: AppSpacing.x16),
            const Text('Чек', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              child: CachedNetworkImage(
                imageUrl: expense.photoUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: AppColors.n100,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.n100,
                  alignment: Alignment.center,
                  child: Text(
                    'Не удалось загрузить чек',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.n500,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x8),
        ],
      ),
    );
  }

  String _stageLabel(List<Stage> stages, String? stageId) {
    if (stageId == null) return 'Без этапа';
    for (final s in stages) {
      if (s.id == stageId) {
        return s.title.trim().isNotEmpty
            ? 'Этап ${s.orderIndex + 1}: ${s.title}'
            : 'Этап ${s.orderIndex + 1}';
      }
    }
    return 'Этап';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.n500),
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.n900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.n100);
}
