import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../approvals/domain/approval.dart';
import '../../approvals/presentation/_widgets/reject_sheet.dart';
import '../../projects/application/project_controller.dart';
import '../../steps/application/steps_controller.dart';
import '../../steps/domain/step.dart';
import '../../steps/presentation/extra_work_sheet.dart';
import '../application/stages_controller.dart';
import '../data/stages_repository.dart';
import '../domain/stage.dart';
import '_widgets/stage_banner_data.dart';
import '_widgets/stage_checklist_tab.dart';
import '_widgets/stage_chat_tab.dart';
import '_widgets/stage_docs_tab.dart';
import '_widgets/stage_status_banner.dart';
import '_widgets/stage_stats_row.dart';
import '_widgets/stage_tabs_bar.dart';
import 'pause_sheet.dart';
import 'save_as_template_sheet.dart';
import 'stage_widgets.dart' show StageDisplayStatus, StageStatusBadge;
import '_widgets/stage_approvals_tab.dart';

/// Детали этапа — пиксель-в-пиксель редизайн c-stage-* (8 состояний).
///
/// Layout: header (back+title+badge+menu) → StageStatsRow → StageStatusBanner
/// → StageTabsBar → IndexedStack из 4 табов → state-aware bottom action bar.
class StageDetailScreen extends ConsumerStatefulWidget {
  const StageDetailScreen({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  ConsumerState<StageDetailScreen> createState() =>
      _StageDetailScreenState();
}

class _StageDetailScreenState extends ConsumerState<StageDetailScreen> {
  StageTab _tab = StageTab.checklist;

  @override
  Widget build(BuildContext context) {
    final stagesAsync =
        ref.watch(stagesControllerProvider(widget.projectId));
    final projectAsync =
        ref.watch(projectControllerProvider(widget.projectId));
    final approvalsAsync =
        ref.watch(approvalsControllerProvider(widget.projectId));

    return AppScaffold(
      showBack: true,
      title: 'Этап',
      padding: EdgeInsets.zero,
      body: stagesAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Ошибка загрузки',
          onRetry: () =>
              ref.invalidate(stagesControllerProvider(widget.projectId)),
        ),
        data: (stages) {
          final stage = stages.cast<Stage?>().firstWhere(
                (s) => s?.id == widget.stageId,
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
          final pendingForStage = approvalsAsync.maybeWhen(
            data: (b) =>
                b.pending.where((a) => a.stageId == stage.id).length,
            orElse: () => 0,
          );
          final stepsAsync = ref.watch(
            stepsControllerProvider(
              StepsKey(projectId: widget.projectId, stageId: stage.id),
            ),
          );
          final stepsTotal = stepsAsync.maybeWhen(
            data: (s) => s.length,
            orElse: () => 0,
          );
          final stepsDone = stepsAsync.maybeWhen(
            data: (s) =>
                s.where((x) => x.status == StepStatus.done).length,
            orElse: () => 0,
          );
          final photosTotal = stepsAsync.maybeWhen(
            data: (s) => s.fold<int>(0, (a, st) => a + st.photosCount),
            orElse: () => 0,
          );

          return Column(
            children: [
              _StageHeader(stage: stage, display: display),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x16,
                  AppSpacing.x12,
                  AppSpacing.x16,
                  AppSpacing.x10,
                ),
                child: StageStatsRow(
                  progressPct: stage.progressCache,
                  progressColor: display.semaphore.dot,
                  stepsDone: stepsDone,
                  stepsTotal: stepsTotal,
                  photosCount: photosTotal,
                  filesCount: 0,
                ),
              ),
              if (StageBannerData.fromStage(stage, display) != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x16,
                    0,
                    AppSpacing.x16,
                    AppSpacing.x12,
                  ),
                  child: StageStatusBanner(
                    data: StageBannerData.fromStage(stage, display)!,
                    onContact: () =>
                        _openProjectChat(widget.projectId, stage.id),
                  ),
                ),
              StageTabsBar(
                active: _tab,
                onChange: (t) => setState(() => _tab = t),
                approvalsBadge: pendingForStage,
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    StageChecklistTab(
                      stage: stage,
                      display: display,
                      onStepTap: (step) => context.push(
                        '/projects/${widget.projectId}/stages/${stage.id}/steps/${step.id}',
                      ),
                      onAddStep: () => _showAddStepSheet(context, stage),
                      onToggleStep: (step) => _toggleStep(stage, step),
                    ),
                    StageApprovalsTab(
                      projectId: widget.projectId,
                      stageId: stage.id,
                    ),
                    StageDocsTab(
                      projectId: widget.projectId,
                      stageId: stage.id,
                    ),
                    StageChatTab(
                      projectId: widget.projectId,
                      stageId: stage.id,
                    ),
                  ],
                ),
              ),
              _ActionBar(
                projectId: widget.projectId,
                stage: stage,
                display: display,
                planAllowsStart: !planRequired || planApproved,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openProjectChat(String projectId, String stageId) async {
    // overdue → «Связаться» в banner'е. Открываем чат проекта; реальный
    // stage-chat доступен из таба «Чат».
    context.push('/projects/$projectId/chats');
  }

  Future<void> _toggleStep(Stage stage, Step step) async {
    final key = StepsKey(projectId: widget.projectId, stageId: stage.id);
    final c = ref.read(stepsControllerProvider(key).notifier);
    final failure =
        step.isDone ? await c.uncomplete(step.id) : await c.complete(step.id);
    if (mounted && failure != null) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _showAddStepSheet(BuildContext context, Stage stage) async {
    final title = await showAppBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      child: const _CreateRegularStepBody(),
    );
    if (title == null || title.isEmpty) return;
    final key =
        StepsKey(projectId: widget.projectId, stageId: stage.id);
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

// ─────────────────────────────────────────────────────────────────────
// Header: back + title + badge + 3-dot menu
// ─────────────────────────────────────────────────────────────────────
class _StageHeader extends ConsumerWidget {
  const _StageHeader({required this.stage, required this.display});

  final Stage stage;
  final StageDisplayStatus display;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.n0,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x20,
        AppSpacing.x4,
        AppSpacing.x16,
        AppSpacing.x12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stage.title,
                  style: AppTextStyles.h1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _openMenu(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          StageStatusBadge(display: display),
        ],
      ),
    );
  }

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    await showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(title: 'Действия'),
          ListTile(
            leading: const Icon(Icons.bookmark_add_outlined),
            title: const Text('Сохранить как шаблон'),
            onTap: () {
              Navigator.of(context).pop();
              showSaveAsTemplateSheet(
                context,
                ref,
                stageId: stage.id,
                defaultTitle: stage.title,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Action bar: state-aware кнопки внизу экрана.
// ─────────────────────────────────────────────────────────────────────
class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({
    required this.projectId,
    required this.stage,
    required this.display,
    required this.planAllowsStart,
  });

  final String projectId;
  final Stage stage;
  final StageDisplayStatus display;
  final bool planAllowsStart;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  StagesController get _controller =>
      ref.read(stagesControllerProvider(widget.projectId).notifier);

  Future<void> _wrap(Future<dynamic> Function() action, String successMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final failure = await action();
      if (!mounted) return;
      final msg = failure == null
          ? successMsg
          : ((failure as dynamic).userMessage as String? ?? 'Не удалось');
      AppToast.show(
        context,
        message: msg,
        kind: failure == null ? AppToastKind.success : AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tryStart() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
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
      child: Builder(
        builder: (sheetCtx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(
              title: 'План не согласован',
              subtitle:
                  'Этап нельзя запустить, пока заказчик не одобрит план '
                  'работ.',
              centered: true,
            ),
            AppButton(
              label: 'Открыть согласование плана',
              onPressed: () => Navigator.of(sheetCtx).pop(true),
            ),
            const SizedBox(height: AppSpacing.x8),
            AppButton(
              label: 'Позже',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(sheetCtx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (!(go ?? false) || !mounted) return;
    // sheet закрылся, но в этом же кадре `_tryStart`'s finally делает
    // setState(_busy = false) — ребилд ActionBar конкурирует с push.
    // Отдаём навигацию в следующий frame, чтобы router не словил race
    // на go_router 14.8.1 (HeroController/GlobalKey).
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await context.push<void>(
      AppRoutes.projectPlanApprovalWith(widget.projectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = ref.watch(canProvider(DomainAction.stageStart));
    final canPause = ref.watch(canProvider(DomainAction.stagePause));
    final canRequest = ref.watch(canProvider(DomainAction.approvalRequest));
    final children = <Widget>[];

    // Все элементы children должны быть Expanded — Row делит ширину поровну
    // (или по flex). AppButton имеет fullWidth=true → без Expanded падает с
    // «BoxConstraints forces an infinite width». Сепараторы между кнопками
    // добавляются в общий for-loop ниже, не внутри case'ов.
    switch (widget.display) {
      case StageDisplayStatus.pending:
        if (canStart) {
          children.add(
            Expanded(
              child: AppButton(
                label: widget.planAllowsStart
                    ? 'Запустить этап'
                    : 'План не согласован',
                icon: Icons.play_arrow_rounded,
                isLoading: _busy,
                onPressed: _busy
                    ? null
                    : (widget.planAllowsStart
                        ? _tryStart
                        : () => context.push(
                              AppRoutes.projectPlanApprovalWith(
                                widget.projectId,
                              ),
                            )),
              ),
            ),
          );
        }
      case StageDisplayStatus.lateStart:
        if (canStart) {
          children.add(
            Expanded(
              child: AppButton(
                label: 'Запустить этап',
                icon: Icons.play_arrow_rounded,
                isLoading: _busy,
                onPressed: _busy ? null : _tryStart,
              ),
            ),
          );
        }
      case StageDisplayStatus.active:
      case StageDisplayStatus.overdue:
        if (canPause) {
          children.add(
            Expanded(
              child: AppButton(
                label: 'Пауза',
                icon: Icons.pause_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () => showPauseSheet(
                          context,
                          ref,
                          projectId: widget.projectId,
                          stageId: widget.stage.id,
                          stageTitle: widget.stage.title,
                        ),
              ),
            ),
          );
        }
        if (canRequest) {
          // ТЗ §2.4: «На приёмку» доступно только когда все шаги завершены
          // (progressCache=100). Backend дублирует проверку — но кнопка
          // disabled даёт мгновенный фидбек без запроса.
          final canSendToReview = widget.stage.progressCache >= 100;
          children.add(
            Expanded(
              flex: 2,
              child: AppButton(
                label: canSendToReview
                    ? 'На проверку'
                    : 'Завершите все шаги',
                isLoading: _busy,
                onPressed: canSendToReview
                    ? () => _wrap(
                          () => _controller.sendToReview(widget.stage.id),
                          'Этап отправлен на приёмку',
                        )
                    : null,
              ),
            ),
          );
        }
      case StageDisplayStatus.paused:
        if (canPause) {
          children.add(
            Expanded(
              child: AppButton(
                label: 'Возобновить',
                icon: Icons.play_arrow_rounded,
                isLoading: _busy,
                onPressed: () => _wrap(
                  () => _controller.resume(widget.stage.id),
                  'Этап возобновлён',
                ),
              ),
            ),
          );
        }
      case StageDisplayStatus.review:
        children.add(
          Expanded(
            child: AppButton(
              label: 'Отклонить',
              variant: AppButtonVariant.destructive,
              onPressed: () => _rejectStage(),
            ),
          ),
        );
        children.add(
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Принять работу',
              variant: AppButtonVariant.success,
              onPressed: () => _approveStage(),
            ),
          ),
        );
      case StageDisplayStatus.rejected:
        if (canRequest) {
          children.add(
            Expanded(
              child: AppButton(
                label: 'Исправить и отправить снова',
                isLoading: _busy,
                onPressed: () => _wrap(
                  () => _controller.sendToReview(widget.stage.id),
                  'Этап отправлен на приёмку',
                ),
              ),
            ),
          );
        }
      case StageDisplayStatus.done:
        children.add(
          Expanded(
            child: AppButton(
              label: 'К списку этапов',
              variant: AppButtonVariant.ghost,
              onPressed: () =>
                  context.go('/projects/${widget.projectId}/stages'),
            ),
          ),
        );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x32 + 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.x8),
            children[i],
          ],
        ],
      ),
    );
  }

  Future<void> _approveStage() async {
    final pending = ref
        .read(approvalsControllerProvider(widget.projectId))
        .maybeWhen(data: (b) => b.pending, orElse: () => <Approval>[]);
    final stageAccept = pending.firstWhere(
      (a) =>
          a.scope == ApprovalScope.stageAccept &&
          a.stageId == widget.stage.id,
      orElse: () => Approval(
        id: '',
        scope: ApprovalScope.stageAccept,
        projectId: widget.projectId,
        requestedById: '',
        addresseeId: '',
        status: ApprovalStatus.pending,
        attemptNumber: 1,
        requiresReassign: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (stageAccept.id.isEmpty) {
      AppToast.show(
        context,
        message: 'Запрос на приёмку не найден',
        kind: AppToastKind.error,
      );
      return;
    }
    setState(() => _busy = true);
    final failure = await ref
        .read(approvalsControllerProvider(widget.projectId).notifier)
        .approve(approval: stageAccept);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      message: failure == null ? 'Этап принят' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }

  Future<void> _rejectStage() async {
    final pending = ref
        .read(approvalsControllerProvider(widget.projectId))
        .maybeWhen(data: (b) => b.pending, orElse: () => <Approval>[]);
    final stageAccept = pending.firstWhere(
      (a) =>
          a.scope == ApprovalScope.stageAccept &&
          a.stageId == widget.stage.id,
      orElse: () => Approval(
        id: '',
        scope: ApprovalScope.stageAccept,
        projectId: widget.projectId,
        requestedById: '',
        addresseeId: '',
        status: ApprovalStatus.pending,
        attemptNumber: 1,
        requiresReassign: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (stageAccept.id.isEmpty) return;
    final reason = await showRejectSheet(
      context,
      entityName: widget.stage.title,
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    final failure = await ref
        .read(approvalsControllerProvider(widget.projectId).notifier)
        .reject(approval: stageAccept, comment: reason);
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      message: failure == null ? 'Отклонено' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Add-step sheet (inline, без отдельного экрана)
// ─────────────────────────────────────────────────────────────────────
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
                'используйте отдельную кнопку.',
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
              fillColor: AppColors.n50,
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

// extra-work sheet — сохраняем доступ из меню (не используется напрямую,
// но импортирован для совместимости с существующим API).
// ignore: unused_element
void _ensureExtraWorkImport() => showExtraWorkSheet;
