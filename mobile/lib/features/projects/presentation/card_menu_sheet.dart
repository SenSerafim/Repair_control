import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';
import 'copy_project_sheet.dart';

/// s-card-menu — bottom-sheet с действиями над проектом.
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
          subtitle: project.address,
        ),
        if (!project.isArchived) ...[
          _MenuRow(
            icon: Icons.visibility_outlined,
            label: 'Открыть',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/projects/${project.id}');
            },
          ),
          _MenuRow(
            icon: Icons.edit_outlined,
            label: 'Редактировать',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/projects/${project.id}/edit');
            },
          ),
          _MenuRow(
            icon: Icons.copy_outlined,
            label: 'Скопировать',
            onTap: () async {
              Navigator.of(context).pop();
              await showCopyProjectSheet(context, ref, project: project);
            },
          ),
          _MenuRow(
            icon: Icons.archive_outlined,
            label: 'Архивировать',
            destructive: true,
            onTap: () async {
              Navigator.of(context).pop();
              await _archive(context, ref, project);
            },
          ),
        ] else ...[
          _MenuRow(
            icon: Icons.unarchive_outlined,
            label: 'Восстановить',
            onTap: () async {
              Navigator.of(context).pop();
              await _restore(context, ref, project);
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBottomSheetHeader(
          title: 'Архивировать проект?',
          subtitle: '«${project.title}» перестанет появляться '
              'в активных. Вы сможете восстановить его в любой момент.',
        ),
        AppButton(
          label: 'Да, в архив',
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBottomSheetHeader(
          title: 'Вернуть из архива?',
          subtitle: '«${project.title}» снова появится в активных.',
        ),
        AppButton(
          label: 'Да, вернуть',
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.redDot : AppColors.n700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x8,
          vertical: AppSpacing.x14,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.x12),
            Text(label, style: AppTextStyles.subtitle.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
