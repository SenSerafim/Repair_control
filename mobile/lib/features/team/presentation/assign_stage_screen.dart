import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/data/stages_repository.dart';
import '../../stages/domain/stage.dart';
import '../application/team_controller.dart';
import '../data/team_repository.dart';
import 'add_member_screen.dart';

/// s-assign-stage — выбор этапа для назначения мастером.
///
/// Две связанные модели на бэке (см. backend/stages.service.ts:202):
///   • `Membership` (role=master, stageIds[]) — мастер в команде проекта.
///   • `Stage.masterId` — single-master FSM конкретного этапа. Эту привязку
///     создаёт `POST /stages/:id/assign-master` — он же поднимает stage-chat
///     и approval-flow. `addMember` сам её НЕ создаёт.
///
/// Поэтому корректная последовательность:
///   1. Если юзера ещё нет в команде → addMember(master, stageIds=[stage]).
///      Если уже master → updateMember расширяет stageIds.
///      Если уже foreman/rep → ошибка, надо снять текущую роль.
///   2. После membership → assignMaster, чтобы Stage.masterId был заполнен
///      и создался stage-chat.
///
/// Кнопка «Добавить без этапа» — для случая когда этапов ещё нет либо
/// назначение делается позже из StageDetailScreen.
class AssignStageScreen extends ConsumerStatefulWidget {
  const AssignStageScreen({
    required this.projectId,
    required this.args,
    super.key,
  });

  final String projectId;
  final MemberFoundArgs args;

  @override
  ConsumerState<AssignStageScreen> createState() => _AssignStageScreenState();
}

class _AssignStageScreenState extends ConsumerState<AssignStageScreen> {
  bool _busy = false;

  Future<void> _pick(Stage stage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final teamState = ref
          .read(teamControllerProvider(widget.projectId))
          .valueOrNull;
      final existing = teamState?.members
          .where((m) => m.userId == widget.args.userId)
          .toList();
      final hasMembership = existing != null && existing.isNotEmpty;

      if (hasMembership) {
        final m = existing.first;
        if (m.role != MembershipRole.master) {
          if (!mounted) return;
          setState(() => _busy = false);
          AppToast.show(
            context,
            message:
                'Пользователь уже в команде как '
                '«${m.role.displayName}». Снимите эту роль перед '
                'назначением мастером.',
            kind: AppToastKind.error,
          );
          return;
        }
        // Уже master — расширим membership.stageIds через PATCH endpoint
        // (backend members.service:updateMembership поддерживает stageIds).
        try {
          await ref
              .read(teamRepositoryProvider)
              .updateMember(
                projectId: widget.projectId,
                membershipId: m.id,
                stageIds: [stage.id],
              );
          ref.invalidate(teamControllerProvider(widget.projectId));
        } on TeamException catch (e) {
          throw _AssignFailureMessage(e.failure.userMessage);
        }
      } else {
        final fail = await ref
            .read(teamControllerProvider(widget.projectId).notifier)
            .addMember(
              userId: widget.args.userId,
              role: MembershipRole.master,
              stageIds: [stage.id],
              specialization: widget.args.specialization,
            );
        if (fail != null) {
          throw _AssignFailureMessage(fail.userMessage);
        }
      }

      // Stage.masterId — single-master FSM. Обязательно после membership.
      await ref
          .read(stagesRepositoryProvider)
          .assignMaster(
            projectId: widget.projectId,
            stageId: stage.id,
            masterUserId: widget.args.userId,
          );
      ref.invalidate(stagesControllerProvider(widget.projectId));
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
        context,
        message:
            '✓ ${widget.args.firstName} назначен(а) мастером '
            'на «${stage.title}»',
        kind: AppToastKind.success,
      );
      context.go(AppRoutes.projectTeamWith(widget.projectId));
    } on _AssignFailureMessage catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(context, message: e.message, kind: AppToastKind.error);
    } on StagesException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
        context,
        message: 'Не удалось назначить. Попробуйте ещё раз.',
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _addWithoutStage() async {
    if (_busy) return;
    setState(() => _busy = true);
    final fail = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .addMember(
          userId: widget.args.userId,
          role: MembershipRole.master,
          specialization: widget.args.specialization,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (fail == null) {
      AppToast.show(
        context,
        message:
            '✓ ${widget.args.firstName} добавлен(а) мастером. '
            'Назначьте на этапы позже из карточки этапа.',
        kind: AppToastKind.success,
      );
      context.go(AppRoutes.projectTeamWith(widget.projectId));
    } else {
      AppToast.show(
        context,
        message: fail.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stagesControllerProvider(widget.projectId));
    final fullName = '${widget.args.firstName} ${widget.args.lastName}'.trim();

    return AppScaffold(
      showBack: true,
      title: 'Выбор этапа',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          _Banner(
            text: '$fullName будет назначен(а) мастером на выбранный этап',
          ),
          Expanded(
            child: stagesAsync.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить этапы',
                onRetry: () =>
                    ref.invalidate(stagesControllerProvider(widget.projectId)),
              ),
              data: (stages) => ListView(
                padding: const EdgeInsets.all(AppSpacing.x16),
                children: [
                  if (stages.isNotEmpty) ...[
                    const Text(
                      'ЭТАПЫ ПРОЕКТА',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                    for (final stage in stages) ...[
                      _StageCard(
                        stage: stage,
                        enabled: !_busy,
                        onTap: () => _pick(stage),
                      ),
                      const SizedBox(height: AppSpacing.x10),
                    ],
                    const SizedBox(height: AppSpacing.x12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.x14),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBg,
                        borderRadius: AppRadius.card,
                      ),
                      child: const Text(
                        'В проекте пока нет этапов. Добавьте мастера сейчас '
                        '— назначите на этапы позже, когда они появятся.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.yellowText,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x16),
                  ],
                  AppButton(
                    label: 'Добавить без этапа',
                    variant: AppButtonVariant.secondary,
                    icon: PhosphorIconsRegular.userPlus,
                    isLoading: _busy,
                    onPressed: _addWithoutStage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignFailureMessage implements Exception {
  _AssignFailureMessage(this.message);
  final String message;
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x10,
      ),
      color: AppColors.brandLight,
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.info, size: 14, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.enabled,
    required this.onTap,
  });

  final Stage stage;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg1, bg2, fg) = _colorsFor(stage.status);
    final progressLabel = stage.status == StageStatus.active
        ? 'В работе · ${stage.progressCache}%'
        : 'Ожидает · ${stage.progressCache}%';

    return Material(
      color: AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.n200),
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.sh1,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bg1, bg2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(
                  PhosphorIconsRegular.lightning,
                  size: 20,
                  color: fg,
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stage.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progressLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (Color, Color, Color) _colorsFor(StageStatus s) => switch (s) {
    StageStatus.active => (
      const Color(0xFFDBEAFE),
      const Color(0xFFBFDBFE),
      const Color(0xFF2563EB),
    ),
    StageStatus.done => (
      const Color(0xFFD1FAE5),
      const Color(0xFFA7F3D0),
      AppColors.greenDark,
    ),
    StageStatus.paused => (
      const Color(0xFFFEF3C7),
      const Color(0xFFFDE68A),
      AppColors.yellowText,
    ),
    StageStatus.rejected => (
      const Color(0xFFFEE2E2),
      const Color(0xFFFECACA),
      AppColors.redDot,
    ),
    _ => (
      const Color(0xFFFEF3C7),
      const Color(0xFFFDE68A),
      AppColors.yellowText,
    ),
  };
}
