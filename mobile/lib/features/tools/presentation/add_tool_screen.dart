import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// NEWFIX-2 §7.1 — Форма добавления инструмента в личный профиль.
/// Поля: название, артикул, серийник, статус, локация (или сотрудник).
class AddToolScreen extends ConsumerStatefulWidget {
  const AddToolScreen({super.key});

  @override
  ConsumerState<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends ConsumerState<AddToolScreen> {
  final _name = TextEditingController();
  final _article = TextEditingController();
  final _serial = TextEditingController();
  final _storage = TextEditingController();
  ToolStatus _status = ToolStatus.inStorage;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _article.dispose();
    _serial.dispose();
    _storage.dispose();
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
          article: _article.text.trim().isEmpty ? null : _article.text.trim(),
          serial: _serial.text.trim().isEmpty ? null : _serial.text.trim(),
          status: _status,
          storageLocation: _status == ToolStatus.inStorage &&
                  _storage.text.trim().isNotEmpty
              ? _storage.text.trim()
              : null,
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
            controller: _article,
            label: 'Артикул',
            placeholder: 'Опционально: GBH 2-26 DRE',
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _serial,
            label: 'Серийный номер',
            placeholder: 'Опционально: SN-12345',
          ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            'Статус',
            style: AppTextStyles.body.copyWith(
              color: AppColors.n800,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          for (final st in [ToolStatus.inStorage, ToolStatus.withEmployee])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x6),
              child: _StatusRow(
                status: st,
                active: _status == st,
                onTap: () => setState(() => _status = st),
              ),
            ),
          if (_status == ToolStatus.inStorage) ...[
            const SizedBox(height: AppSpacing.x12),
            AppInput(
              controller: _storage,
              label: 'Номер места / название склада',
              placeholder: 'Гараж, Склад №1, Балкон…',
            ),
          ],
          if (_status == ToolStatus.withEmployee) ...[
            const SizedBox(height: AppSpacing.x12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Text(
                'Выдача инструмента сотруднику — через профиль сотрудника '
                '(Чаты → Команда → выбрать → «+ Выдать инструмент»). Здесь '
                'мы только заведём карточку, а выдадите позже.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x32),
          AppButton(
            label: 'Добавить',
            icon: PhosphorIconsBold.plus,
            isLoading: _busy,
            // Если выбран with_employee — пока не разрешаем сохранять отсюда:
            // по §9 выдача всегда через профиль сотрудника. Заводим как in_storage.
            onPressed: _status == ToolStatus.withEmployee ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.active,
    required this.onTap,
  });

  final ToolStatus status;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.x12,
            horizontal: AppSpacing.x12,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.brandLight : AppColors.n50,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: active ? AppColors.brand : AppColors.n400,
              ),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: AppTextStyles.body.copyWith(
                  color: active ? AppColors.brand : AppColors.n800,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
