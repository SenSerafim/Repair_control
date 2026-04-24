import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/templates_controller.dart';
import '../data/stages_repository.dart';

/// s-save-template — ввод названия + POST /templates/from-stage/:id.
Future<bool> showSaveAsTemplateSheet(
  BuildContext context,
  WidgetRef ref, {
  required String stageId,
  required String defaultTitle,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _SaveBody(stageId: stageId, defaultTitle: defaultTitle),
  );
  return result ?? false;
}

class _SaveBody extends ConsumerStatefulWidget {
  const _SaveBody({required this.stageId, required this.defaultTitle});

  final String stageId;
  final String defaultTitle;

  @override
  ConsumerState<_SaveBody> createState() => _SaveBodyState();
}

class _SaveBodyState extends ConsumerState<_SaveBody> {
  late final TextEditingController _title;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Введите название');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(stagesRepositoryProvider).saveAsTemplate(
            stageId: widget.stageId,
            title: title,
          );
      ref.invalidate(userTemplatesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Шаблон сохранён',
        kind: AppToastKind.success,
      );
    } on StagesException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.failure.userMessage;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Сохранить как шаблон',
          subtitle: 'Шаблон попадёт в раздел «Мои шаблоны» — '
              'можно применить к другим проектам одним нажатием.',
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
        const Text('Название шаблона', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.x6),
        TextField(
          controller: _title,
          decoration: InputDecoration(
            hintText: 'Например, «Электрика стандарт»',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
            filled: true,
            fillColor: AppColors.n0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.n200, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Сохранить',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
