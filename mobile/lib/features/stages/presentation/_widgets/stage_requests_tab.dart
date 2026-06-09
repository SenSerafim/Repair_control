import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/api_error.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../materials/application/materials_controller.dart';
import '../../../materials/presentation/_widgets/material_card.dart';

/// Таб «Заявки» в детали этапа (Task 2.1, TZ-фронт §11).
///
/// Берёт общий список заявок проекта через `materialsControllerProvider`
/// и оставляет только привязанные к этому этапу (`stageId == this.stageId`).
/// Общие заявки проекта (stageId == null) сюда не попадают — для них
/// существует экран «Заявки проекта» (materials_list_screen).
///
/// Карточка переиспользует [MaterialCard] из materials-фичи — никакой
/// дубликации row-логики. Тап ведёт на детальный экран заявки.
class StageRequestsTab extends ConsumerWidget {
  const StageRequestsTab({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialsControllerProvider(projectId));
    return async.when(
      loading: () => const AppLoadingState(),
      error: (e, _) {
        // Безопасный subtitle: ApiError.message либо общий retry-prompt.
        // Не дёргаем e.toString() — у части AsyncError приходит null и в UI
        // появляется уродливый «(null)». Аудит уже ловил этот баг.
        final subtitle = e is ApiError
            ? (e.message ?? 'Попробуйте ещё раз')
            : 'Попробуйте ещё раз';
        return AppErrorState(
          title: 'Не удалось загрузить заявки',
          subtitle: subtitle,
          onRetry: () =>
              ref.invalidate(materialsControllerProvider(projectId)),
        );
      },
      data: (items) {
        final filtered = items.where((r) => r.stageId == stageId).toList();
        if (filtered.isEmpty) {
          return const AppEmptyState(
            title: 'Нет заявок на этом этапе',
            subtitle:
                'Создайте заявку с экрана «Заявки проекта».',
            icon: Icons.inventory_2_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(materialsControllerProvider(projectId));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.x16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.x10),
            itemBuilder: (context, i) {
              final r = filtered[i];
              return MaterialCard(
                request: r,
                onTap: () =>
                    context.push('/projects/$projectId/materials/${r.id}'),
              );
            },
          ),
        );
      },
    );
  }
}
