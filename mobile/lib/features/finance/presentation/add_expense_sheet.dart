import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../../stages/application/stages_controller.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

/// ТЗ NEWFIX §5.1: bottom-sheet «Добавить расход» (CoinKeeper-flow).
/// Поля сверху вниз: Этап (опц.) · Категория · Название · Сумма · Комментарий.
/// Фото чека отложено в v2 (presign+upload), сразу после первой итерации
/// с заказчиком — добавим image_picker по той же схеме что E1b/4b.
Future<bool> showAddExpenseSheet(
  BuildContext context, {
  required String projectId,
  String? initialStageId,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.n0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
    ),
    builder: (_) => _AddExpenseSheet(
      projectId: projectId,
      initialStageId: initialStageId,
    ),
  );
  return ok ?? false;
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet({required this.projectId, this.initialStageId});

  final String projectId;
  final String? initialStageId;

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _comment = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.materials;
  String? _stageId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stageId = widget.initialStageId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final kopecks = MoneyInput.readKopecks(_amount);
    if (name.isEmpty) {
      setState(() => _error = 'Введите название расхода');
      return;
    }
    if (kopecks == null || kopecks <= 0) {
      setState(() => _error = 'Введите сумму');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(expensesRepositoryProvider).create(
            projectId: widget.projectId,
            category: _category,
            name: name,
            amountKopecks: kopecks,
            stageId: _stageId,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      ref.invalidate(projectExpensesProvider(widget.projectId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ExpensesException catch (e) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить: ${e.failure.name}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x16,
          AppSpacing.x14,
          AppSpacing.x16,
          AppSpacing.x16 + insets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 40,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.n200,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            const Text(
              'Добавить расход',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.x14),
            if (_error != null) ...[
              AppInlineError(message: _error!),
              const SizedBox(height: AppSpacing.x10),
            ],
            const Text('Этап (опционально)', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            _StagePicker(
              projectId: widget.projectId,
              selectedStageId: _stageId,
              onChanged: (id) => setState(() => _stageId = id),
            ),
            const SizedBox(height: AppSpacing.x14),
            const Text('Категория', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in ExpenseCategory.values)
                  ChoiceChip(
                    label: Text(c.displayName),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x14),
            const Text('Название', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'Например, «Цемент М500»',
              ),
            ),
            const SizedBox(height: AppSpacing.x14),
            const Text('Сумма', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            MoneyInput(controller: _amount, label: 'Сумма'),
            const SizedBox(height: AppSpacing.x14),
            const Text(
              'Комментарий (опционально)',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.x6),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(hintText: 'Детали'),
            ),
            const SizedBox(height: AppSpacing.x16),
            AppButton(label: 'Добавить', isLoading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _StagePicker extends ConsumerWidget {
  const _StagePicker({
    required this.projectId,
    required this.selectedStageId,
    required this.onChanged,
  });

  final String projectId;
  final String? selectedStageId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stagesControllerProvider(projectId));
    return async.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Text(
        'Не удалось загрузить этапы',
        style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
      ),
      data: (stages) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceChip(
            label: const Text('Без этапа'),
            selected: selectedStageId == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final s in stages)
            ChoiceChip(
              label: Text('Этап ${s.orderIndex + 1}'),
              selected: selectedStageId == s.id,
              onSelected: (_) => onChanged(s.id),
            ),
        ],
      ),
    );
  }
}
