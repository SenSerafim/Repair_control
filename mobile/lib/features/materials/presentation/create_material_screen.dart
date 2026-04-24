import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../application/materials_controller.dart';
import '../data/materials_repository.dart';
import '../domain/material_request.dart';

class CreateMaterialScreen extends ConsumerStatefulWidget {
  const CreateMaterialScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CreateMaterialScreen> createState() =>
      _CreateMaterialScreenState();
}

class _CreateMaterialScreenState
    extends ConsumerState<CreateMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _comment = TextEditingController();
  MaterialRecipient _recipient = MaterialRecipient.foreman;
  final _items = <_ItemDraft>[_ItemDraft()];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final items = <MaterialItemInput>[];
    for (final draft in _items) {
      final name = draft.name.text.trim();
      final qty = double.tryParse(draft.qty.text.replaceAll(',', '.'));
      if (name.isEmpty || qty == null || qty <= 0) {
        setState(() => _error = 'Заполните все позиции');
        return;
      }
      items.add(MaterialItemInput(
        name: name,
        qty: qty,
        unit: draft.unit.text.trim().isEmpty
            ? null
            : draft.unit.text.trim(),
        pricePerUnit: MoneyInput.readKopecks(draft.price),
      ));
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(materialsControllerProvider(widget.projectId).notifier)
        .create(
          recipient: _recipient,
          title: _title.text.trim(),
          items: items,
          comment:
              _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: 'Заявка создана',
        kind: AppToastKind.success,
      );
      context.pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Заявка на материалы',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.x16),
            if (_error != null) ...[
              AppInlineError(message: _error!),
              const SizedBox(height: AppSpacing.x12),
            ],
            const Text('Кто покупает', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            Wrap(
              spacing: 8,
              children: [
                for (final r in MaterialRecipient.values)
                  ChoiceChip(
                    label: Text(r.displayName),
                    selected: _recipient == r,
                    onSelected: (_) => setState(() => _recipient = r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text('Название заявки', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _title,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите название'
                  : null,
              decoration: _dec('Например, «Электрика этап 3»'),
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text('Позиции', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.x8),
            for (var i = 0; i < _items.length; i++) ...[
              _ItemCard(
                draft: _items[i],
                index: i + 1,
                canRemove: _items.length > 1,
                onRemove: () => setState(() {
                  _items[i].dispose();
                  _items.removeAt(i);
                }),
              ),
              const SizedBox(height: AppSpacing.x10),
            ],
            AppButton(
              label: 'Добавить позицию',
              variant: AppButtonVariant.ghost,
              onPressed: () => setState(() => _items.add(_ItemDraft())),
            ),
            const SizedBox(height: AppSpacing.x16),
            const Text('Комментарий (опционально)', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _comment,
              maxLines: 3,
              maxLength: 2000,
              decoration: _dec('Детали, адрес магазина…'),
            ),
            const SizedBox(height: AppSpacing.x20),
            AppButton(
              label: 'Создать заявку',
              isLoading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
  }
}

class _ItemDraft {
  final name = TextEditingController();
  final qty = TextEditingController();
  final unit = TextEditingController(text: 'шт');
  final price = TextEditingController();

  void dispose() {
    name.dispose();
    qty.dispose();
    unit.dispose();
    price.dispose();
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final _ItemDraft draft;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.micro
                      .copyWith(color: AppColors.brand),
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: TextFormField(
                  controller: draft.name,
                  decoration: _inlineDec('Название'),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.n400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: draft.qty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inlineDec('Кол-во'),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: TextFormField(
                  controller: draft.unit,
                  decoration: _inlineDec('Ед.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          MoneyInput(
            controller: draft.price,
            label: 'Цена за единицу (опционально)',
          ),
        ],
      ),
    );
  }
}

InputDecoration _inlineDec(String label) => InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.caption,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
    );

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      filled: true,
      fillColor: AppColors.n0,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
    );
