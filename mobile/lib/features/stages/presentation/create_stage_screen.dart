import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../application/stages_controller.dart';
import 'templates_gallery.dart';

/// c-stage-create — 2-табный экран: «Новый» / «Из шаблона».
class CreateStageScreen extends ConsumerStatefulWidget {
  const CreateStageScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CreateStageScreen> createState() =>
      _CreateStageScreenState();
}

class _CreateStageScreenState extends ConsumerState<CreateStageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Новый этап',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.n0,
            child: TabBar(
              controller: _tabs,
              labelStyle: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w800),
              labelColor: AppColors.brand,
              unselectedLabelColor: AppColors.n400,
              indicatorColor: AppColors.brand,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Новый'),
                Tab(text: 'Из шаблона'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _BlankForm(projectId: widget.projectId),
                TemplatesGallery(
                  onPick: (t) async {
                    final applied = await showTemplatePreview(
                      context,
                      ref,
                      template: t,
                      projectId: widget.projectId,
                    );
                    if (applied && context.mounted) {
                      context.pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlankForm extends ConsumerStatefulWidget {
  const _BlankForm({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_BlankForm> createState() => _BlankFormState();
}

class _BlankFormState extends ConsumerState<_BlankForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _workBudget = TextEditingController();
  final _materialsBudget = TextEditingController();
  DateTime? _plannedStart;
  DateTime? _plannedEnd;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _workBudget.dispose();
    _materialsBudget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_plannedStart != null &&
        _plannedEnd != null &&
        _plannedEnd!.isBefore(_plannedStart!)) {
      setState(() => _error = 'Конец должен быть после старта');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stagesControllerProvider(widget.projectId).notifier)
        .create(
          title: _title.text.trim(),
          plannedStart: _plannedStart,
          plannedEnd: _plannedEnd,
          workBudget: MoneyInput.readKopecks(_workBudget),
          materialsBudget: MoneyInput.readKopecks(_materialsBudget),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure != null) {
      setState(() => _error = failure.userMessage);
    } else {
      AppToast.show(
        context,
        message: 'Этап создан',
        kind: AppToastKind.success,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.x16),
        children: [
          if (_error != null) ...[
            AppInlineError(message: _error!),
            const SizedBox(height: AppSpacing.x12),
          ],
          const Text('Название этапа', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Введите название'
                : null,
            decoration: _dec('Например, Электрика'),
          ),
          const SizedBox(height: AppSpacing.x16),
          _DateTile(
            label: 'Плановый старт',
            value: _plannedStart,
            onChanged: (d) => setState(() => _plannedStart = d),
          ),
          const SizedBox(height: AppSpacing.x10),
          _DateTile(
            label: 'Плановое завершение',
            value: _plannedEnd,
            minDate: _plannedStart,
            onChanged: (d) => setState(() => _plannedEnd = d),
          ),
          const SizedBox(height: AppSpacing.x16),
          MoneyInput(controller: _workBudget, label: 'Бюджет работ'),
          const SizedBox(height: AppSpacing.x12),
          MoneyInput(
            controller: _materialsBudget,
            label: 'Бюджет материалов',
          ),
          const SizedBox(height: AppSpacing.x24),
          AppButton(
            label: 'Создать этап',
            isLoading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.x16),
        ],
      ),
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
    final formatted = value == null
        ? 'Выберите дату'
        : DateFormat('d MMMM y', 'ru').format(value!);
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color:
                value == null ? AppColors.n200 : AppColors.brand,
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
                  Text(formatted, style: AppTextStyles.subtitle),
                ],
              ),
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
