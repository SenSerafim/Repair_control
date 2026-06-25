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
    // SingleChildScrollView: 56px icon + header + 4-line TextField + 2 кнопки
    // на узком экране с открытой клавиатурой легко overflow'ят Column.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: AppSpacing.x14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF87171), AppColors.redDot],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x1ADC2626), spreadRadius: 6),
                  BoxShadow(
                    color: Color(0x33DC2626),
                    offset: Offset(0, 8),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.n0,
                size: 28,
              ),
            ),
          ),
          AppBottomSheetHeader(
            title: 'Отклонить работу',
            subtitle: '${widget.hint}\n«${widget.entityName}»',
            centered: true,
          ),
          TextField(
            controller: _ctrl,
            minLines: 4,
            maxLines: 8,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Опишите, что не так...',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n500),
              filled: true,
              fillColor: AppColors.n50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: widget.submitLabel,
            variant: AppButtonVariant.destructive,
            onPressed: text.isEmpty
                ? null
                : () => Navigator.of(context).pop(text),
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
