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
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../../steps/application/steps_controller.dart';
import '../../steps/domain/step.dart';
import '../../steps/presentation/extra_work_sheet.dart';
import '../application/stages_controller.dart';
import '../data/stages_repository.dart';
import '../domain/stage.dart';
import '_widgets/stage_approvals_tab.dart';
import '_widgets/stage_banner_data.dart';
import '_widgets/stage_checklist_tab.dart';
import '_widgets/stage_docs_tab.dart';
import '_widgets/stage_status_banner.dart';
import '_widgets/stage_stats_row.dart';
import '_widgets/stage_tabs_bar.dart';
import 'pause_sheet.dart';
// П1.7 / 4.6 — `save_as_template_sheet.dart` удалён вместе с фичей пользовательских шаблонов.
import 'stage_widgets.dart' show StageDisplayStatus, StageStatusBadge;

/// Детали этапа — пиксель-в-пиксель редизайн c-stage-* (8 состояний).
///
/// Layout: header (back+title+badge+menu) → StageStatsRow → StageStatusBanner
/// → StageTabsBar → IndexedStack из 3 табов → state-aware bottom action bar.
/// Вкладка «Чат» убрана: коммуникации по этапу ведутся через раздел чатов
/// проекта (overdue-баннер показывает CTA «Связаться»).
class StageDetailScreen extends ConsumerStatefulWidget {
  const StageDetailScreen({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  ConsumerState<StageDetailScreen> createState() => _StageDetailScreenState();
}

class _StageDetailScreenState extends ConsumerState<StageDetailScreen> {
  StageTab _tab = StageTab.checklist;

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stagesControllerProvider(widget.projectId));
    final projectAsync = ref.watch(projectControllerProvider(widget.projectId));
    final approvalsAsync = ref.watch(
      approvalsControllerProvider(widget.projectId),
    );

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
          // Бейдж на табе «Согл.» считаем тем же фильтром, что и сама вкладка:
          // прямой stageId-матч + plan-scope, упоминающий этот этап в payload.
          // Иначе число рядом с табом расходилось с реально видимыми карточками.
          final pendingForStage = approvalsAsync.maybeWhen(
            data: (b) =>
                b.pending.where((a) => approvalBelongsToStage(a, stage.id)).length,
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
            data: (s) => s.where((x) => x.status == StepStatus.done).length,
            orElse: () => 0,
          );
          final photosTotal = stepsAsync.maybeWhen(
            data: (s) => s.fold<int>(0, (a, st) => a + st.photosCount),
            orElse: () => 0,
          );

          // Есть ли уже отправленный (pending) approval scope=plan по этому
          // этапу — нужно для CTA в action bar (показать «На согласовании» вместо
          // «Отправить план»).
          final pendingPlanApproval = approvalsAsync.maybeWhen(
            data: (b) => b.pending.any(
              (a) =>
                  a.scope == ApprovalScope.plan &&
                  (a.stageId == stage.id ||
                      a.payload['stageId'] == stage.id),
            ),
            orElse: () => false,
          );
          // Может ли текущая роль добавлять шаги в этап. Используем
          // canInProjectProvider, чтобы заказчик/master без права не видел
          // CTA «+ Шаг» (сервер всё равно вернёт 403).
          final canManageSteps = ref.watch(
            canInProjectProvider((
              action: DomainAction.stepManage,
              projectId: widget.projectId,
            )),
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
                      // Скрываем кнопку «+ Шаг» у ролей без права step.manage
                      // (у заказчика, мастера-чужого-этапа). Передаём null —
                      // checklist tab должен трактовать это как «без CTA».
                      onAddStep: canManageSteps
                          ? () => _showAddStepSheet(context, stage)
                          : null,
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
                  ],
                ),
              ),
              _ActionBar(
                projectId: widget.projectId,
                stage: stage,
                display: display,
                planAllowsStart: !planRequired || planApproved,
                planRequired: planRequired,
                planApproved: planApproved,
                pendingPlanApproval: pendingPlanApproval,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openProjectChat(String projectId, String stageId) async {
    // overdue → «Связаться» в banner'е. Открываем раздел чатов проекта —
    // пользователь сам выберет нужный чат (этап, общий, личный).
    context.push('/projects/$projectId/chats');
  }

  Future<void> _toggleStep(Stage stage, Step step) async {
    final key = StepsKey(projectId: widget.projectId, stageId: stage.id);
    final c = ref.read(stepsControllerProvider(key).notifier);
    final failure = step.isDone
        ? await c.uncomplete(step.id)
        : await c.complete(step.id);
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
    final key = StepsKey(projectId: widget.projectId, stageId: stage.id);
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
    // П1.7 / 4.6 — пункт «Сохранить как шаблон» удалён.
    // П1.11 / 4.8 / 7.5 — меню переиспользовано под назначение бригадира/мастера.
    // 2026-05: canInProjectProvider честно учитывает membership-роль +
    // делегированные представителю права (canEditStages/canCreateStages),
    // тогда как старый canProvider смотрел только глобальную активную роль.
    final canManageStages = ref.read(
      canInProjectProvider((
        action: DomainAction.stageManage,
        projectId: stage.projectId,
      )),
    );
    await showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(title: 'Действия'),
          if (canManageStages) ...[
            ListTile(
              leading: const Icon(
                Icons.engineering_outlined,
                color: AppColors.brand,
              ),
              title: const Text('Назначить бригадира'),
              subtitle: const Text('Один бригадир на этап'),
              onTap: () {
                Navigator.of(context).pop();
                _showAssignSheet(context, ref, kind: _AssignKind.foreman);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.handyman_outlined,
                color: AppColors.brand,
              ),
              title: const Text('Назначить мастера'),
              subtitle: const Text(
                'Если мастер не назначен — этап ведёт сам бригадир',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showAssignSheet(context, ref, kind: _AssignKind.master);
              },
            ),
          ],
          if (!canManageStages)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Дополнительных действий нет — нужны права на управление этапом.',
                style: TextStyle(fontSize: 14, color: Color(0xFF656b7a)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAssignSheet(
    BuildContext context,
    WidgetRef ref, {
    required _AssignKind kind,
  }) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _AssignMemberSheet(
        projectId: stage.projectId,
        stageId: stage.id,
        kind: kind,
      ),
    );
  }
}

enum _AssignKind { foreman, master }

class _AssignMemberSheet extends ConsumerStatefulWidget {
  const _AssignMemberSheet({
    required this.projectId,
    required this.stageId,
    required this.kind,
  });

  final String projectId;
  final String stageId;
  final _AssignKind kind;

  @override
  ConsumerState<_AssignMemberSheet> createState() => _AssignMemberSheetState();
}

class _AssignMemberSheetState extends ConsumerState<_AssignMemberSheet> {
  String? _busyUserId;

  Future<void> _doAssign(String userId, String fullName) async {
    if (_busyUserId != null) return;
    setState(() => _busyUserId = userId);
    final repo = ref.read(stagesRepositoryProvider);
    try {
      if (widget.kind == _AssignKind.foreman) {
        await repo.assignForeman(
          projectId: widget.projectId,
          stageId: widget.stageId,
          foremanUserId: userId,
        );
      } else {
        await repo.assignMaster(
          projectId: widget.projectId,
          stageId: widget.stageId,
          masterUserId: userId,
        );
      }
      ref.invalidate(stagesControllerProvider(widget.projectId));
      if (!mounted) return;
      final label =
          widget.kind == _AssignKind.foreman ? 'бригадиром' : 'мастером';
      final messengerCtx = context;
      Navigator.of(messengerCtx).pop();
      AppToast.show(
        messengerCtx,
        message: fullName.isEmpty
            ? '✓ Назначено $label'
            : '✓ $fullName назначен(а) $label',
        kind: AppToastKind.success,
      );
    } on StagesException catch (e) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      AppToast.show(
        context,
        message: 'Не удалось назначить. Попробуйте ещё раз.',
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // QA-баг #3 / 2026-05 — pick-and-assign sheet с реальным feedback'ом.
    // Раньше onAssign закрывал sheet до завершения async и молча проглатывал
    // ошибки → пользователь видел «ничего не происходит». Теперь sheet
    // stateful: inline-индикатор на строке, success/error toast, закрытие
    // только после успеха.
    final title = widget.kind == _AssignKind.foreman
        ? 'Выберите бригадира'
        : 'Выберите мастера';
    final neededRole = widget.kind == _AssignKind.foreman
        ? MembershipRole.foreman
        : MembershipRole.master;
    final teamAsync = ref.watch(teamControllerProvider(widget.projectId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(title: title),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: teamAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AppLoadingState(),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: AppErrorState(
                title: 'Не удалось загрузить команду',
                onRetry: () =>
                    ref.invalidate(teamControllerProvider(widget.projectId)),
              ),
            ),
            data: (team) {
              final candidates = team.members
                  .where((m) => m.role == neededRole)
                  .toList();
              if (candidates.isEmpty) {
                return _AssignEmptyState(
                  kind: widget.kind,
                  onAddNew: () {
                    Navigator.of(context).pop();
                    context.push(
                      AppRoutes.projectAddMemberWith(widget.projectId),
                    );
                  },
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: candidates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final m = candidates[i];
                  final user = m.user;
                  final fullName = user == null
                      ? m.userId
                      : '${user.firstName} ${user.lastName}'.trim();
                  final isBusy = _busyUserId == m.userId;
                  return ListTile(
                    leading: AppAvatar(
                      seed: m.userId,
                      name: fullName.isEmpty ? null : fullName,
                      imageUrl: user?.avatarUrl,
                    ),
                    title: Text(fullName.isEmpty ? 'Без имени' : fullName),
                    subtitle: Text(m.role.displayName),
                    trailing: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    enabled: _busyUserId == null,
                    onTap: () => _doAssign(m.userId, fullName),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssignEmptyState extends StatelessWidget {
  const _AssignEmptyState({required this.kind, required this.onAddNew});
  final _AssignKind kind;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final roleLabel = kind == _AssignKind.foreman ? 'бригадиров' : 'мастеров';
    final ctaLabel =
        kind == _AssignKind.foreman ? 'Добавить бригадира' : 'Добавить мастера';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'В команде проекта пока нет $roleLabel. '
            'Добавьте подходящего человека — после этого сможете назначить '
            'его на этот этап.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF656b7a)),
          ),
          const SizedBox(height: 16),
          AppButton(label: ctaLabel, onPressed: onAddNew),
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
    required this.planRequired,
    required this.planApproved,
    required this.pendingPlanApproval,
  });

  final String projectId;
  final Stage stage;
  final StageDisplayStatus display;
  final bool planAllowsStart;
  /// Проект требует согласования плана (Project.requiresPlanApproval).
  final bool planRequired;
  /// Этот этап (или проект целиком) имеет одобренный план.
  final bool planApproved;
  /// Уже есть pending approval scope=plan по этому этапу — не плодим повторно.
  final bool pendingPlanApproval;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  StagesController get _controller =>
      ref.read(stagesControllerProvider(widget.projectId).notifier);

  Future<void> _wrap(
    Future<dynamic> Function() action,
    String successMsg,
  ) async {
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
    // QA баг #1: запуск этапа без бригадира должен быть запрещён.
    // Бэк теперь кидает stages.no_foreman, но даём мгновенный фидбек на
    // фронте — без сетевого round-trip и с понятным CTA.
    if (widget.stage.foremanIds.isEmpty) {
      AppToast.show(
        context,
        message: 'Назначьте бригадира на этап перед запуском',
        kind: AppToastKind.error,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(stagesRepositoryProvider)
          .start(projectId: widget.projectId, stageId: widget.stage.id);
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

  /// П2.3 — отправить план этапа на согласование заказчику.
  /// Endpoint идемпотентный; повторный тап даст уже существующий pending
  /// approval. После успеха инвалидируем approvals + stages, чтобы UI
  /// мгновенно показал «План на согласовании» (через ws-сигнал тоже придёт).
  Future<void> _trySubmitPlan() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(stagesRepositoryProvider)
          .submitPlan(projectId: widget.projectId, stageId: widget.stage.id);
      ref.invalidate(approvalsControllerProvider(widget.projectId));
      ref.invalidate(stagesControllerProvider(widget.projectId));
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'План отправлен заказчику на согласование',
        kind: AppToastKind.success,
      );
    } on StagesException catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
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
    // Решения по UI делаем по правам в КОНКРЕТНОМ проекте, а не по глобальной
    // роли: один пользователь может быть foreman в одном проекте и customer-
    // representative в другом. canInProjectProvider учитывает membership-role
    // + делегированные представителю права.
    final canStart = ref.watch(
      canInProjectProvider((
        action: DomainAction.stageStart,
        projectId: widget.projectId,
      )),
    );
    final canPause = ref.watch(
      canInProjectProvider((
        action: DomainAction.stagePause,
        projectId: widget.projectId,
      )),
    );
    final canRequest = ref.watch(
      canInProjectProvider((
        action: DomainAction.approvalRequest,
        projectId: widget.projectId,
      )),
    );
    final canDecide = ref.watch(
      canInProjectProvider((
        action: DomainAction.approvalDecide,
        projectId: widget.projectId,
      )),
    );
    // Право управлять этапом — для CTA «Отправить план на согласование».
    // Бэкенд проверяет это через @RequireAccess('stage.manage') на endpoint.
    final canManageStage = ref.watch(
      canInProjectProvider((
        action: DomainAction.stageManage,
        projectId: widget.projectId,
      )),
    );
    final children = <Widget>[];

    // Все элементы children должны быть Expanded — Row делит ширину поровну
    // (или по flex). AppButton имеет fullWidth=true → без Expanded падает с
    // «BoxConstraints forces an infinite width». Сепараторы между кнопками
    // добавляются в общий for-loop ниже, не внутри case'ов.
    switch (widget.display) {
      case StageDisplayStatus.pending:
        // План требуется, не одобрен → бригадир видит «Отправить план», а
        // заказчик/представитель с canApprove — «Согласовать план». Тогда
        // кнопка «Запустить» появится после approve. Если план не требуется
        // (project.requiresPlanApproval=false) — бригадир может стартовать
        // сразу, без plan-approval.
        final showPlanCta = widget.planRequired && !widget.planApproved;
        if (showPlanCta && canManageStage) {
          // Inline submit: pending уже есть → disabled-метка, иначе POST.
          children.add(
            Expanded(
              flex: 2,
              child: AppButton(
                label: widget.pendingPlanApproval
                    ? 'План на согласовании'
                    : 'Отправить план заказчику',
                icon: widget.pendingPlanApproval
                    ? Icons.hourglass_bottom_rounded
                    : Icons.send_rounded,
                isLoading: _busy,
                onPressed: _busy || widget.pendingPlanApproval
                    ? null
                    : _trySubmitPlan,
              ),
            ),
          );
        } else if (showPlanCta && canDecide) {
          // У заказчика/представителя CTA — открыть экран plan-approval
          // (там карточка с Approve/Reject). Сюда не попадает foreman.
          children.add(
            Expanded(
              child: AppButton(
                label: 'Согласовать план',
                icon: Icons.task_alt_rounded,
                onPressed: () => context.push(
                  AppRoutes.projectPlanApprovalWith(widget.projectId),
                ),
              ),
            ),
          );
        } else if (canStart) {
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
                label: canSendToReview ? 'На проверку' : 'Завершите все шаги',
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
        // ТЗ §2.6 — Принимает этап заказчик (или бригадир, если приёмку
        // запускал мастер, — двухступенчатый approval). Решает только тот,
        // кому адресован pending stage_accept approval. У мастера/прочих
        // здесь кнопок быть не должно — отсюда canDecide-фильтр.
        if (canDecide) {
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
        }
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
          a.scope == ApprovalScope.stageAccept && a.stageId == widget.stage.id,
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
          a.scope == ApprovalScope.stageAccept && a.stageId == widget.stage.id,
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
  State<_CreateRegularStepBody> createState() => _CreateRegularStepBodyState();
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
    // SingleChildScrollView: счётчик maxLength + клавиатура легко выдавливают
    // контент за 13–30 px на узких экранах; без скролла Column overflow'ит.
    return SingleChildScrollView(
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
                borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
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
          AppButton(label: 'Добавить шаг', onPressed: _submit),
        ],
      ),
    );
  }
}

// extra-work sheet — сохраняем доступ из меню (не используется напрямую,
// но импортирован для совместимости с существующим API).
// ignore: unused_element
void _ensureExtraWorkImport() => showExtraWorkSheet;
