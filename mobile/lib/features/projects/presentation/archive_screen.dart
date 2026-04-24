import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/projects_list_controller.dart';
import 'card_menu_sheet.dart';
import 'project_card.dart';

/// s-archive — архивные проекты.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(archivedProjectsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Архив',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить архив',
          onRetry: () =>
              ref.read(archivedProjectsProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              title: 'Архив пуст',
              subtitle: 'Архивные проекты появятся здесь.',
              icon: Icons.archive_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(archivedProjectsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x10),
              itemBuilder: (_, i) {
                final p = items[i];
                return ProjectCard(
                  project: p,
                  onTap: () => context.push('/projects/${p.id}'),
                  onMenu: () =>
                      showCardMenuSheet(context, ref, project: p),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
