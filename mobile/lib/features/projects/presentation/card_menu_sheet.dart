import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../exports/data/exports_repository.dart';
import '../../exports/domain/export_job.dart';
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
    // Видимость операций в меню зависит от прав в этом конкретном проекте,
    // а не от глобальной activeRole (см. ТЗ §1.3 — один пользователь может
    // быть foreman'ом в A и master'ом в B).
    final canEdit = ref.watch(
      canInProjectProvider((
        action: DomainAction.projectEdit,
        projectId: project.id,
      )),
    );
    final canArchive = ref.watch(
      canInProjectProvider((
        action: DomainAction.projectArchive,
        projectId: project.id,
      )),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(
          title: project.title,
          subtitle: 'Выберите действие',
        ),
        if (!project.isArchived) ...[
          if (canEdit)
            _MenuRow(
              icon: PhosphorIconsRegular.copy,
              iconBg: AppColors.brandLight,
              iconColor: AppColors.brand,
              label: 'Копировать проект',
              onTap: () async {
                Navigator.of(context).pop();
                if (!context.mounted) return;
                await showCopyProjectSheet(context, ref, project: project);
              },
            ),
          if (canEdit)
            _MenuRow(
              icon: PhosphorIconsRegular.pencilSimple,
              iconBg: AppColors.n100,
              iconColor: AppColors.n700,
              label: 'Редактировать',
              onTap: () {
                Navigator.of(context).pop();
                if (!context.mounted) return;
                context.push('/projects/${project.id}/edit');
              },
            ),
          if (canArchive)
            _MenuRow(
              icon: PhosphorIconsRegular.archive,
              iconBg: AppColors.yellowBg,
              iconColor: AppColors.yellowText,
              label: 'Архивировать',
              onTap: () async {
                // Захватываем notifier ДО pop'а sheet'а — после Navigator.pop
                // ConsumerWidget этого шита dispose'нется, и `ref` станет
                // невалидным. Без захвата здесь следующий ref.read из
                // confirmAndArchiveProject крашился `Cannot use "ref" after
                // the widget was disposed.` (Riverpod transcript из jira).
                final notifier = ref.read(activeProjectsProvider.notifier);
                Navigator.of(context).pop();
                if (!context.mounted) return;
                await confirmAndArchiveProject(context, notifier, project);
              },
            ),
        ] else ...[
          if (canArchive)
            _MenuRow(
              icon: PhosphorIconsRegular.arrowCounterClockwise,
              iconBg: AppColors.brandLight,
              iconColor: AppColors.brand,
              label: 'Восстановить',
              onTap: () async {
                final notifier = ref.read(archivedProjectsProvider.notifier);
                Navigator.of(context).pop();
                if (!context.mounted) return;
                await _restore(context, notifier, project);
              },
            ),
          _MenuRow(
            icon: PhosphorIconsRegular.fileZip,
            iconBg: AppColors.n100,
            iconColor: AppColors.n700,
            label: 'Скачать ZIP',
            onTap: () async {
              final repo = ref.read(exportsRepositoryProvider);
              Navigator.of(context).pop();
              if (!context.mounted) return;
              await _requestZipExport(context, repo, project);
            },
          ),
        ],
      ],
    );
  }
}

/// Подтверждение архивации + вызов API. Вынесен в публичный helper,
/// чтобы его можно было вызвать не только из меню карточки, но и из
/// «Опасной зоны» на экране редактирования.
///
/// Принимает уже-полученный [ActiveProjectsController] вместо `WidgetRef`,
/// чтобы безопасно работать после `Navigator.pop` родительского sheet'а
/// (ConsumerWidget этого sheet'а уже dispose'нут — `ref.read` падает с
/// `Cannot use "ref" after the widget was disposed`). На стороне вызова
/// notifier берут до pop, потом передают сюда.
///
/// Альтернативный путь — из ConsumerStatefulWidget, где widget жив до
/// финального dispose'а: тогда можно завернуть в локальный helper и
/// получить notifier через `ref.read` прямо тут.
Future<bool> confirmAndArchiveProject(
  BuildContext context,
  ActiveProjectsController notifier,
  Project project,
) async {
  final confirmed = await showAppBottomSheet<bool>(
    context: context,
    child: _ArchiveConfirmBody(projectTitle: project.title),
  );
  if (confirmed ?? false) {
    final failure = await notifier.archiveById(project.id);
    if (!context.mounted) return false;
    AppToast.show(
      context,
      message: failure == null ? 'Проект архивирован' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
    return failure == null;
  }
  return false;
}

/// До этого «Скачать ZIP» в меню карточки только показывал toast
/// «ZIP-архив запрошен» — реального job'а не создавал. Теперь зовём
/// `exports.create(projectZip)` как в архивном экране — пользователь
/// получит уведомление в ленте, когда ZIP будет готов.
Future<void> _requestZipExport(
  BuildContext context,
  ExportsRepository exports,
  Project project,
) async {
  try {
    await exports.create(
      projectId: project.id,
      kind: ExportKind.projectZip,
    );
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: 'ZIP-архив запрошен · уведомим в ленте',
      kind: AppToastKind.success,
    );
  } on ExportsException catch (e) {
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: e.failure.userMessage,
      kind: AppToastKind.error,
    );
  }
}

Future<void> _restore(
  BuildContext context,
  ArchivedProjectsController notifier,
  Project project,
) async {
  final confirmed = await showAppBottomSheet<bool>(
    context: context,
    child: _RestoreConfirmBody(projectTitle: project.title),
  );
  if (confirmed ?? false) {
    final failure = await notifier.restoreById(project.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null ? 'Проект возвращён' : failure.userMessage,
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
