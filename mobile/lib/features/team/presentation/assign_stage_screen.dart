import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../application/team_controller.dart';
import 'add_member_screen.dart';

/// s-assign-stage — выбор этапа для назначения мастером.
class AssignStageScreen extends ConsumerStatefulWidget {
  const AssignStageScreen({
    required this.projectId,
    required this.args,
    super.key,
  });

  final String projectId;
  final MemberFoundArgs args;

  @override
  ConsumerState<AssignStageScreen> createState() =>
      _AssignStageScreenState();
}

class _AssignStageScreenState extends ConsumerState<AssignStageScreen> {
  bool _busy = false;

  Future<void> _pick(Stage stage) async {
    setState(() => _busy = true);
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .addMember(
          userId: widget.args.userId,
          role: MembershipRole.master,
          stageIds: [stage.id],
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: '✓ Назначен на этап «${stage.title}»',
        kind: AppToastKind.success,
      );
      context.go(AppRoutes.projectTeamWith(widget.projectId));
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync =
        ref.watch(stagesControllerProvider(widget.projectId));
    final fullName =
        '${widget.args.firstName} ${widget.args.lastName}'.trim();

    return AppScaffold(
      showBack: true,
      title: 'Выбор этапа',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          _Banner(text: '$fullName будет назначен мастером на выбранный этап'),
          Expanded(
            child: stagesAsync.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить этапы',
                onRetry: () => ref.invalidate(
                  stagesControllerProvider(widget.projectId),
                ),
              ),
              data: (stages) => ListView(
                padding: const EdgeInsets.all(AppSpacing.x16),
                children: [
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
