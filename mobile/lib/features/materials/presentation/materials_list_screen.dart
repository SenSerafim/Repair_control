import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../application/materials_controller.dart';
import '../domain/material_request.dart';
import '_widgets/material_card.dart';

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
          // shared (stageId=null) + perStage.
          final shared = items.where((r) => r.stageId == null).toList();
          final perStage = items.where((r) => r.stageId != null).toList();
          // Hero-summary: общая сумма куплено + кол-во заявок и доставок.
          final totalSpent = items.fold<int>(
            0,
            (acc, r) => acc + r.totalBoughtPrice,
          );
          final delivered = items
              .where((r) => r.status == MaterialRequestStatus.delivered)
              .length;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(materialsControllerProvider(projectId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                _SummaryChip(
                  totalSpent: totalSpent,
                  count: items.length,
                  delivered: delivered,
                ),
                const SizedBox(height: AppSpacing.x12),
                if (shared.isNotEmpty) ...[
                  const _SectionHeader(label: 'Общие материалы проекта'),
                  const SizedBox(height: AppSpacing.x8),
                  for (var i = 0; i < shared.length; i++) ...[
                    if (i == 0)
                      TourAnchor(
                        id: 'materials.first_request',
                        child: MaterialCard(
                          request: shared[i],
                          onTap: () => context.push(
                            '/projects/$projectId/materials/${shared[i].id}',
                          ),
                        ),
                      )
                    else
                      MaterialCard(
                        request: shared[i],
                        onTap: () => context.push(
                          '/projects/$projectId/materials/${shared[i].id}',
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
                    MaterialCard(
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.totalSpent,
    required this.count,
    required this.delivered,
  });

  final int totalSpent;
  final int count;
  final int delivered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ИТОГО МАТЕРИАЛОВ',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count заявок · $delivered доставлено',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n500,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Money.format(totalSpent),
            style: AppTextStyles.h2.copyWith(
              color: AppColors.greenDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
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
