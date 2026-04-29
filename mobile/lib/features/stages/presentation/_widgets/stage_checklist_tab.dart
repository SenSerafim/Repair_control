import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/access_guard.dart';
import '../../../../core/access/system_role.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
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
class StageChecklistTab extends ConsumerWidget {
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
  final VoidCallback onAddStep;
  final void Function(Step step) onToggleStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = StepsKey(projectId: stage.projectId, stageId: stage.id);
    final async = ref.watch(stepsControllerProvider(key));
    final locked = display == StageDisplayStatus.pending &&
        stage.foremanIds.isEmpty;
    // Master имеет step.manage только для своих шагов (rbac.matrix.ts:42).
    // Создание новых шагов — прерогатива бригадира/customer-owner. Скрываем
    // кнопку «Добавить шаг» если активная роль — master, чтобы не получать
    // 403 после тапа.
    final canAddStep = ref.watch(activeRoleProvider) != SystemRole.master;

    return async.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить шаги',
        onRetry: () => ref.invalidate(stepsControllerProvider(key)),
      ),
      data: (steps) {
        if (steps.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Column(
              children: [
                AppEmptyState(
                  title: 'Шагов пока нет',
                  subtitle: canAddStep
                      ? 'Добавьте основной шаг — именно они определяют '
                          'прогресс этапа.'
                      : 'Шаги добавит бригадир этого этапа.',
                  icon: Icons.checklist_rounded,
                  actionLabel: canAddStep ? 'Добавить шаг' : null,
                  onAction: canAddStep ? onAddStep : null,
                ),
              ],
            ),
          );
        }
        // Первый незавершённый шаг = активный.
        final activeIdx =
            steps.indexWhere((s) => s.status != StepStatus.done);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x16,
            AppSpacing.x12,
            AppSpacing.x16,
            AppSpacing.x16,
          ),
          children: [
            Text(
              'ЧЕК-ЛИСТ · ${steps.where((s) => s.status == StepStatus.done).length} ИЗ ${steps.length} ШАГОВ',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.n400,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            for (var i = 0; i < steps.length; i++)
              ChecklistStepRow(
                step: steps[i],
                isActive: !locked &&
                    display == StageDisplayStatus.active &&
                    i == activeIdx,
                locked: locked,
                executorName: null,
                completedAt: steps[i].doneAt,
                annotation: _annotationFor(steps[i]),
                substeps: const [],
                onTap: () => onStepTap(steps[i]),
                onToggleDone: () => onToggleStep(steps[i]),
              ),
            if (canAddStep) ...[
              const SizedBox(height: AppSpacing.x8),
              AppDashedBorder(
                borderRadius: AppRadius.r16,
                color: AppColors.brand,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  onTap: locked ? null : onAddStep,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
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
                            color:
                                locked ? AppColors.n300 : AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  StepAnnotation? _annotationFor(Step step) {
    if (step.type == StepType.extra &&
        step.status == StepStatus.pendingApproval) {
      return ExtraWorkPendingAnnotation(
        amountKopecks: step.price ?? 0,
      );
    }
    return null;
  }
}
