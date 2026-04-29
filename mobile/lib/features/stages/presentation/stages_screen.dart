import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/application/project_controller.dart';
import '../application/stages_controller.dart';
import '../domain/stage.dart';
import '_widgets/stage_row_card.dart';
import '_widgets/stage_stripe_card.dart';
import 'stage_widgets.dart' show StageDisplayStatus;

/// c-stages-tile / c-stages-list / c-stages-empty / c-stages-loading.
///
/// Pixel-perfect редизайн под Кластер C: header (project title + subtitle),
/// pill-segmented view-toggle, фильтр-чипы (5 + Без подрядчика), tile/list
/// карточки нового стиля. Drag-and-drop сохранён в list-режиме.
class StagesScreen extends ConsumerStatefulWidget {
  const StagesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<StagesScreen> createState() => _StagesScreenState();
}

enum _ViewMode { tile, list }

enum _Filter {
  all,
  active,
  pending,
  paused,
  done,
  noContractor;

  String get label => switch (this) {
        _Filter.all => 'Все',
        _Filter.active => 'В работе',
        _Filter.pending => 'Ожидает',
        _Filter.paused => 'На паузе',
        _Filter.done => 'Завершён',
        _Filter.noContractor => 'Без подрядчика',
      };

  bool match(Stage s) {
    final display = StageDisplayStatus.of(s);
    return switch (this) {
      _Filter.all => true,
      _Filter.active =>
        display == StageDisplayStatus.active || display == StageDisplayStatus.overdue,
      _Filter.pending => display == StageDisplayStatus.pending ||
          display == StageDisplayStatus.lateStart,
      _Filter.paused => display == StageDisplayStatus.paused,
      _Filter.done => display == StageDisplayStatus.done,
      _Filter.noContractor => s.foremanIds.isEmpty,
    };
  }
}

class _StagesScreenState extends ConsumerState<StagesScreen> {
  _ViewMode _mode = _ViewMode.list;
  _Filter _filter = _Filter.all;

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
    final projectAsync = ref.watch(projectControllerProvider(widget.projectId));

    return AppScaffold(
      showBack: true,
      padding: EdgeInsets.zero,
      // Кастомный title — большой проектный заголовок + subtitle.
      // AppScaffold ожидает `title`, но дизайн требует двухстрочной шапки;
      // используем showBack=false-style + tile-view внутри body для
      // совместимости с existing AppScaffold API (он рендерит back-кнопку).
      title: projectAsync.value?.title ?? 'Этапы',
      body: async.when(
        loading: () => const AppLoadingState(
          skeleton: AppListSkeleton(itemHeight: 96),
        ),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить этапы',
          onRetry: () =>
              ref.invalidate(stagesControllerProvider(widget.projectId)),
        ),
        data: (stages) {
          final canManage =
              ref.watch(canProvider(DomainAction.stageManage));
          final filtered =
              stages.where((s) => _filter.match(s)).toList();
          if (stages.isEmpty) {
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
              _SubtitleBar(stagesCount: stages.length),
              _Toolbar(
                mode: _mode,
                onMode: (m) => setState(() => _mode = m),
                filter: _filter,
                filterCounts: {
                  for (final f in _Filter.values)
                    f: stages.where(f.match).length,
                },
                onFilter: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    stagesControllerProvider(widget.projectId),
                  ),
                  child: filtered.isEmpty
                      ? _FilterEmpty(filter: _filter)
                      : _mode == _ViewMode.tile
                          ? _TileView(
                              projectId: widget.projectId,
                              stages: filtered,
                            )
                          : _ListView(
                              projectId: widget.projectId,
                              stages: filtered,
                              filter: _filter,
                              onReorder: _filter == _Filter.all
                                  ? (o, n) =>
                                      _reorder(filtered, o, n)
                                  : null,
                            ),
                ),
              ),
              if (canManage)
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x16,
                    AppSpacing.x12,
                    AppSpacing.x16,
                    AppSpacing.x16,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.n0,
                    border: Border(
                      top: BorderSide(color: AppColors.n200),
                    ),
                  ),
                  child: AppButton(
                    label: 'Добавить этап',
                    icon: Icons.add_rounded,
                    onPressed: () => context
                        .push('/projects/${widget.projectId}/stages/create'),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          tooltip: 'Уведомления',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
      ],
    );
  }
}

class _SubtitleBar extends StatelessWidget {
  const _SubtitleBar({required this.stagesCount});

  final int stagesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x20,
        0,
        AppSpacing.x16,
        AppSpacing.x12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n100)),
      ),
      child: Text(
        'Этапы проекта · $stagesCount',
        style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.mode,
    required this.onMode,
    required this.filter,
    required this.filterCounts,
    required this.onFilter,
  });

  final _ViewMode mode;
  final ValueChanged<_ViewMode> onMode;
  final _Filter filter;
  final Map<_Filter, int> filterCounts;
  final ValueChanged<_Filter> onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.n0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x10,
      ),
      child: Row(
        children: [
          _PillSegmented(
            mode: mode,
            onChange: onMode,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _Filter.values.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.x6),
                    _Chip(
                      filter: _Filter.values[i],
                      active: filter == _Filter.values[i],
                      count:
                          filterCounts[_Filter.values[i]] ?? 0,
                      onTap: () => onFilter(_Filter.values[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSegmented extends StatelessWidget {
  const _PillSegmented({required this.mode, required this.onChange});

  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segBtn(_ViewMode.tile, Icons.grid_view_rounded),
          _segBtn(_ViewMode.list, Icons.format_list_bulleted_rounded),
        ],
      ),
    );
  }

  Widget _segBtn(_ViewMode m, IconData icon) {
    final active = m == mode;
    return GestureDetector(
      onTap: () => onChange(m),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 28,
        alignment: Alignment.center,
        decoration: active
            ? BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppShadows.sh1,
              )
            : null,
        child: Icon(
          icon,
          size: 16,
          color: active ? AppColors.n700 : AppColors.n400,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.filter,
    required this.active,
    required this.count,
    required this.onTap,
  });

  final _Filter filter;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.n0 : AppColors.n600;
    final label = filter == _Filter.all ? '${filter.label} ($count)' : filter.label;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? null : AppColors.n0,
            gradient: active ? AppGradients.brandButton : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: active
                ? null
                : Border.all(color: AppColors.n200, width: 1.5),
            boxShadow: active ? AppShadows.shBlue : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'По фильтру «${filter.label}» этапов нет',
      subtitle: 'Попробуйте другой фильтр или добавьте новый этап.',
      icon: Icons.filter_alt_off_outlined,
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x10,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      itemCount: stages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) {
        final s = stages[i];
        return StageStripeCard(
          stage: s,
          display: StageDisplayStatus.of(s),
          orderIndex: i + 1,
          onTap: () => context.push('/projects/$projectId/stages/${s.id}'),
          foremanName: null,
          stepsTotal: 0,
          stepsDone: (s.progressCache / 100 * 0).round(),
        );
      },
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.projectId,
    required this.stages,
    required this.filter,
    required this.onReorder,
  });

  final String projectId;
  final List<Stage> stages;
  final _Filter filter;

  /// Если null — drag-reorder отключён (когда применён фильтр).
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    if (onReorder == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x16,
          AppSpacing.x10,
          AppSpacing.x16,
          AppSpacing.x16,
        ),
        itemCount: stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x8),
        itemBuilder: (_, i) {
          final s = stages[i];
          return StageRowCard(
            stage: s,
            display: StageDisplayStatus.of(s),
            onTap: () =>
                context.push('/projects/$projectId/stages/${s.id}'),
            foremanName: null,
          );
        },
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x10,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      itemCount: stages.length,
      buildDefaultDragHandles: false,
      onReorder: onReorder!,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, c) {
          final t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1.0 + 0.03 * t,
            child: Material(
              color: Colors.transparent,
              elevation: 8 * t,
              borderRadius: AppRadius.card,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: Opacity(opacity: 0.95, child: c),
            ),
          );
        },
        child: child,
      ),
      itemBuilder: (_, i) {
        final s = stages[i];
        return Padding(
          key: ValueKey(s.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.x8),
          child: ReorderableDelayedDragStartListener(
            index: i,
            child: StageRowCard(
              stage: s,
              display: StageDisplayStatus.of(s),
              onTap: () =>
                  context.push('/projects/$projectId/stages/${s.id}'),
              reorderable: true,
              foremanName: null,
            ),
          ),
        );
      },
    );
  }
}
