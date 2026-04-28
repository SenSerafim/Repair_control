import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/project_controller.dart';
import '../data/projects_repository.dart';
import 'money_input.dart';

/// s-create-1 / s-create-2 / s-create-3 — 3-шаговый wizard создания проекта.
///
/// Дизайн `Кластер B`:
/// - Шаг 1: название, адрес, период (старт → дедлайн), описание
/// - Шаг 2: бюджет работ + бюджет материалов + автоматический итог
/// - Шаг 3: чек-лист предустановленных этапов (3 выбраны по умолчанию)
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _pageController = PageController();
  int _step = 1;

  // Step 1 — основное.
  final _title = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  DateTime? _plannedStart;
  DateTime? _plannedEnd;

  // Step 2 — бюджет.
  late final TextEditingController _workBudget;
  late final TextEditingController _materialsBudget;
  final _budgetComment = TextEditingController();

  // Step 3 — этапы.
  final _selectedStages = <_StageTemplate>{
    _StageTemplate.demolition,
    _StageTemplate.electrical,
    _StageTemplate.finishing,
  };

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _workBudget = TextEditingController()
      ..addListener(() => setState(() {}));
    _materialsBudget = TextEditingController()
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _title.dispose();
    _address.dispose();
    _description.dispose();
    _workBudget.dispose();
    _materialsBudget.dispose();
    _budgetComment.dispose();
    super.dispose();
  }

  bool get _canStep1 =>
      _title.text.trim().isNotEmpty && _address.text.trim().isNotEmpty;

  void _next() {
    if (_step < 3) {
      setState(() => _step += 1);
      _pageController.animateToPage(
        _step - 1,
        duration: AppDurations.normal,
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 1) {
      context.pop();
    } else {
      setState(() => _step -= 1);
      _pageController.animateToPage(
        _step - 1,
        duration: AppDurations.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final created = await ref.read(projectCreatorProvider).create(
            title: _title.text.trim(),
            address: _address.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            plannedStart: _plannedStart,
            plannedEnd: _plannedEnd,
            workBudget: MoneyInput.readKopecks(_workBudget),
            materialsBudget: MoneyInput.readKopecks(_materialsBudget),
          );
      if (!mounted) return;
      // TODO: после успеха — POST /api/templates/{id}/apply для каждого
      // _selectedStages.id когда появится batch endpoint.
      AppToast.show(
        context,
        message: 'Проект создан',
        kind: AppToastKind.success,
      );
      context.go('/projects/${created.id}');
    } on ProjectsException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = switch (_step) {
      1 => _canStep1,
      2 => true,
      3 => _selectedStages.isNotEmpty,
      _ => false,
    };

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: SafeArea(
        child: Column(
          children: [
            AppWizardHeader(
              title: _step == 1
                  ? 'Новый объект'
                  : _step == 2
                      ? 'Бюджет проекта'
                      : 'Этапы',
              step: _step,
              totalSteps: 3,
              onBack: _back,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    title: _title,
                    address: _address,
                    description: _description,
                    plannedStart: _plannedStart,
                    plannedEnd: _plannedEnd,
                    onStartChanged: (d) => setState(() => _plannedStart = d),
                    onEndChanged: (d) => setState(() => _plannedEnd = d),
                    onAnyChanged: () => setState(() {}),
                  ),
                  _Step2(
                    workBudget: _workBudget,
                    materialsBudget: _materialsBudget,
                    comment: _budgetComment,
                    onAnyChanged: () => setState(() {}),
                  ),
                  _Step3(
                    selected: _selectedStages,
                    onToggle: (s) => setState(() {
                      if (_selectedStages.contains(s)) {
                        _selectedStages.remove(s);
                      } else {
                        _selectedStages.add(s);
                      }
                    }),
                  ),
                ],
              ),
            ),
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppInlineError(message: _submitError!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton(
                label: _step == 3 ? 'Создать проект' : 'Далее',
                variant: _step == 3
                    ? AppButtonVariant.success
                    : AppButtonVariant.primary,
                icon:
                    _step == 3 ? PhosphorIconsBold.check : null,
                isLoading: _submitting,
                onPressed: canProceed && !_submitting ? _next : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.title,
    required this.address,
    required this.description,
    required this.plannedStart,
    required this.plannedEnd,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onAnyChanged,
  });

  final TextEditingController title;
  final TextEditingController address;
  final TextEditingController description;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final VoidCallback onAnyChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x20),
      children: [
        AppInput(
          controller: title,
          label: 'НАЗВАНИЕ',
          placeholder: 'Например: Квартира на Ленина, 12',
          onChanged: (_) => onAnyChanged(),
        ),
        const SizedBox(height: AppSpacing.x14),
        AppInput(
          controller: address,
          label: 'АДРЕС',
          placeholder: 'ул., дом, квартира',
          onChanged: (_) => onAnyChanged(),
        ),
        const SizedBox(height: AppSpacing.x14),
        const _SectionLabel(text: 'ПЕРИОД'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'СТАРТ',
                value: plannedStart,
                onChanged: onStartChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: _DateField(
                label: 'ДЕДЛАЙН',
                value: plannedEnd,
                minDate: plannedStart,
                onChanged: onEndChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x14),
        AppInput(
          controller: description,
          label: 'ОПИСАНИЕ (НЕОБЯЗАТЕЛЬНО)',
          placeholder: 'Особенности объекта, пожелания, сроки...',
          maxLines: 5,
          maxLength: 2000,
          onChanged: (_) => onAnyChanged(),
        ),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2({
    required this.workBudget,
    required this.materialsBudget,
    required this.comment,
    required this.onAnyChanged,
  });

  final TextEditingController workBudget;
  final TextEditingController materialsBudget;
  final TextEditingController comment;
  final VoidCallback onAnyChanged;

  @override
  Widget build(BuildContext context) {
    final w = MoneyInput.readKopecks(workBudget) ?? 0;
    final m = MoneyInput.readKopecks(materialsBudget) ?? 0;
    final total = w + m;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x20),
      children: [
        Row(
          children: [
            Expanded(
              child: _BudgetCard(
                label: 'РАБОТЫ',
                controller: workBudget,
                onChanged: onAnyChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: _BudgetCard(
                label: 'МАТЕРИАЛЫ',
                controller: materialsBudget,
                onChanged: onAnyChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x14),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            border: Border.all(color: AppColors.brand, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ИТОГО',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
              Text(
                '${_formatRubles(total)} ₽',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        AppInput(
          controller: comment,
          label: 'КОММЕНТАРИЙ (НЕОБЯЗАТЕЛЬНО)',
          placeholder: 'Резерв на непредвиденные расходы, доплаты…',
          maxLines: 3,
          onChanged: (_) => onAnyChanged(),
        ),
      ],
    );
  }

  static String _formatRubles(int kopecks) {
    final rubles = kopecks ~/ 100;
    return NumberFormat.decimalPattern('ru').format(rubles);
  }
}

class _Step3 extends StatelessWidget {
  const _Step3({required this.selected, required this.onToggle});

  final Set<_StageTemplate> selected;
  final ValueChanged<_StageTemplate> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x20),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.x10),
          child: Text(
            'Выберите этапы — потом добавите свои.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n500,
              height: 1.45,
            ),
          ),
        ),
        for (final s in _StageTemplate.values) ...[
          _StageRow(
            template: s,
            selected: selected.contains(s),
            onToggle: () => onToggle(s),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
        const SizedBox(height: AppSpacing.x6),
        AppDashedBorder(
          color: AppColors.n300,
          borderRadius: AppRadius.r12,
          height: 48,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsBold.plus,
                size: 14,
                color: AppColors.n500,
              ),
              const SizedBox(width: 6),
              const Text(
                'Добавить кастомный этап',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.n500,
        letterSpacing: 0.7,
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

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.n50,
        border: Border.all(
          color: controller.text.isEmpty ? AppColors.n200 : AppColors.n300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 4),
          MoneyInput(
            controller: controller,
            hint: '0 ₽',
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.template,
    required this.selected,
    required this.onToggle,
  });

  final _StageTemplate template;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandLight : AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.n200,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brand.withValues(alpha: 0.12)
                      : AppColors.n100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  template.icon,
                  size: 18,
                  color: selected ? AppColors.brand : AppColors.n600,
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Text(
                  template.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.brand : AppColors.n800,
                  ),
                ),
              ),
              _Check(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.n300,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: selected
          ? const Icon(
              PhosphorIconsBold.check,
              size: 14,
              color: AppColors.n0,
            )
          : null,
    );
  }
}

/// Локальный пресет этапов (UI). После создания проекта реальные этапы
/// создаются на бэке через POST /stages для каждого выбранного template'а.
enum _StageTemplate {
  demolition('Демонтаж', PhosphorIconsRegular.hammer),
  electrical('Электрика', PhosphorIconsRegular.lightning),
  plumbing('Сантехника', PhosphorIconsRegular.drop),
  walls('Штукатурка и стяжка', PhosphorIconsRegular.squareHalf),
  flooring('Полы', PhosphorIconsRegular.squaresFour),
  ceiling('Потолки', PhosphorIconsRegular.rectangle),
  finishing('Чистовая отделка', PhosphorIconsRegular.paintBrush),
  doors('Двери', PhosphorIconsRegular.door),
  furniture('Мебель и техника', PhosphorIconsRegular.armchair),
  cleaning('Уборка', PhosphorIconsRegular.broom);

  const _StageTemplate(this.title, this.icon);
  final String title;
  final IconData icon;
}
