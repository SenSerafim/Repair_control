import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/project_controller.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// s-copy-project — bottom-sheet с вводом нового названия копии.
Future<Project?> showCopyProjectSheet(
  BuildContext context,
  WidgetRef ref, {
  required Project project,
}) async {
  return showAppBottomSheet<Project>(
    context: context,
    child: _CopyBody(project: project),
  );
}

class _CopyBody extends ConsumerStatefulWidget {
  const _CopyBody({required this.project});

  final Project project;

  @override
  ConsumerState<_CopyBody> createState() => _CopyBodyState();
}

class _CopyBodyState extends ConsumerState<_CopyBody> {
  late final TextEditingController _title;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: '${widget.project.title} (копия)');
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final copy = await ref.read(projectCreatorProvider).copy(
            widget.project.id,
            newTitle: _title.text.trim().isEmpty ? null : _title.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(copy);
      AppToast.show(
        context,
        message: 'Проект скопирован',
        kind: AppToastKind.success,
      );
    } on ProjectsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.failure.userMessage;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHeader(
          title: 'Копия проекта',
          subtitle:
              'Создадим новый проект с теми же этапами и командой. '
              'Бюджет и даты сбросятся.',
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
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Название', style: AppTextStyles.caption),
        ),
        const SizedBox(height: AppSpacing.x6),
        TextField(
          controller: _title,
          decoration: InputDecoration(
            hintText: 'Как назвать копию?',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
            filled: true,
            fillColor: AppColors.n0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(
                color: AppColors.n200,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(
                color: AppColors.n200,
                width: 1.5,
              ),
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
        const SizedBox(height: AppSpacing.x20),
        AppButton(
          label: 'Скопировать',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
