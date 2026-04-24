import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/step_detail_controller.dart';

/// c-add-substep — добавить подшаг (1-1000 символов).
Future<bool> showAddSubstepSheet(
  BuildContext context,
  WidgetRef ref, {
  required StepDetailKey key,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _AddSubstepBody(detailKey: key),
  );
  return result ?? false;
}

class _AddSubstepBody extends ConsumerStatefulWidget {
  const _AddSubstepBody({required this.detailKey});

  final StepDetailKey detailKey;

  @override
  ConsumerState<_AddSubstepBody> createState() => _AddSubstepBodyState();
}

class _AddSubstepBodyState extends ConsumerState<_AddSubstepBody> {
  final _text = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Введите текст подшага');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stepDetailProvider(widget.detailKey).notifier)
        .addSubstep(text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Добавить подшаг',
          subtitle:
              'Разделите работу на мелкие пункты — их удобно отмечать '
              'по мере выполнения.',
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
              style: AppTextStyles.body.copyWith(color: AppColors.redText),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
        ],
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'Что нужно сделать?',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
            filled: true,
            fillColor: AppColors.n0,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.n200, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Добавить',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
