import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';

/// s-tool-add — форма добавления инструмента (Название/Кол-во/Описание).
class AddToolScreen extends ConsumerStatefulWidget {
  const AddToolScreen({super.key});

  @override
  ConsumerState<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends ConsumerState<AddToolScreen> {
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _desc = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final qty = int.tryParse(_qty.text);
    if (name.isEmpty) {
      AppToast.show(context, message: 'Введите название', kind: AppToastKind.error);
      return;
    }
    if (qty == null || qty <= 0) {
      AppToast.show(context,
          message: 'Количество — целое > 0', kind: AppToastKind.error);
      return;
    }
    setState(() => _busy = true);
    final failure = await ref.read(myToolsProvider.notifier).create(
          name: name,
          totalQty: qty,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      AppToast.show(context, message: '✓ Добавлено', kind: AppToastKind.success);
      context.pop();
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Добавить инструмент',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
        children: [
          AppInput(
            controller: _name,
            label: 'Название',
            placeholder: 'Например: Перфоратор Bosch GBH 2-26',
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _qty,
            label: 'Количество',
            placeholder: '1',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _desc,
            label: 'Описание (необязательно)',
            placeholder: 'Серийный номер, характеристики...',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.x32),
          AppButton(
            label: 'Добавить',
            icon: PhosphorIconsBold.plus,
            isLoading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
