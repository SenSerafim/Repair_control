import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/project_controller.dart';
import '../domain/project.dart';
import 'money_input.dart';

/// s-edit-project — редактирование всех полей проекта на одном экране.
class EditProjectScreen extends ConsumerStatefulWidget {
  const EditProjectScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<EditProjectScreen> createState() =>
      _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _address;
  late final TextEditingController _workBudget;
  late final TextEditingController _materialsBudget;
  DateTime? _plannedStart;
  DateTime? _plannedEnd;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _address = TextEditingController();
    _workBudget = TextEditingController();
    _materialsBudget = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _workBudget.dispose();
    _materialsBudget.dispose();
    super.dispose();
  }

  void _initFrom(Project p) {
    if (_initialized) return;
    _title.text = p.title;
    _address.text = p.address ?? '';
    _plannedStart = p.plannedStart;
    _plannedEnd = p.plannedEnd;
    MoneyInput.setFromKopecks(_workBudget, p.workBudget);
    MoneyInput.setFromKopecks(_materialsBudget, p.materialsBudget);
    _initialized = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_plannedStart != null &&
        _plannedEnd != null &&
        _plannedEnd!.isBefore(_plannedStart!)) {
      setState(() => _error = 'Дата завершения должна быть позже старта');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(projectControllerProvider(widget.projectId).notifier)
        .save(
          title: _title.text.trim(),
          address:
              _address.text.trim().isEmpty ? null : _address.text.trim(),
          plannedStart: _plannedStart,
          plannedEnd: _plannedEnd,
          workBudget: MoneyInput.readKopecks(_workBudget),
          materialsBudget: MoneyInput.readKopecks(_materialsBudget),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      setState(() => _error = failure.userMessage);
    } else {
      AppToast.show(
        context,
        message: 'Проект обновлён',
        kind: AppToastKind.success,
      );
      await Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectControllerProvider(widget.projectId));

    return AppScaffold(
      showBack: true,
      title: 'Редактирование',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить проект',
          onRetry: () =>
              ref.invalidate(projectControllerProvider(widget.projectId)),
        ),
        data: (project) {
          _initFrom(project);
          if (project.isArchived) {
            return _ArchivedBanner(project: project);
          }
          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.x16,
                bottom: AppSpacing.x24,
              ),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x12),
                    decoration: BoxDecoration(
                      color: AppColors.redBg,
                      borderRadius: AppRadius.card,
                    ),
                    child: Text(
                      _error!,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.redText),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                ],
                const Text('Название', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.x6),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите название'
                      : null,
                  decoration: _dec('Как назовём объект?'),
                ),
                const SizedBox(height: AppSpacing.x12),
                const Text('Адрес', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.x6),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec('ул., дом, квартира'),
                ),
                const SizedBox(height: AppSpacing.x20),
                _DatePickTile(
                  label: 'Старт',
                  value: _plannedStart,
                  onChanged: (d) => setState(() => _plannedStart = d),
                ),
                const SizedBox(height: AppSpacing.x12),
                _DatePickTile(
                  label: 'Завершение',
                  value: _plannedEnd,
                  minDate: _plannedStart,
                  onChanged: (d) => setState(() => _plannedEnd = d),
                ),
                const SizedBox(height: AppSpacing.x20),
                MoneyInput(
                  controller: _workBudget,
                  label: 'Бюджет работ',
                ),
                const SizedBox(height: AppSpacing.x12),
                MoneyInput(
                  controller: _materialsBudget,
                  label: 'Бюджет материалов',
                ),
                const SizedBox(height: AppSpacing.x24),
                AppButton(
                  label: 'Сохранить',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArchivedBanner extends StatelessWidget {
  const _ArchivedBanner({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.x16),
        padding: const EdgeInsets.all(AppSpacing.x20),
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: AppRadius.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_rounded, color: AppColors.n400, size: 32),
            const SizedBox(height: AppSpacing.x12),
            Text(
              'Проект «${project.title}» в архиве',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.x6),
            const Text(
              'Редактирование заблокировано. Чтобы изменить данные — '
              'сначала восстановите проект из архива.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickTile extends StatelessWidget {
  const _DatePickTile({
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
    final formatted = value == null
        ? 'Не выбрана'
        : DateFormat('d MMMM y', 'ru').format(value!);
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? minDate ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: minDate ?? DateTime(now.year - 1, now.month),
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
          border: Border.all(color: AppColors.n200, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.n400,
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(formatted, style: AppTextStyles.subtitle),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.n300,
            ),
          ],
        ),
      ),
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
