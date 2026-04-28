import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../exports/data/exports_repository.dart';
import '../../exports/domain/export_job.dart';
import '../../notifications/application/notifications_controller.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';

/// s-archive — список архивных проектов с info-баннером и split-row кнопками.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(archivedProjectsProvider);
    final unread = ref.watch(notificationsProvider).where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: Column(
        children: [
          _Header(
            unreadNotifications: unread,
            onActiveTap: () => context.go(AppRoutes.projects),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить архив',
                onRetry: () =>
                    ref.read(archivedProjectsProvider.notifier).refresh(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _ArchiveEmpty();
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(archivedProjectsProvider.notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    children: [
                      const _InfoBox(
                        text: 'Архивные проекты хранятся бессрочно. '
                            'Данные и фотографии не удаляются.',
                      ),
                      const SizedBox(height: AppSpacing.x16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x4,
                        ),
                        child: Text(
                          '${items.length} ${_pluralize(items.length)} В АРХИВЕ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.n400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      for (var i = 0; i < items.length; i++) ...[
                        AppArchiveCard(
                          title: items[i].title,
                          meta: _meta(items[i]),
                          onRestore: () =>
                              _restore(context, ref, items[i]),
                          onDownload: () =>
                              _downloadZip(context, ref, items[i]),
                        ),
                        if (i < items.length - 1)
                          const SizedBox(height: AppSpacing.x10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _pluralize(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'ОБЪЕКТ';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'ОБЪЕКТА';
    }
    return 'ОБЪЕКТОВ';
  }

  static String _meta(Project p) {
    final df = DateFormat('d MMM yyyy', 'ru');
    final archived = p.archivedAt;
    final progressLabel = p.progressCache >= 100 ? '· 100%' : '';
    return [
      if (archived != null) 'Завершён ${df.format(archived)}',
      progressLabel,
    ].where((s) => s.isNotEmpty).join(' ');
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      child: _RestoreSheet(projectTitle: project.title),
    );
    if (confirmed ?? false) {
      final failure = await ref
          .read(archivedProjectsProvider.notifier)
          .restoreById(project.id);
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: failure == null
            ? 'Проект возвращён в активные'
            : failure.userMessage,
        kind: failure == null ? AppToastKind.success : AppToastKind.error,
      );
    }
  }

  Future<void> _downloadZip(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      child: _DownloadZipSheet(projectTitle: project.title),
    );
    if (confirmed ?? false) {
      try {
        await ref.read(exportsRepositoryProvider).create(
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
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.unreadNotifications,
    required this.onActiveTap,
  });

  final int unreadNotifications;
  final VoidCallback onActiveTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border:
              Border(bottom: BorderSide(color: AppColors.n200, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Мои объекты',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                _IconBtn(
                  icon: PhosphorIconsRegular.question,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/profile/help'),
                ),
                _IconBtn(
                  icon: PhosphorIconsRegular.bell,
                  badge: unreadNotifications,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onActiveTap,
                    behavior: HitTestBehavior.opaque,
                    child: const _Tab(label: 'Активные', active: false),
                  ),
                ),
                const Expanded(
                  child: _Tab(label: 'Архив', active: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: AppColors.n400),
            if (badge != null && badge! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.redDot,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.n0, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge! > 99 ? '99' : '$badge',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.n0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppColors.brand : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.brand : AppColors.n400,
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveEmpty extends StatelessWidget {
  const _ArchiveEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(AppRadius.r24),
              ),
              child: Icon(
                PhosphorIconsRegular.archive,
                size: 36,
                color: AppColors.n400,
              ),
            ),
            const SizedBox(height: AppSpacing.x14),
            const Text(
              'Архив пуст',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Сюда попадают завершённые проекты — '
              'данные и фотографии сохраняются',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestoreSheet extends StatelessWidget {
  const _RestoreSheet({required this.projectTitle});

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
            '«$projectTitle» снова появится в активных',
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

class _DownloadZipSheet extends StatelessWidget {
  const _DownloadZipSheet({required this.projectTitle});

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
              PhosphorIconsRegular.fileZip,
              size: 28,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        const Center(
          child: Text(
            'Скачать ZIP-архив?',
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
            'Соберём «$projectTitle» в один файл — '
            'данные, фото, документы. Уведомим в ленте, когда будет готов.',
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
          label: 'Запросить ZIP',
          variant: AppButtonVariant.success,
          icon: PhosphorIconsBold.downloadSimple,
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
