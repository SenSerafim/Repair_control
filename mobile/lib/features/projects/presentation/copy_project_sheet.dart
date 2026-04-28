import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/project_controller.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// s-copy-project — modal-sheet копирования проекта.
///
/// Дизайн: brand-light круг + copy-icon, поле «Новое название», 3 чек-бокса
/// (Скопировать этапы / шаблоны / команду), кнопки «Создать копию» / «Отмена».
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
  bool _copyStages = true;
  bool _copyTemplates = true;
  bool _copyTeam = false;
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
            newTitle:
                _title.text.trim().isEmpty ? null : _title.text.trim(),
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
      setState(() => _error = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r20),
            ),
            child: Icon(
              PhosphorIconsRegular.copy,
              size: 28,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        const Center(
          child: Text(
            'Копия проекта',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Создадим новый проект на основе текущего',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        if (_error != null) ...[
          AppInlineError(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        AppInput(
          controller: _title,
          label: 'НОВОЕ НАЗВАНИЕ',
          placeholder: 'Как назвать копию?',
        ),
        const SizedBox(height: AppSpacing.x14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'СКОПИРОВАТЬ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n400,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppMenuGroup(
          children: [
            AppMenuRow(
              label: 'Этапы',
              sub: 'Структура: список этапов без статусов',
              trailing: Switch.adaptive(
                value: _copyStages,
                onChanged: (v) => setState(() => _copyStages = v),
                activeColor: AppColors.brand,
              ),
              onTap: () => setState(() => _copyStages = !_copyStages),
            ),
            AppMenuRow(
              label: 'Пользовательские шаблоны',
              sub: 'Сохранённые шаблоны этапов',
              trailing: Switch.adaptive(
                value: _copyTemplates,
                onChanged: (v) => setState(() => _copyTemplates = v),
                activeColor: AppColors.brand,
              ),
              onTap: () => setState(() => _copyTemplates = !_copyTemplates),
            ),
            AppMenuRow(
              label: 'Команда',
              sub: 'Текущие участники получат приглашения',
              trailing: Switch.adaptive(
                value: _copyTeam,
                onChanged: (v) => setState(() => _copyTeam = v),
                activeColor: AppColors.brand,
              ),
              onTap: () => setState(() => _copyTeam = !_copyTeam),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x20),
        AppButton(
          label: 'Создать копию',
          icon: PhosphorIconsBold.copy,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
