import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
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
    final canCreate = ref.watch(canProvider(DomainAction.materialsManage));

    return AppScaffold(
      showBack: true,
      title: 'Материалы',
      padding: EdgeInsets.zero,
      actions: [
        if (canCreate)
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
          // ТЗ §5.1 + Gaps §5.1: материалы со `stageId=null` — общие
          // проекта, отдельная секция в списке (бригадир может видеть «по
          // всему проекту», customer — для проектных закупок).
          final shared = items.where((r) => r.stageId == null).toList();
          final perStage = items.where((r) => r.stageId != null).toList();
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(materialsControllerProvider(projectId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                if (shared.isNotEmpty) ...[
                  const _SectionHeader(label: 'Общие материалы проекта'),
                  const SizedBox(height: AppSpacing.x8),
                  for (final r in shared) ...[
                    MaterialRequestCard(
                      request: r,
                      onTap: () => context.push(
                        '/projects/$projectId/materials/${r.id}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                  ],
                  const SizedBox(height: AppSpacing.x12),
                ],
                if (perStage.isNotEmpty) ...[
                  const _SectionHeader(label: 'По этапам'),
                  const SizedBox(height: AppSpacing.x8),
                  for (final r in perStage) ...[
                    MaterialRequestCard(
                      request: r,
                      onTap: () => context.push(
                        '/projects/$projectId/materials/${r.id}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.x4, top: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tiny.copyWith(
          color: AppColors.n400,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
