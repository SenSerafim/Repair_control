import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';
import 'card_menu_sheet.dart';
import 'project_card.dart';

/// s-projects — список активных проектов.
///
/// Дизайн `Кластер B` (s-empty / s-projects-loading): «Мои объекты» 22/w800
/// + 2 action-icon-кнопки (?, bell с badge), tabs Активные/Архив (2.5px
/// underline), список ProjectCard.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(filteredActiveProjectsProvider);
    final unread = ref.watch(notificationsProvider).where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: Column(
        children: [
          _Header(
            unreadNotifications: unread,
            activeIndex: 0,
            onArchiveTap: () => context.push(AppRoutes.projectsArchive),
            onJoinByCodeTap: () =>
                context.push(AppRoutes.projectsJoinByCode),
          ),
          Expanded(
            child: async.when(
              loading: () => const _ProjectsSkeleton(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить проекты',
                onRetry: () =>
                    ref.read(activeProjectsProvider.notifier).refresh(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    onCreate: () => context.push(AppRoutes.projectsCreate),
                    onJoinByCode: () =>
                        context.push(AppRoutes.projectsJoinByCode),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(activeProjectsProvider.notifier).refresh(),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.x10),
                          itemBuilder: (_, i) => _CardTile(project: items[i]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          ref.watch(canProvider(DomainAction.projectCreate))
              ? FloatingActionButton(
                  onPressed: () => context.push(AppRoutes.projectsCreate),
                  backgroundColor: AppColors.brand,
                  elevation: 4,
                  child: Icon(
                    PhosphorIconsBold.plus,
                    color: AppColors.n0,
                    size: 24,
                  ),
                )
              : null,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.unreadNotifications,
    required this.activeIndex,
    required this.onArchiveTap,
    required this.onJoinByCodeTap,
  });

  final int unreadNotifications;
  final int activeIndex;
  final VoidCallback onArchiveTap;
  final VoidCallback onJoinByCodeTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                // Доступно всем ролям — присоединиться к проекту по 6-значному
                // коду от заказчика/бригадира/представителя.
                _IconBtn(
                  icon: PhosphorIconsRegular.qrCode,
                  onTap: onJoinByCodeTap,
                ),
                _IconBtn(
                  icon: PhosphorIconsRegular.question,
                  onTap: () => context.push(AppRoutes.profileHelp),
                ),
                _IconBtn(
                  icon: PhosphorIconsRegular.bell,
                  badge: unreadNotifications,
                  onTap: () => context.push(AppRoutes.notifications),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Tab(
                  label: 'Активные',
                  active: activeIndex == 0,
                  onTap: () {},
                ),
                _Tab(
                  label: 'Архив',
                  active: activeIndex == 1,
                  onTap: onArchiveTap,
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
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: AppColors.n400),
            if (badge != null && badge! > 0)
              Positioned(
                top: -2,
                right: -2,
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
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
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
        ),
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProjectCard(
      project: project,
      onTap: () => context.push('/projects/${project.id}'),
      onMenu: () => showCardMenuSheet(context, ref, project: project),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onCreate, required this.onJoinByCode});

  final VoidCallback onCreate;
  final VoidCallback onJoinByCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreate = ref.watch(canProvider(DomainAction.projectCreate));
    final activeRole = ref.watch(
      profileControllerProvider.select((s) => s.valueOrNull?.activeRole),
    );

    final (title, subtitle, icon) = switch (activeRole) {
      SystemRole.representative => (
          'Вас ещё не добавили',
          'Введите 6-значный код от заказчика, или дождитесь, пока вас добавят в проект',
          PhosphorIconsRegular.usersThree,
        ),
      SystemRole.contractor || SystemRole.master => (
          'Нет назначений',
          'Введите 6-значный код от заказчика или бригадира — проект появится здесь сразу',
          PhosphorIconsRegular.wrench,
        ),
      _ => (
          'Нет активных объектов',
          'Создайте первый объект, чтобы управлять ремонтом из любой точки мира',
          PhosphorIconsRegular.house,
        ),
    };

    // Для не-customer ролей даём явный CTA — присоединиться по коду.
    final showJoinByCodeCta = activeRole == SystemRole.contractor ||
        activeRole == SystemRole.master ||
        activeRole == SystemRole.representative;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              child: Icon(icon, size: 36, color: AppColors.n400),
            ),
            const SizedBox(height: AppSpacing.x14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n500,
                height: 1.55,
              ),
            ),
            if (canCreate) ...[
              const SizedBox(height: AppSpacing.x20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AppButton(
                  label: 'Создать первый объект',
                  icon: PhosphorIconsBold.plus,
                  onPressed: onCreate,
                ),
              ),
            ],
            if (showJoinByCodeCta) ...[
              const SizedBox(height: AppSpacing.x20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AppButton(
                  label: 'Присоединиться по коду',
                  icon: PhosphorIconsBold.qrCode,
                  onPressed: onJoinByCode,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectsSkeleton extends StatelessWidget {
  const _ProjectsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x10),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.n0,
              border: Border.all(color: AppColors.n200),
              borderRadius: BorderRadius.circular(AppRadius.r16),
              boxShadow: AppShadows.sh1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 3, color: AppColors.n200),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeletonRow(width: 180, height: 14),
                      const SizedBox(height: 8),
                      const AppSkeletonRow(width: 240, height: 11),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AppSkeletonRow(
                            width: 80,
                            height: 18,
                            radius: 100,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: AppSkeletonRow(height: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const AppSkeletonRow(height: 4, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
