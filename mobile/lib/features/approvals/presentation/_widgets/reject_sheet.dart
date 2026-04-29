import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';

/// Sheet «Отклонить работу» — c-reject-sheet.
///
/// Заголовок + textarea + 2 кнопки. Возвращает текст причины (≥1 символ) или
/// null при отмене.
Future<String?> showRejectSheet(
  BuildContext context, {
  required String entityName,
  String hint = 'Укажите причину отклонения. Бригадир получит уведомление.',
  String submitLabel = 'Отклонить',
}) {
  return showAppBottomSheet<String>(
    context: context,
    child: _RejectBody(
      entityName: entityName,
      hint: hint,
      submitLabel: submitLabel,
    ),
  );
}

class _RejectBody extends StatefulWidget {
  const _RejectBody({
    required this.entityName,
    required this.hint,
    required this.submitLabel,
  });

  final String entityName;
  final String hint;
  final String submitLabel;

  @override
  State<_RejectBody> createState() => _RejectBodyState();
}

class _RejectBodyState extends State<_RejectBody> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _ctrl.text.trim();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBottomSheetHeader(
            title: 'Отклонить работу',
            subtitle: '${widget.hint}\n«${widget.entityName}»',
          ),
          TextField(
            controller: _ctrl,
            minLines: 4,
            maxLines: 8,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Опишите, что не так...',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.brand, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: widget.submitLabel,
            variant: AppButtonVariant.destructive,
            onPressed:
                text.isEmpty ? null : () => Navigator.of(context).pop(text),
          ),
          const SizedBox(height: AppSpacing.x8),
          AppButton(
            label: 'Отмена',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
