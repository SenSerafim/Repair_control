import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/stages_controller.dart';
import '../domain/stage.dart';
import 'stage_widgets.dart';

enum _ViewMode { tile, list }

/// c-stages-tile / c-stages-list / c-stages-empty / c-stages-loading.
///
/// В list-режиме можно drag-and-drop через ReorderableListView.
class StagesScreen extends ConsumerStatefulWidget {
  const StagesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<StagesScreen> createState() => _StagesScreenState();
}

class _StagesScreenState extends ConsumerState<StagesScreen> {
  _ViewMode _mode = _ViewMode.list;

  Future<void> _reorder(List<Stage> current, int oldIndex, int newIndex) async {
    var targetIndex = newIndex;
    if (newIndex > oldIndex) targetIndex -= 1;
    final reordered = [...current];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(targetIndex, moved);
    final newOrder = reordered.map((s) => s.id).toList();
    final failure = await ref
        .read(stagesControllerProvider(widget.projectId).notifier)
        .reorder(newOrder);
    if (failure != null && mounted) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stagesControllerProvider(widget.projectId));

    return AppScaffold(
      showBack: true,
      title: 'Этапы',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: Icon(
            _mode == _ViewMode.tile
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
          ),
          tooltip: _mode == _ViewMode.tile ? 'Список' : 'Плитки',
          onPressed: () => setState(() {
            _mode = _mode == _ViewMode.tile ? _ViewMode.list : _ViewMode.tile;
          }),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(
          skeleton: AppListSkeleton(itemHeight: 128),
        ),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить этапы',
          onRetry: () =>
              ref.invalidate(stagesControllerProvider(widget.projectId)),
        ),
        data: (stages) {
          if (stages.isEmpty) {
            final canManage =
                ref.watch(canProvider(DomainAction.stageManage));
            return AppEmptyState(
              title: 'Пока нет этапов',
              subtitle: 'Создайте этап вручную или применив шаблон.',
              icon: Icons.dashboard_outlined,
              actionLabel: canManage ? 'Добавить этап' : null,
              onAction: canManage
                  ? () => context
                      .push('/projects/${widget.projectId}/stages/create')
                  : null,
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    stagesControllerProvider(widget.projectId),
                  ),
                  child: _mode == _ViewMode.tile
                      ? _TileView(
                          projectId: widget.projectId,
                          stages: stages,
                        )
                      : _ListView(
                          projectId: widget.projectId,
                          stages: stages,
                          onReorder: _reorder,
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.x16),
                decoration: const BoxDecoration(
                  color: AppColors.n0,
                  border: Border(
                    top: BorderSide(color: AppColors.n200),
                  ),
                ),
                child: AppButton(
                  label: 'Добавить этап',
                  onPressed: () => context
                      .push('/projects/${widget.projectId}/stages/create'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({required this.projectId, required this.stages});

  final String projectId;
  final List<Stage> stages;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: stages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) => StageTile(
        stage: stages[i],
        index: i + 1,
        onTap: () =>
            context.push('/projects/$projectId/stages/${stages[i].id}'),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.projectId,
    required this.stages,
    required this.onReorder,
  });

  final String projectId;
  final List<Stage> stages;
  final Future<void> Function(List<Stage>, int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: stages.length,
      buildDefaultDragHandles: false,
      onReorder: (old, nw) => onReorder(stages, old, nw),
      itemBuilder: (_, i) {
        final s = stages[i];
        return Padding(
          key: ValueKey(s.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.x10),
          child: ReorderableDelayedDragStartListener(
            index: i,
            child: StageCard(
              stage: s,
              index: i + 1,
              showDragHandle: true,
              onTap: () => context.push('/projects/$projectId/stages/${s.id}'),
            ),
          ),
        );
      },
    );
  }
}
