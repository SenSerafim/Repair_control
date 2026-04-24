import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/project_controller.dart';
import '../data/projects_repository.dart';
import 'money_input.dart';

/// s-create-1 / s-create-2 / s-create-3 — 3-шаговый wizard.
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  int _step = 0;

  // Step 1 fields
  final _title = TextEditingController();
  final _address = TextEditingController();
  final _formStep1 = GlobalKey<FormState>();

  // Step 2 fields
  DateTime? _plannedStart;
  DateTime? _plannedEnd;
  String? _datesError;

  // Step 3 fields
  final _workBudget = TextEditingController();
  final _materialsBudget = TextEditingController();

  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _workBudget.dispose();
    _materialsBudget.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!(_formStep1.currentState?.validate() ?? false)) return;
    } else if (_step == 1) {
      if (_plannedStart != null &&
          _plannedEnd != null &&
          _plannedEnd!.isBefore(_plannedStart!)) {
        setState(() => _datesError = 'Конец должен быть после старта');
        return;
      }
      setState(() => _datesError = null);
    }
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final created = await ref.read(projectCreatorProvider).create(
            title: _title.text.trim(),
            address:
                _address.text.trim().isEmpty ? null : _address.text.trim(),
            plannedStart: _plannedStart,
            plannedEnd: _plannedEnd,
            workBudget: MoneyInput.readKopecks(_workBudget),
            materialsBudget: MoneyInput.readKopecks(_materialsBudget),
          );
      if (!mounted) return;
      context.go('/projects/${created.id}');
      AppToast.show(
        context,
        message: 'Проект создан',
        kind: AppToastKind.success,
      );
    } on ProjectsException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      onBack: _back,
      title: 'Новый объект · ${_step + 1}/3',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.x8),
          _ProgressIndicator(step: _step),
          const SizedBox(height: AppSpacing.x16),
          Expanded(child: _buildStep()),
          if (_submitError != null) ...[
            AppInlineError(message: _submitError!),
            const SizedBox(height: AppSpacing.x12),
          ],
          AppButton(
            label: _step == 2 ? 'Создать' : 'Далее',
            isLoading: _submitting,
            onPressed: _step == 2 ? _submit : _next,
          ),
          const SizedBox(height: AppSpacing.x16),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Step1(formKey: _formStep1, title: _title, address: _address);
      case 1:
        return _Step2(
          plannedStart: _plannedStart,
          plannedEnd: _plannedEnd,
          error: _datesError,
          onStartChanged: (d) => setState(() => _plannedStart = d),
          onEndChanged: (d) => setState(() => _plannedEnd = d),
        );
      case 2:
        return _Step3(
          workBudget: _workBudget,
          materialsBudget: _materialsBudget,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.brand : AppColors.n200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: AppSpacing.x6),
        ],
      ],
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.formKey,
    required this.title,
    required this.address,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController address;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        children: [
          const Text('Как назовём объект?', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Это название увидят все участники проекта.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x20),
          const Text('Название', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextFormField(
            controller: title,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Введите название';
              if (t.length > 200) return 'Максимум 200 символов';
              return null;
            },
            decoration: _dec('Например, Квартира на Ленина'),
          ),
          const SizedBox(height: AppSpacing.x16),
          const Text('Адрес (опционально)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextFormField(
            controller: address,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('ул., дом, квартира'),
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2({
    required this.plannedStart,
    required this.plannedEnd,
    required this.error,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final String? error;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Когда планируем?', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x6),
        const Text(
          'Даты помогут построить светофор по этапам и напомнить о сроках.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x20),
        _DateTile(
          label: 'Планируемый старт',
          value: plannedStart,
          onChanged: onStartChanged,
        ),
        const SizedBox(height: AppSpacing.x12),
        _DateTile(
          label: 'Планируемое завершение',
          value: plannedEnd,
          onChanged: onEndChanged,
          minDate: plannedStart,
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.x12),
          Text(
            error!,
            style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
          ),
        ],
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? minDate;

  @override
  Widget build(BuildContext context) {
    final formatted =
        value == null ? 'Выберите дату' : DateFormat('d MMMM y', 'ru').format(value!);
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? minDate ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate:
              minDate ?? DateTime(now.year - 1, now.month, now.day),
          lastDate: DateTime(now.year + 5),
          locale: const Locale('ru'),
        );
        if (picked != null) onChanged(picked);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x16),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: value == null ? AppColors.n200 : AppColors.brand,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: value == null ? AppColors.n400 : AppColors.brand,
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: AppTextStyles.subtitle.copyWith(
                      color:
                          value == null ? AppColors.n400 : AppColors.n800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  const _Step3({
    required this.workBudget,
    required this.materialsBudget,
  });

  final TextEditingController workBudget;
  final TextEditingController materialsBudget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Бюджет', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x6),
        const Text(
          'Можно указать позже. Суммы отображаются только владельцу '
          'и участникам с правом просмотра финансов.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x20),
        MoneyInput(
          controller: workBudget,
          label: 'Работы',
          hint: 'Сумма за работы',
        ),
        const SizedBox(height: AppSpacing.x16),
        MoneyInput(
          controller: materialsBudget,
          label: 'Материалы',
          hint: 'Сумма на материалы',
        ),
      ],
    );
  }
}

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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.redDot, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.redDot, width: 1.5),
      ),
    );
