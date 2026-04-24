import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../application/steps_controller.dart';

/// c-extra-work / s-extra-work-create — доп.работа.
/// После создания backend автоматически создаёт Approval scope=extra_work.
Future<bool> showExtraWorkSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String stageId,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _ExtraWorkBody(projectId: projectId, stageId: stageId),
    isScrollControlled: true,
  );
  return result ?? false;
}

class _ExtraWorkBody extends ConsumerStatefulWidget {
  const _ExtraWorkBody({required this.projectId, required this.stageId});

  final String projectId;
  final String stageId;

  @override
  ConsumerState<_ExtraWorkBody> createState() => _ExtraWorkBodyState();
}

class _ExtraWorkBodyState extends ConsumerState<_ExtraWorkBody> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final priceKop = MoneyInput.readKopecks(_price);
    if (priceKop == null || priceKop <= 0) {
      setState(() => _error = 'Укажите цену доп.работы');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stepsControllerProvider(
          StepsKey(
            projectId: widget.projectId,
            stageId: widget.stageId,
          ),
        ).notifier)
        .createExtra(
          title: _title.text.trim(),
          priceKopecks: priceKop,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Доп.работа отправлена заказчику на согласование',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBottomSheetHeader(
              title: 'Доп.работа',
              subtitle:
                  'Работа сверх плана. Будет создана заявка на '
                  'согласование заказчиком. После одобрения — бюджет '
                  'этапа увеличится автоматически.',
            ),
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
              decoration: _dec('Например, Демонтаж доп. перегородки'),
            ),
            const SizedBox(height: AppSpacing.x12),
            MoneyInput(
              controller: _price,
              label: 'Цена доп.работы',
              hint: 'Сколько стоит',
            ),
            const SizedBox(height: AppSpacing.x12),
            const Text('Описание (опционально)', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 2000,
              decoration: _dec('Что именно и почему нужно сделать?'),
            ),
            const SizedBox(height: AppSpacing.x16),
            AppButton(
              label: 'Отправить заказчику',
              isLoading: _submitting,
              onPressed: _submit,
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
    );
