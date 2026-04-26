import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';
import 'card_menu_sheet.dart';
import 'project_card.dart';
import 'projects_filters.dart';

/// s-projects — активные проекты: tabs (Активные/Архив) + search + filter chips.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(projectsFilterProvider);
    final async = ref.watch(filteredActiveProjectsProvider);
    final query = ref.watch(projectsSearchQueryProvider);

    return AppScaffold(
      title: 'Мои объекты',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Присоединиться по коду',
          onPressed: () => context.push(AppRoutes.projectsJoinByCode),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.push(AppRoutes.projectsSearch),
        ),
      ],
      body: Column(
        children: [
          _TopTabs(
            activeIndex: 0,
            onArchiveTap: () => context.push(AppRoutes.projectsArchive),
          ),
          const SizedBox(height: AppSpacing.x8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: _SearchField(
              value: query,
              onChanged: (v) => ref
                  .read(projectsSearchQueryProvider.notifier)
                  .state = v,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          ProjectsFilterChips(
            selected: filter,
            onSelected: (f) =>
                ref.read(projectsFilterProvider.notifier).state = f,
          ),
          const SizedBox(height: AppSpacing.x10),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(
                skeleton: AppListSkeleton(itemHeight: 110),
              ),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить проекты',
                onRetry: () =>
                    ref.read(activeProjectsProvider.notifier).refresh(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    hasFilters:
                        filter != ProjectsFilter.all || query.isNotEmpty,
                    onCreate: () => context.push(AppRoutes.projectsCreate),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(activeProjectsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => _CardTile(project: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottom: null,
      // ignore: deprecated_member_use
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.activeIndex, required this.onArchiveTap});

  final int activeIndex;
  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, {required bool active, required VoidCallback onTap}) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: active ? AppColors.brand : AppColors.n400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
                Container(
                  height: 2.5,
                  color: active ? AppColors.brand : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Активные', active: activeIndex == 0, onTap: () {}),
        tab('Архив', active: activeIndex == 1, onTap: onArchiveTap),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.n400,
        ),
        hintText: 'Поиск по объектам',
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
        filled: true,
        fillColor: AppColors.n0,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
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
  const _EmptyState({required this.hasFilters, required this.onCreate});

  // ignore: avoid_positional_boolean_parameters
  final bool hasFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreate = ref.watch(canProvider(DomainAction.projectCreate));
    if (hasFilters) {
      return const AppEmptyState(
        title: 'Ничего не найдено',
        subtitle: 'Попробуйте изменить поиск или сбросить фильтры.',
        icon: Icons.search_off_rounded,
      );
    }
    return AppEmptyState(
      title: 'Пока нет проектов',
      subtitle:
          'Создайте первый объект — в нём будут этапы, команда и бюджет.',
      icon: Icons.folder_outlined,
      actionLabel: canCreate ? 'Создать проект' : null,
      onAction: canCreate ? onCreate : null,
    );
  }
}
