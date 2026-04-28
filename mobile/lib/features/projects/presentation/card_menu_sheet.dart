import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';
import 'copy_project_sheet.dart';

/// s-card-menu — bottom-sheet с действиями над проектом.
///
/// Дизайн `Кластер B`: 3 ряда с цветными 40×40 плашками-иконками
/// (Копировать blue / Редактировать grey / Архивировать yellow), chevron
/// справа. Для архивных — Восстановить + Скачать ZIP.
Future<void> showCardMenuSheet(
  BuildContext context,
  WidgetRef ref, {
  required Project project,
}) async {
  await showAppBottomSheet<void>(
    context: context,
    child: _CardMenuBody(project: project),
  );
}

class _CardMenuBody extends ConsumerWidget {
  const _CardMenuBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(
          title: project.title,
          subtitle: 'Выберите действие',
        ),
        if (!project.isArchived) ...[
          _MenuRow(
            icon: PhosphorIconsRegular.copy,
            iconBg: AppColors.brandLight,
            iconColor: AppColors.brand,
            label: 'Копировать проект',
            onTap: () async {
              Navigator.of(context).pop();
              await showCopyProjectSheet(context, ref, project: project);
            },
          ),
          _MenuRow(
            icon: PhosphorIconsRegular.pencilSimple,
            iconBg: AppColors.n100,
            iconColor: AppColors.n700,
            label: 'Редактировать',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/projects/${project.id}/edit');
            },
          ),
          _MenuRow(
            icon: PhosphorIconsRegular.archive,
            iconBg: AppColors.yellowBg,
            iconColor: AppColors.yellowText,
            label: 'Архивировать',
            onTap: () async {
              Navigator.of(context).pop();
              await _archive(context, ref, project);
            },
          ),
        ] else ...[
          _MenuRow(
            icon: PhosphorIconsRegular.arrowCounterClockwise,
            iconBg: AppColors.brandLight,
            iconColor: AppColors.brand,
            label: 'Восстановить',
            onTap: () async {
              Navigator.of(context).pop();
              await _restore(context, ref, project);
            },
          ),
          _MenuRow(
            icon: PhosphorIconsRegular.fileZip,
            iconBg: AppColors.n100,
            iconColor: AppColors.n700,
            label: 'Скачать ZIP',
            onTap: () {
              Navigator.of(context).pop();
              AppToast.show(context, message: 'ZIP-архив запрошен');
            },
          ),
        ],
      ],
    );
  }
}

Future<void> _archive(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final confirmed = await showAppBottomSheet<bool>(
    context: context,
    child: _ArchiveConfirmBody(projectTitle: project.title),
  );
  if (confirmed ?? false) {
    final failure = await ref
        .read(activeProjectsProvider.notifier)
        .archiveById(project.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null
          ? 'Проект архивирован'
          : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}

Future<void> _restore(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final confirmed = await showAppBottomSheet<bool>(
    context: context,
    child: _RestoreConfirmBody(projectTitle: project.title),
  );
  if (confirmed ?? false) {
    final failure = await ref
        .read(archivedProjectsProvider.notifier)
        .restoreById(project.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null
          ? 'Проект возвращён'
          : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}

/// s-archive-confirm — modal-sheet подтверждения архивации.
class _ArchiveConfirmBody extends StatelessWidget {
  const _ArchiveConfirmBody({required this.projectTitle});

  final String projectTitle;

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
              color: AppColors.yellowBg,
              borderRadius: BorderRadius.circular(AppRadius.r20),
            ),
            child: Icon(
              PhosphorIconsRegular.archive,
              size: 28,
              color: AppColors.yellowText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        const Center(
          child: Text(
            'Архивировать проект?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            projectTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n500,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.x16),
          child: Text(
            'Проект будет скрыт из основного списка. Все данные сохранятся — '
            'вы сможете восстановить его в любой момент из раздела «Архив».',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.n400,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x20),
        AppButton(
          label: 'Да, архивировать',
          variant: AppButtonVariant.destructive,
          icon: PhosphorIconsRegular.archive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _RestoreConfirmBody extends StatelessWidget {
  const _RestoreConfirmBody({required this.projectTitle});

  final String projectTitle;

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
              PhosphorIconsRegular.arrowCounterClockwise,
              size: 28,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        const Center(
          child: Text(
            'Восстановить проект?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '«$projectTitle» вернётся в активные проекты',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n500,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x20),
        AppButton(
          label: 'Восстановить',
          icon: PhosphorIconsBold.arrowCounterClockwise,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x10,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
