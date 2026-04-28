import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/application/project_controller.dart';
import '../../steps/application/steps_controller.dart';
import '../../steps/domain/step.dart';
import '../../steps/presentation/extra_work_sheet.dart';
import '../../steps/presentation/step_widgets.dart';
import '../application/stages_controller.dart';
import '../data/stages_repository.dart';
import '../domain/stage.dart';
import 'pause_sheet.dart';
import 'save_as_template_sheet.dart';
import 'stage_widgets.dart';

/// Детали этапа — унифицированный экран для всех 6 статусов + 2 computed
/// (overdue/late-start). Banner + CTAs зависят от текущего статуса.
class StageDetailScreen extends ConsumerWidget {
  const StageDetailScreen({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final projectAsync = ref.watch(projectControllerProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Этап',
      padding: EdgeInsets.zero,
      body: stagesAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Ошибка загрузки',
          onRetry: () =>
              ref.invalidate(stagesControllerProvider(projectId)),
        ),
        data: (stages) {
          final stage = stages.cast<Stage?>().firstWhere(
                (s) => s?.id == stageId,
                orElse: () => null,
              );
          if (stage == null) {
            return const AppEmptyState(
              title: 'Этап не найден',
              icon: Icons.error_outline,
            );
          }
          final project = projectAsync.value;
          final planRequired = project?.requiresPlanApproval ?? false;
          final planApproved =
              (project?.planApproved ?? false) || stage.planApproved;
          final display = StageDisplayStatus.of(stage);
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(stagesControllerProvider(projectId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                _HeaderCard(stage: stage, display: display),
                const SizedBox(height: AppSpacing.x12),
                _StatusBanner(
                  display: display,
                  planRequired: planRequired,
                  planApproved: planApproved,
                ),
                const SizedBox(height: AppSpacing.x16),
                _InfoGrid(stage: stage),
                const SizedBox(height: AppSpacing.x20),
                _CtaGroup(
                  projectId: projectId,
                  stage: stage,
                  display: display,
                  canStart: !planRequired || planApproved,
                ),
                const SizedBox(height: AppSpacing.x24),
                _StepsSection(projectId: projectId, stageId: stage.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepsSection extends ConsumerWidget {
  const _StepsSection({required this.projectId, required this.stageId});

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = StepsKey(projectId: projectId, stageId: stageId);
    final async = ref.watch(stepsControllerProvider(key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Шаги', style: AppTextStyles.h2),
            const Spacer(),
            TextButton.icon(
              onPressed: () => showExtraWorkSheet(
                context,
                ref,
                projectId: projectId,
                stageId: stageId,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Доп.работа'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.x16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Не удалось загрузить шаги',
            style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
          ),
          data: (steps) {
            if (steps.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.x16),
                decoration: BoxDecoration(
                  color: AppColors.n100,
                  borderRadius: AppRadius.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Шагов пока нет. Добавьте основной шаг — '
                      'именно они определяют прогресс этапа.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.x10),
                    AppButton(
                      label: 'Добавить шаг',
                      variant: AppButtonVariant.secondary,
                      fullWidth: false,
                      onPressed: () => _showCreateStepSheet(context, ref, key),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final s in steps) ...[
                  StepRow(
                    step: s,
                    onTap: () => context.push(
                      '/projects/$projectId/stages/$stageId/steps/${s.id}',
                    ),
                    onToggleDone: () async {
                      final c = ref.read(
                        stepsControllerProvider(key).notifier,
                      );
                      final failure = s.isDone
                          ? await c.uncomplete(s.id)
                          : await c.complete(s.id);
                      if (context.mounted && failure != null) {
                        AppToast.show(
                          context,
                          message: failure.userMessage,
                          kind: AppToastKind.error,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.x8),
                ],
                AppButton(
                  label: 'Добавить шаг',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _showCreateStepSheet(context, ref, key),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showCreateStepSheet(
    BuildContext context,
    WidgetRef ref,
    StepsKey key,
  ) async {
    final title = await showAppBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      child: const _CreateRegularStepBody(),
    );
    if (title == null || title.isEmpty) return;
    final failure = await ref
        .read(stepsControllerProvider(key).notifier)
        .createRegular(title: title);
    if (context.mounted) {
      AppToast.show(
        context,
        message: failure == null ? 'Шаг добавлен' : failure.userMessage,
        kind: failure == null ? AppToastKind.success : AppToastKind.error,
      );
    }
  }
}

class _CreateRegularStepBody extends StatefulWidget {
  const _CreateRegularStepBody();

  @override
  State<_CreateRegularStepBody> createState() =>
      _CreateRegularStepBodyState();
}

class _CreateRegularStepBodyState extends State<_CreateRegularStepBody> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.length < 2) {
      setState(() => _error = 'Минимум 2 символа');
      return;
    }
    if (title.length > 200) {
      setState(() => _error = 'Максимум 200 символов');
      return;
    }
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Новый шаг',
            subtitle:
                'Основной шаг попадает в прогресс этапа. Для доп.работы '
                'используйте отдельную кнопку сверху.',
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Что нужно сделать?',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.brand, width: 1.5),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.x6),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
          ],
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Добавить шаг',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.stage, required this.display});

  final Stage stage;
  final StageDisplayStatus display;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stage.title, style: AppTextStyles.h1, maxLines: 3),
          const SizedBox(height: AppSpacing.x8),
          StageStatusBadge(display: display),
          const SizedBox(height: AppSpacing.x12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (stage.progressCache / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: display.semaphore.dot,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Прогресс: ${stage.progressCache}%',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.display,
    required this.planRequired,
    required this.planApproved,
  });

  final StageDisplayStatus display;
  final bool planRequired;
  final bool planApproved;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, color) = switch (display) {
      StageDisplayStatus.pending => planRequired && !planApproved
          ? (
              Icons.lock_outline,
              'Ожидает согласования плана',
              'Этап нельзя запустить, пока план работ не одобрен заказчиком.',
              AppColors.n500,
            )
          : (
              Icons.play_arrow_rounded,
              'Готов к запуску',
              'Нажмите «Запустить», чтобы начать работы.',
              AppColors.brand,
            ),
      StageDisplayStatus.active => (
          Icons.trending_up_rounded,
          'В работе',
          'Мастера выполняют шаги. Когда всё готово — отправьте на приёмку.',
          AppColors.greenDark,
        ),
      StageDisplayStatus.paused => (
          Icons.pause_circle_outline,
          'На паузе',
          'Пауза не списывает срок. Возобновите, когда будет готово.',
          AppColors.yellowDot,
        ),
      StageDisplayStatus.review => (
          Icons.check_circle_outline,
          'На приёмке',
          'Заказчик увидит этап в согласованиях и подтвердит/отклонит приёмку.',
          AppColors.blueDot,
        ),
      StageDisplayStatus.done => (
          Icons.verified_outlined,
          'Завершён',
          'Этап принят. Спасибо за работу!',
          AppColors.greenDark,
        ),
      StageDisplayStatus.rejected => (
          Icons.close_rounded,
          'Отклонён заказчиком',
          'Смотрите комментарий. После правок — отправьте снова.',
          AppColors.redDot,
        ),
      StageDisplayStatus.overdue => (
          Icons.schedule_outlined,
          'Просрочен',
          'Дедлайн прошёл. Нужно решить: перенести срок или ускорить.',
          AppColors.redDot,
        ),
      StageDisplayStatus.lateStart => (
          Icons.hourglass_top_outlined,
          'Опоздал со стартом',
          'Плановая дата старта прошла. Запустите этап или обновите дату.',
          AppColors.redDot,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.stage});

  final Stage stage;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM y', 'ru');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        children: [
          _row(
            'Старт',
            stage.plannedStart == null ? '—' : df.format(stage.plannedStart!),
          ),
          const Divider(height: AppSpacing.x20, color: AppColors.n100),
          _row(
            'Завершение',
            stage.plannedEnd == null ? '—' : df.format(stage.plannedEnd!),
          ),
          const Divider(height: AppSpacing.x20, color: AppColors.n100),
          _row('Работы', Money.format(stage.workBudget)),
          const SizedBox(height: AppSpacing.x8),
          _row('Материалы', Money.format(stage.materialsBudget)),
          if (stage.foremanIds.isNotEmpty) ...[
            const Divider(height: AppSpacing.x20, color: AppColors.n100),
            _row('Бригадир(ы)', '${stage.foremanIds.length} чел.'),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value, style: AppTextStyles.subtitle),
        ],
      );
}

class _CtaGroup extends ConsumerStatefulWidget {
  const _CtaGroup({
    required this.projectId,
    required this.stage,
    required this.display,
    required this.canStart,
  });

  final String projectId;
  final Stage stage;
  final StageDisplayStatus display;
  final bool canStart;

  @override
  ConsumerState<_CtaGroup> createState() => _CtaGroupState();
}

class _CtaGroupState extends ConsumerState<_CtaGroup> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    try {
      final failureMessage = await action();
      if (!mounted) return;
      if (failureMessage != null) {
        AppToast.show(
          context,
          message: failureMessage,
          kind: AppToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _wrap(
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    final failure = await action();
    if (failure == null && mounted) {
      AppToast.show(
        context,
        message: successMessage,
        kind: AppToastKind.success,
      );
      return null;
    }
    return (failure as dynamic)?.userMessage as String? ?? 'Не удалось';
  }

  /// Бэк возвращает 409 `approvals.plan_not_approved`, когда план обязателен,
  /// но ещё не одобрен. Локально мы перехватываем код и предлагаем
  /// перейти на экран согласования плана, не показывая generic-ошибку.
  Future<void> _tryStart() async {
    setState(() => _busy = true);
    try {
      // Идём через repo напрямую, чтобы видеть `ApiError.code`. Контроллер
      // потом подхватит обновление через invalidate.
      await ref.read(stagesRepositoryProvider).start(
            projectId: widget.projectId,
            stageId: widget.stage.id,
          );
      ref.invalidate(stagesControllerProvider(widget.projectId));
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Этап запущен',
        kind: AppToastKind.success,
      );
    } on StagesException catch (e) {
      if (!mounted) return;
      if (e.apiError.code == 'approvals.plan_not_approved') {
        await _showPlanRequiredDialog();
      } else {
        AppToast.show(
          context,
          message: e.failure.userMessage,
          kind: AppToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPlanRequiredDialog() async {
    final go = await showAppBottomSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'План не согласован',
            subtitle: 'Этап нельзя запустить, пока заказчик не одобрит план '
                'работ. Откройте экран согласования плана и отправьте '
                'запрос или дождитесь решения.',
          ),
          AppButton(
            label: 'Открыть согласование плана',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.x8),
          AppButton(
            label: 'Позже',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if ((go ?? false) && mounted) {
      unawaited(
        context.push(AppRoutes.projectPlanApprovalWith(widget.projectId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesController =
        ref.read(stagesControllerProvider(widget.projectId).notifier);
    final canStart = ref.watch(canProvider(DomainAction.stageStart));
    final canPause = ref.watch(canProvider(DomainAction.stagePause));
    final canManageStage =
        ref.watch(canProvider(DomainAction.stageManage));
    final canRequestApproval =
        ref.watch(canProvider(DomainAction.approvalRequest));
    final buttons = <Widget>[];

    switch (widget.display) {
      case StageDisplayStatus.pending:
      case StageDisplayStatus.lateStart:
        if (canStart) {
          buttons.add(
            AppButton(
              label: widget.canStart
                  ? 'Запустить этап'
                  : 'План не согласован',
              isLoading: _busy,
              onPressed: widget.canStart
                  ? _tryStart
                  : () => context.push(
                        AppRoutes.projectPlanApprovalWith(widget.projectId),
                      ),
            ),
          );
        }
      case StageDisplayStatus.active:
      case StageDisplayStatus.overdue:
        if (canRequestApproval) {
          buttons.add(
            AppButton(
              label: 'Отправить на приёмку',
              isLoading: _busy,
              onPressed: () => _run(
                () => _wrap(
                  () => stagesController.sendToReview(widget.stage.id),
                  successMessage: 'Этап отправлен на приёмку',
                ),
              ),
            ),
          );
        }
        if (canPause) {
          if (buttons.isNotEmpty) {
            buttons.add(const SizedBox(height: AppSpacing.x8));
          }
          buttons.add(
            AppButton(
              label: 'Поставить на паузу',
              variant: AppButtonVariant.secondary,
              onPressed: _busy
                  ? null
                  : () => showPauseSheet(
                        context,
                        ref,
                        projectId: widget.projectId,
                        stageId: widget.stage.id,
                      ),
            ),
          );
        }
      case StageDisplayStatus.paused:
        if (canPause) {
          buttons.add(
            AppButton(
              label: 'Возобновить',
              isLoading: _busy,
              onPressed: () => _run(
                () => _wrap(
                  () => stagesController.resume(widget.stage.id),
                  successMessage: 'Этап возобновлён',
                ),
              ),
            ),
          );
        }
      case StageDisplayStatus.review:
      case StageDisplayStatus.done:
      case StageDisplayStatus.rejected:
        break;
    }

    if (canManageStage) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: AppSpacing.x12));
      }
      buttons.add(
        AppButton(
          label: 'Сохранить как шаблон',
          variant: AppButtonVariant.ghost,
          onPressed: _busy
              ? null
              : () => showSaveAsTemplateSheet(
                    context,
                    ref,
                    stageId: widget.stage.id,
                    defaultTitle: widget.stage.title,
                  ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(children: buttons);
  }
}
