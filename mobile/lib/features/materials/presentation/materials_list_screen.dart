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
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../application/materials_controller.dart';
import '../domain/material_request.dart';
import '_widgets/material_card.dart';

// Sentinel для бакета «без этапа» в _StageFilter (общие заявки проекта).
const String _noStageKey = '__no_stage__';

class MaterialsListScreen extends ConsumerStatefulWidget {
  const MaterialsListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends ConsumerState<MaterialsListScreen> {
  // ТЗ NEWFIX §5.8: фильтр по этапам. 'all' = все, _noStageKey = общие
  // (stageId=null), либо конкретный stageId.
  String _stageId = 'all';

  String get projectId => widget.projectId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(materialsControllerProvider(projectId));
    final canCreate = ref.watch(canProvider(DomainAction.materialsManage));
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final stages = stagesAsync.value ?? const <Stage>[];

    return AppScaffold(
      showBack: true,
      title: 'Заявки',
      padding: EdgeInsets.zero,
      actions: [
        if (canCreate)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/projects/$projectId/materials/new'),
          ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(materialsControllerProvider(projectId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: 'Заявок ещё нет',
              subtitle:
                  'Создайте заявку — заказчик согласует её или отклонит. '
                  'Все участники проекта видят решение сразу.',
              icon: Icons.inventory_2_outlined,
              actionLabel: canCreate ? 'Создать заявку' : null,
              onAction: canCreate
                  ? () => context.push('/projects/$projectId/materials/new')
                  : null,
            );
          }
          // ТЗ NEWFIX §5.8: проектный экран — группировка по этапам.
          // Фильтр-чипсы сверху + секции «Этап N · Title» в порядке
          // orderIndex + «Общие материалы проекта» (stageId=null) в конце.
          // Hero-summary: сумма по согласованным + счётчики.
          final totalSpent = items
              .where((r) => r.status == MaterialRequestStatus.approved)
              .fold<int>(0, (acc, r) => acc + r.totalEstimatedPrice);
          final approved = items
              .where((r) => r.status == MaterialRequestStatus.approved)
              .length;
          final filtered = items.where((r) {
            if (_stageId == 'all') return true;
            if (_stageId == _noStageKey) return r.stageId == null;
            return r.stageId == _stageId;
          }).toList();
          final byStage = <String, List<MaterialRequest>>{};
          final shared = <MaterialRequest>[];
          for (final r in filtered) {
            if (r.stageId == null) {
              shared.add(r);
            } else {
              (byStage[r.stageId!] ??= []).add(r);
            }
          }
          final orderedStages = [
            for (final s in stages)
              if ((byStage[s.id] ?? const []).isNotEmpty) s,
          ];

          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(materialsControllerProvider(projectId))
                ..invalidate(stagesControllerProvider(projectId));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                _SummaryChip(
                  totalSpent: totalSpent,
                  count: items.length,
                  approved: approved,
                ),
                const SizedBox(height: AppSpacing.x12),
                _StageFilterChips(
                  activeId: _stageId,
                  stages: stages,
                  hasShared: items.any((r) => r.stageId == null),
                  onSelect: (id) => setState(() => _stageId = id),
                ),
                const SizedBox(height: AppSpacing.x8),
                for (final stage in orderedStages) ...[
                  _SectionHeader(
                    label: 'Этап ${stage.orderIndex + 1} · ${stage.title}',
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  for (final r in byStage[stage.id]!) ...[
                    MaterialCard(
                      request: r,
                      onTap: () => context.push(
                        '/projects/$projectId/materials/${r.id}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                  ],
                  const SizedBox(height: AppSpacing.x10),
                ],
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
    required this.approved,
  });

  final int totalSpent;
  final int count;
  final int approved;

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
                  '$count заявок · $approved согласовано',
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

/// ТЗ NEWFIX §5.8: горизонтальный фильтр-чипсы по этапам на проектном
/// экране заявок. Скрываем «Общие», если в проекте нет ни одной заявки
/// без stageId — чтобы не мусорить интерфейсом.
class _StageFilterChips extends StatelessWidget {
  const _StageFilterChips({
    required this.activeId,
    required this.stages,
    required this.hasShared,
    required this.onSelect,
  });

  final String activeId;
  final List<Stage> stages;
  final bool hasShared;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty && !hasShared) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StageChip(
            label: 'Все этапы',
            selected: activeId == 'all',
            onTap: () => onSelect('all'),
          ),
          const SizedBox(width: AppSpacing.x6),
          for (final s in stages) ...[
            _StageChip(
              label: 'Этап ${s.orderIndex + 1}',
              selected: activeId == s.id,
              onTap: () => onSelect(s.id),
            ),
            const SizedBox(width: AppSpacing.x6),
          ],
          if (hasShared)
            _StageChip(
              label: 'Общие',
              selected: activeId == _noStageKey,
              onTap: () => onSelect(_noStageKey),
            ),
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.tiny.copyWith(
            color: selected ? Colors.white : AppColors.n700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
