import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../team/application/team_controller.dart';
import '../application/tools_controller.dart';
import '../domain/responsible_resolver.dart';
import '../domain/tool.dart';

/// NEWFIX-2 §7.1 — Форма добавления инструмента в личный профиль.
/// Поля: название, артикул, серийник, статус, локация (или сотрудник).
///
/// NEWFIX TЗ-2 §8.3 (Task 6.4): если экран открыт в контексте проекта
/// ([projectId] != null) и выбран статус «у сотрудника», ответственный
/// заполняется бригадиром проекта по умолчанию (но пользователь может
/// поменять). Если бригадира в проекте нет — оставляем поле пустым.
class AddToolScreen extends ConsumerStatefulWidget {
  const AddToolScreen({this.projectId, super.key});

  /// Если задан — форма открыта в контексте проекта (например, со страницы
  /// «Инструменты проекта»). В этом случае «ответственный сотрудник»
  /// pre-fill'ится бригадиром проекта.
  ///
  /// `null` — обычный flow «Мои инструменты» (без pre-fill).
  final String? projectId;

  @override
  ConsumerState<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends ConsumerState<AddToolScreen> {
  final _name = TextEditingController();
  final _article = TextEditingController();
  final _serial = TextEditingController();
  final _storage = TextEditingController();
  ToolStatus _status = ToolStatus.inStorage;
  DateTime? _purchaseDate;
  ToolCondition? _condition;
  bool _busy = false;

  /// NEWFIX TЗ-2 §8.3 — id ответственного сотрудника (только когда
  /// статус = `withEmployee`). Если экран открыт с `projectId`, инициализируется
  /// бригадиром проекта; иначе остаётся null. Перезаписывается выбором юзера.
  String? _assignedEmployeeId;

  /// Был ли уже выполнен pre-fill из teamControllerProvider — чтобы не
  /// переписывать выбор пользователя при последующих ребилдах.
  bool _foremanPrefillApplied = false;

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
          assignedEmployeeId:
              _status == ToolStatus.withEmployee ? _assignedEmployeeId : null,
          purchaseDate: _purchaseDate,
          condition: _condition,
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
    // NEWFIX TЗ-2 §8.3 (Task 6.4): когда экран открыт в контексте проекта,
    // подписываемся на teamControllerProvider и pre-fill'им бригадира как
    // ответственного сотрудника. Делаем только один раз, чтобы не затирать
    // выбор пользователя.
    final projectId = widget.projectId;
    if (projectId != null && !_foremanPrefillApplied) {
      final teamAsync = ref.watch(teamControllerProvider(projectId));
      final foremanId = teamAsync.maybeWhen(
        data: (s) => resolveProjectForemanId(s.members),
        orElse: () => null,
      );
      if (foremanId != null) {
        _assignedEmployeeId = foremanId;
        _foremanPrefillApplied = true;
      }
    }

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
          const SizedBox(height: AppSpacing.x12),
          _PurchaseDateField(
            value: _purchaseDate,
            onChanged: (d) => setState(() => _purchaseDate = d),
          ),
          const SizedBox(height: AppSpacing.x12),
          _ConditionField(
            value: _condition,
            onChanged: (c) => setState(() => _condition = c),
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
            if (widget.projectId != null && _assignedEmployeeId != null) ...[
              // NEWFIX TЗ-2 §8.3: pre-fill бригадира как ответственного.
              Container(
                padding: const EdgeInsets.all(AppSpacing.x12),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Text(
                  'По умолчанию — бригадир',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else ...[
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
          ],
          const SizedBox(height: AppSpacing.x32),
          AppButton(
            label: 'Добавить',
            icon: PhosphorIconsBold.plus,
            isLoading: _busy,
            // Личный flow (projectId == null): withEmployee без явного выбора
            // ответственного сохранять нельзя (§9 — выдача через профиль).
            // В контексте проекта (projectId != null) — разрешаем: бригадир
            // уже подставлен по умолчанию.
            onPressed: _status == ToolStatus.withEmployee &&
                    (widget.projectId == null || _assignedEmployeeId == null)
                ? null
                : _save,
          ),
        ],
      ),
    );
  }
}

class _PurchaseDateField extends StatelessWidget {
  const _PurchaseDateField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Опционально'
        : DateFormat('d MMM y', 'ru').format(value!);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2000),
          lastDate: now,
          locale: const Locale('ru'),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          color: AppColors.n50,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Дата покупки',
                    style: AppTextStyles.caption.copyWith(color: AppColors.n400),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: AppTextStyles.body.copyWith(
                      color: value == null ? AppColors.n400 : AppColors.n800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(null),
              )
            else
              const Icon(Icons.calendar_today, size: 18, color: AppColors.n400),
          ],
        ),
      ),
    );
  }
}

class _ConditionField extends StatelessWidget {
  const _ConditionField({required this.value, required this.onChanged});

  final ToolCondition? value;
  final ValueChanged<ToolCondition?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ToolCondition?>(
          isExpanded: true,
          value: value,
          hint: Text(
            'Состояние (опционально)',
            style: AppTextStyles.body.copyWith(color: AppColors.n400),
          ),
          items: [
            DropdownMenuItem<ToolCondition?>(
              value: null,
              child: Text(
                '— не указано —',
                style: AppTextStyles.body.copyWith(color: AppColors.n400),
              ),
            ),
            for (final c in ToolCondition.values)
              DropdownMenuItem<ToolCondition?>(
                value: c,
                child: Text(c.displayName),
              ),
          ],
          onChanged: onChanged,
        ),
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
