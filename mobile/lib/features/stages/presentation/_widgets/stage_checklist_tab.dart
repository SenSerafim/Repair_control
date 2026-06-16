import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../approvals/application/approvals_controller.dart';
import '../../../approvals/domain/approval.dart';
import '../../../onboarding/presentation/widgets/tour_anchor.dart';
import '../../../steps/application/steps_controller.dart';
import '../../../steps/domain/step.dart';
import '../../domain/stage.dart';
import '../stage_widgets.dart' show StageDisplayStatus;
import 'checklist_step_row.dart';

/// Body таба «Чек-лист» в детали этапа.
///
/// Активный шаг (первый незавершённый при display==active) рендерится с
/// brand-light bg. Остальные — обычные. При display==pending+нет foreman —
/// все шаги залочены (opacity 0.5).
///
/// NEWFIX-3 §3.1–3.2:
///   • drag-reorder через ReorderableListView.builder. Гейтим тем же
///     сигналом, что и кнопка «+ Шаг» (`onAddStep != null`) — кто может
///     создавать шаги, тот может и переставлять. Бекенд всё равно проверит
///     и вернёт 403, если что.
///   • поле поиска по title шагов над списком. Когда фильтр активен —
///     drag отключён (фильтрованный список != true order, и onReorder
///     сломал бы orderIndex'ы).
class StageChecklistTab extends ConsumerStatefulWidget {
  const StageChecklistTab({
    required this.stage,
    required this.display,
    required this.onStepTap,
    required this.onAddStep,
    required this.onToggleStep,
    super.key,
  });

  final Stage stage;
  final StageDisplayStatus display;
  final void Function(Step step) onStepTap;

  /// `null` означает, что у текущей роли нет права создавать шаги.
  /// Источник истины — StageDetailScreen, который вычисляет это через
  /// canInProjectProvider(stepManage). Здесь только рендерим CTA при
  /// non-null. Никакой дополнительной фильтрации.
  final VoidCallback? onAddStep;
  final void Function(Step step) onToggleStep;

  @override
  ConsumerState<StageChecklistTab> createState() => _StageChecklistTabState();
}

class _StageChecklistTabState extends ConsumerState<StageChecklistTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final display = widget.display;
    final key = StepsKey(projectId: stage.projectId, stageId: stage.id);
    final async = ref.watch(stepsControllerProvider(key));
    final locked =
        display == StageDisplayStatus.pending && stage.foremanIds.isEmpty;
    final canAddStep = widget.onAddStep != null;
    // Drag разрешён когда есть права + этап не залочен + поиск пуст.
    final canReorder = canAddStep && !locked && _query.isEmpty;

    // Task 3.3 (TZ-фронт §7.4): один раз достаём pending approvals по проекту
    // и собираем set step-id'шек, по которым открыто согласование scope=step.
    // ChecklistStepRow получает простой bool и не дёргает провайдер сам —
    // меньше ребилдов, меньше зависимостей внутри строки.
    final approvalsAsync = ref.watch(
      approvalsControllerProvider(stage.projectId),
    );
    final stepsWithPendingApproval = approvalsAsync.maybeWhen(
      data: (b) => b.pending
          .where((a) => a.scope == ApprovalScope.step && a.stepId != null)
          .map((a) => a.stepId!)
          .toSet(),
      orElse: () => <String>{},
    );

    return async.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить шаги',
        onRetry: () => ref.invalidate(stepsControllerProvider(key)),
      ),
      data: (steps) {
        // Полностью пустой этап (без поиска) — показываем красивый
        // empty-state. Поиск не показываем, чтобы не плодить шум.
        if (steps.isEmpty) {
          // Внутри IndexedStack (StackFit.loose + AlignmentDirectional.topStart)
          // SingleChildScrollView сжимается до интринзик-ширины контента и
          // прижимается к левому краю. SizedBox(width: double.infinity)
          // принудительно растягивает на всю ширину таба, чтобы
          // crossAxisAlignment.center внутри AppEmptyState реально центрировал.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: SizedBox(
              width: double.infinity,
              child: AppEmptyState(
                title: 'Шагов пока нет',
                subtitle: canAddStep
                    ? 'Добавьте основной шаг — именно они определяют '
                          'прогресс этапа.'
                    : 'Шаги добавит бригадир этого этапа.',
                icon: Icons.checklist_rounded,
                actionLabel: canAddStep ? 'Добавить шаг' : null,
                onAction: widget.onAddStep,
              ),
            ),
          );
        }

        // Применяем фильтр поиска (case-insensitive по title).
        final q = _query.trim().toLowerCase();
        final visible = q.isEmpty
            ? steps
            : steps.where((s) => s.title.toLowerCase().contains(q)).toList();
        // Первый незавершённый шаг = активный. Считаем по полному списку,
        // чтобы пометка «активный» не зависела от поискового фильтра.
        final activeIdx = steps.indexWhere((s) => s.status != StepStatus.done);
        final activeStepId = activeIdx >= 0 ? steps[activeIdx].id : null;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x16,
                AppSpacing.x12,
                AppSpacing.x16,
                AppSpacing.x8,
              ),
              child: _StepSearchField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x16,
                0,
                AppSpacing.x16,
                AppSpacing.x10,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ЧЕК-ЛИСТ · ${steps.where((s) => s.status == StepStatus.done).length} ИЗ ${steps.length} ШАГОВ',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const _SearchEmpty()
                  : _ChecklistBody(
                      // Key включает режим: пересоздаём при переключении
                      // drag<->plain, чтобы оба ListView'а корректно
                      // disposed/initState'нулись.
                      key: ValueKey(
                        'checklist_body_${canReorder ? 'drag' : 'plain'}',
                      ),
                      steps: visible,
                      activeStepId: activeStepId,
                      stepsWithPendingApproval: stepsWithPendingApproval,
                      locked: locked,
                      display: display,
                      canReorder: canReorder,
                      canAddStep: canAddStep,
                      onStepTap: widget.onStepTap,
                      onToggleStep: widget.onToggleStep,
                      onAddStep: widget.onAddStep,
                      onReorder: canReorder
                          ? (oldIndex, newIndex) =>
                                _handleReorder(steps, oldIndex, newIndex)
                          : null,
                      annotationFor: _annotationFor,
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleReorder(
    List<Step> currentSteps,
    int oldIndex,
    int newIndex,
  ) async {
    var targetIndex = newIndex;
    if (newIndex > oldIndex) targetIndex -= 1;
    final reordered = [...currentSteps];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(targetIndex, moved);
    final newOrder = reordered.map((s) => s.id).toList();
    final key = StepsKey(
      projectId: widget.stage.projectId,
      stageId: widget.stage.id,
    );
    final failure = await ref
        .read(stepsControllerProvider(key).notifier)
        .reorder(newOrder);
    if (failure != null && mounted) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  StepAnnotation? _annotationFor(Step step) {
    if (step.type == StepType.extra &&
        step.status == StepStatus.pendingApproval) {
      return ExtraWorkPendingAnnotation(amountKopecks: step.price ?? 0);
    }
    return null;
  }
}

/// Тело чек-листа: либо ReorderableListView (drag разрешён),
/// либо обычный ListView (поиск активен / нет прав).
class _ChecklistBody extends StatelessWidget {
  const _ChecklistBody({
    required this.steps,
    required this.activeStepId,
    required this.stepsWithPendingApproval,
    required this.locked,
    required this.display,
    required this.canReorder,
    required this.canAddStep,
    required this.onStepTap,
    required this.onToggleStep,
    required this.onAddStep,
    required this.onReorder,
    required this.annotationFor,
    super.key,
  });

  final List<Step> steps;
  final String? activeStepId;
  final Set<String> stepsWithPendingApproval;
  final bool locked;
  final StageDisplayStatus display;
  final bool canReorder;
  final bool canAddStep;
  final void Function(Step step) onStepTap;
  final void Function(Step step) onToggleStep;
  final VoidCallback? onAddStep;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final StepAnnotation? Function(Step step) annotationFor;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AppSpacing.x16,
    0,
    AppSpacing.x16,
    AppSpacing.x16,
  );

  @override
  Widget build(BuildContext context) {
    if (canReorder && onReorder != null) {
      // Add-кнопка как НЕперетаскиваемый footer — отдельным виджетом
      // после ReorderableListView, чтобы не возиться с onReorder, который
      // не должен затрагивать её index.
      return Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: _padding,
              itemCount: steps.length,
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
              itemBuilder: (context, i) {
                final s = steps[i];
                final isActive =
                    !locked &&
                    display == StageDisplayStatus.active &&
                    s.id == activeStepId;
                final row = ChecklistStepRow(
                  step: s,
                  isActive: isActive,
                  locked: locked,
                  executorName: null,
                  completedAt: s.doneAt,
                  annotation: annotationFor(s),
                  substeps: const [],
                  hasPendingApproval: stepsWithPendingApproval.contains(s.id),
                  onTap: () => onStepTap(s),
                  onToggleDone: () => onToggleStep(s),
                );
                final wrapped = ReorderableDelayedDragStartListener(
                  index: i,
                  child: row,
                );
                return KeyedSubtree(
                  key: ValueKey('step_${s.id}'),
                  child: i == 0
                      ? TourAnchor(
                          id: 'stage_detail.first_step',
                          child: wrapped,
                        )
                      : wrapped,
                );
              },
            ),
          ),
          if (canAddStep)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x16,
                0,
                AppSpacing.x16,
                AppSpacing.x16,
              ),
              child: _AddStepCta(locked: locked, onTap: onAddStep),
            ),
        ],
      );
    }

    return ListView.builder(
      padding: _padding,
      itemCount: steps.length + (canAddStep ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= steps.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x8),
            child: _AddStepCta(locked: locked, onTap: onAddStep),
          );
        }
        final s = steps[i];
        final isActive =
            !locked &&
            display == StageDisplayStatus.active &&
            s.id == activeStepId;
        final row = ChecklistStepRow(
          step: s,
          isActive: isActive,
          locked: locked,
          executorName: null,
          completedAt: s.doneAt,
          annotation: annotationFor(s),
          substeps: const [],
          hasPendingApproval: stepsWithPendingApproval.contains(s.id),
          onTap: () => onStepTap(s),
          onToggleDone: () => onToggleStep(s),
        );
        if (i == 0) {
          return TourAnchor(id: 'stage_detail.first_step', child: row);
        }
        return row;
      },
    );
  }
}

/// Кнопка «+ Добавить шаг» — dashed border + brand text.
class _AddStepCta extends StatelessWidget {
  const _AddStepCta({required this.locked, required this.onTap});

  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // QA-баг #7: AppDashedBorder по умолчанию height=160 +
    // padding=16, но контент-стрипа высотой ~50px не растягивался на
    // всю рамку — тап работал только по узкой полосе сверху.
    // Передаём height=null + вручную выравниваем padding, чтобы рамка
    // shrink-wrap'илась под содержимое и вся видимая область была
    // clickable.
    return AppDashedBorder(
      borderRadius: AppRadius.r16,
      color: AppColors.brand,
      height: null,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          onTap: locked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x16,
              vertical: AppSpacing.x14,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: locked ? AppColors.n300 : AppColors.brand,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Добавить шаг',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 13,
                    color: locked ? AppColors.n300 : AppColors.brand,
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

/// Empty-state когда есть шаги, но фильтр не нашёл совпадений.
class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.x16),
      child: SizedBox(
        width: double.infinity,
        child: AppEmptyState(
          title: 'Ничего не найдено',
          subtitle: 'Попробуйте другое название',
          icon: Icons.search_off_rounded,
        ),
      ),
    );
  }
}

/// Поле поиска по шагам. Дизайн перенесён из chats_screen
/// (n50 fill + n200 border + lens + clear).
class _StepSearchField extends StatelessWidget {
  const _StepSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.n200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: AppColors.n400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Поиск шагов',
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.n400,
              ),
            ),
        ],
      ),
    );
  }
}
