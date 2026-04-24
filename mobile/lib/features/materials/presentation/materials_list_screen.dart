import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/materials_controller.dart';
import 'materials_widgets.dart';

class MaterialsListScreen extends ConsumerWidget {
  const MaterialsListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialsControllerProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Материалы',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () =>
              context.push('/projects/$projectId/materials/new'),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () =>
              ref.invalidate(materialsControllerProvider(projectId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            final canCreate =
                ref.watch(canProvider(DomainAction.materialsManage));
            return AppEmptyState(
              title: 'Заявок ещё нет',
              subtitle:
                  'Создайте заявку на материалы — бригадир либо заказчик '
                  'пометит позиции как купленные.',
              icon: Icons.inventory_2_outlined,
              actionLabel: canCreate ? 'Создать заявку' : null,
              onAction: canCreate
                  ? () => context.push('/projects/$projectId/materials/new')
                  : null,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(materialsControllerProvider(projectId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x10),
              itemBuilder: (_, i) => MaterialRequestCard(
                request: items[i],
                onTap: () => context.push(
                  '/projects/$projectId/materials/${items[i].id}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
