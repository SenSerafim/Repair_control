import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';

/// Форма добавления инструмента в личный профиль (My Tools).
/// Self-custody модель (2026-05-12): qty=1 — каждый инструмент = одна запись.
/// Добавление в проект делается отдельным флоу на доске инструментов проекта.
class AddToolScreen extends ConsumerStatefulWidget {
  const AddToolScreen({super.key});

  @override
  ConsumerState<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends ConsumerState<AddToolScreen> {
  final _name = TextEditingController();
  final _serial = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _serial.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      AppToast.show(
        context,
        message: 'Введите название',
        kind: AppToastKind.error,
      );
      return;
    }
    setState(() => _busy = true);
    final failure = await ref.read(myToolsProvider.notifier).create(
          name: name,
          serial: _serial.text.trim().isEmpty ? null : _serial.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      AppToast.show(context, message: 'Добавлено', kind: AppToastKind.success);
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
            controller: _serial,
            label: 'Серийный номер',
            placeholder: 'Опционально, например: SN-12345',
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Если у вас несколько одинаковых инструментов — добавьте каждый '
              'отдельной записью, чтобы их можно было отслеживать независимо.',
              style: TextStyle(fontSize: 11, color: AppColors.n400),
            ),
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
