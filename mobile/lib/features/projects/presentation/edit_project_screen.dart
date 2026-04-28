import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/project_controller.dart';
import '../domain/project.dart';
import 'money_input.dart';

/// s-edit-project — редактирование проекта.
///
/// Дизайн `Кластер B`: одна форма (без wizard) с полями name/address/dates/
/// budget + edit-tag «Изменено» рядом с заголовком при unsaved changes.
class EditProjectScreen extends ConsumerStatefulWidget {
  const EditProjectScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  late final TextEditingController _title;
  late final TextEditingController _address;
  late final TextEditingController _description;
  late final TextEditingController _workBudget;
  late final TextEditingController _materialsBudget;
  DateTime? _plannedStart;
  DateTime? _plannedEnd;
  bool _initialized = false;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  Project? _initial;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController()..addListener(_onChanged);
    _address = TextEditingController()..addListener(_onChanged);
    _description = TextEditingController()..addListener(_onChanged);
    _workBudget = TextEditingController()..addListener(_onChanged);
    _materialsBudget = TextEditingController()..addListener(_onChanged);
  }

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _description.dispose();
    _workBudget.dispose();
    _materialsBudget.dispose();
    super.dispose();
  }

  void _initFrom(Project p) {
    if (_initialized) return;
    _initial = p;
    _title.text = p.title;
    _address.text = p.address ?? '';
    _description.text = p.description ?? '';
    _plannedStart = p.plannedStart;
    _plannedEnd = p.plannedEnd;
    MoneyInput.setFromKopecks(_workBudget, p.workBudget);
    MoneyInput.setFromKopecks(_materialsBudget, p.materialsBudget);
    _initialized = true;
    _dirty = false;
  }

  void _onChanged() {
    if (!_initialized || _initial == null) return;
    final newDirty = _title.text.trim() != _initial!.title ||
        _address.text.trim() != (_initial!.address ?? '') ||
        _description.text.trim() != (_initial!.description ?? '') ||
        MoneyInput.readKopecks(_workBudget) != _initial!.workBudget ||
        MoneyInput.readKopecks(_materialsBudget) != _initial!.materialsBudget;
    if (newDirty != _dirty) setState(() => _dirty = newDirty);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final ctrl = ref.read(projectControllerProvider(widget.projectId).notifier);
    final failure = await ctrl.save(
      title: _title.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      description: _description.text.trim(),
      plannedStart: _plannedStart,
      plannedEnd: _plannedEnd,
      workBudget: MoneyInput.readKopecks(_workBudget),
      materialsBudget: MoneyInput.readKopecks(_materialsBudget),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: 'Изменения сохранены',
        kind: AppToastKind.success,
      );
      context.pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectControllerProvider(widget.projectId));
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.n50,
        body: Center(child: AppLoadingState()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.n50,
        body: AppErrorState(
          title: 'Не удалось загрузить проект',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(projectControllerProvider),
        ),
      ),
      data: (p) {
        _initFrom(p);
        return Scaffold(
          backgroundColor: AppColors.n50,
          body: SafeArea(
            child: Column(
              children: [
                _Header(dirty: _dirty),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.x20),
                    children: [
                      AppInput(
                        controller: _title,
                        label: 'НАЗВАНИЕ',
                        placeholder: 'Например: Квартира на Ленина, 12',
                      ),
                      const SizedBox(height: AppSpacing.x14),
                      AppInput(
                        controller: _address,
                        label: 'АДРЕС',
                        placeholder: 'ул., дом, квартира',
                      ),
                      const SizedBox(height: AppSpacing.x14),
                      const Text(
                        'ПЕРИОД',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.n500,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'СТАРТ',
                              value: _plannedStart,
                              onChanged: (d) {
                                setState(() => _plannedStart = d);
                                _onChanged();
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x10),
                          Expanded(
                            child: _DateField(
                              label: 'ДЕДЛАЙН',
                              value: _plannedEnd,
                              minDate: _plannedStart,
                              onChanged: (d) {
                                setState(() => _plannedEnd = d);
                                _onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x14),
                      const Text(
                        'БЮДЖЕТ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.n500,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: MoneyInput(
                              controller: _workBudget,
                              label: 'РАБОТЫ',
                              hint: '0 ₽',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x10),
                          Expanded(
                            child: MoneyInput(
                              controller: _materialsBudget,
                              label: 'МАТЕРИАЛЫ',
                              hint: '0 ₽',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x14),
                      AppInput(
                        controller: _description,
                        label: 'ОПИСАНИЕ',
                        placeholder: 'Особенности объекта, пожелания, сроки...',
                        maxLines: 5,
                        maxLength: 2000,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.x12),
                        AppInlineError(message: _error!),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Отмена',
                          variant: AppButtonVariant.secondary,
                          onPressed: _saving ? null : () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x10),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: 'Сохранить',
                          icon: PhosphorIconsBold.check,
                          isLoading: _saving,
                          onPressed: _dirty && !_saving ? _save : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dirty});

  final bool dirty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n200, width: 1)),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.n0,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.n200),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  boxShadow: AppShadows.sh1,
                ),
                child: Icon(
                  PhosphorIconsRegular.caretLeft,
                  size: 18,
                  color: AppColors.n700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          const Text(
            'Редактирование',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
              letterSpacing: -0.4,
            ),
          ),
          if (dirty) ...[
            const SizedBox(width: AppSpacing.x8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.yellowBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Изменено',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellowText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? minDate;

  @override
  Widget build(BuildContext context) {
    final formatted =
        value == null ? 'Выберите' : DateFormat('d MMM y', 'ru').format(value!);
    final filled = value != null;
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? minDate ?? now,
          firstDate: minDate ?? DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
          locale: const Locale('ru'),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.n50,
          border: Border.all(
            color: filled ? AppColors.n300 : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.n400,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatted,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: filled ? AppColors.n800 : AppColors.n400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
