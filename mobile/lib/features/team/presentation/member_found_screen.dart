import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import 'add_member_screen.dart';

/// s-member-found — карточка найденного пользователя + role-grid
/// (На проект / На этап) + success CTA.
class MemberFoundScreen extends ConsumerStatefulWidget {
  const MemberFoundScreen({
    required this.projectId,
    required this.args,
    super.key,
  });

  final String projectId;
  final MemberFoundArgs args;

  @override
  ConsumerState<MemberFoundScreen> createState() => _MemberFoundScreenState();
}

enum _AssignKind { project, stage }

class _MemberFoundScreenState extends ConsumerState<MemberFoundScreen> {
  _AssignKind _kind = _AssignKind.project;
  bool _busy = false;

  Future<void> _submit() async {
    if (_kind == _AssignKind.stage) {
      // Перейти на выбор этапа.
      context.push(
        AppRoutes.projectAssignStageWith(widget.projectId),
        extra: widget.args,
      );
      return;
    }
    setState(() => _busy = true);
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .addMember(
          userId: widget.args.userId,
          role: MembershipRole.foreman,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: '✓ ${widget.args.firstName} назначен бригадиром',
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
    final fullName =
        '${widget.args.firstName} ${widget.args.lastName}'.trim();
    final ctaLabel = _kind == _AssignKind.project
        ? 'Назначить бригадиром'
        : 'Выбрать этап';

    return AppScaffold(
      showBack: true,
      title: 'Назначение',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
        children: [
          // Карточка найденного пользователя.
          Container(
            padding: const EdgeInsets.all(AppSpacing.x16),
            decoration: BoxDecoration(
              color: AppColors.n0,
              border: Border.all(color: AppColors.n200),
              borderRadius: BorderRadius.circular(AppRadius.r20),
              boxShadow: AppShadows.sh1,
            ),
            child: Row(
              children: [
                AppAvatar(
                  seed: widget.args.userId,
                  name: fullName,
                  size: 52,
                  palette: AvatarPalette.yellow,
                ),
                const SizedBox(width: AppSpacing.x14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.n800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.args.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.greenDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Зарегистрирован',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x20),
          const Text(
            'Назначить как',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Row(
            children: [
              Expanded(
                child: _AssignCard(
                  icon: PhosphorIconsRegular.briefcase,
                  iconColor: AppColors.brand,
                  title: 'На проект',
                  sub: 'Бригадир',
                  selected: _kind == _AssignKind.project,
                  onTap: () =>
                      setState(() => _kind = _AssignKind.project),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: _AssignCard(
                  icon: PhosphorIconsRegular.calendar,
                  iconColor: AppColors.n600,
                  title: 'На этап',
                  sub: 'Мастер',
                  selected: _kind == _AssignKind.stage,
                  onTap: () => setState(() => _kind = _AssignKind.stage),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          _HintBox(
            text: '«На проект» — видит все этапы, назначает мастеров. '
                '«На этап» — работает только в выбранном этапе.',
          ),
          const SizedBox(height: AppSpacing.x20),
          AppButton(
            label: ctaLabel,
            variant: _kind == _AssignKind.project
                ? AppButtonVariant.success
                : AppButtonVariant.primary,
            isLoading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _AssignCard extends StatelessWidget {
  const _AssignCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandLight : AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.n200,
              width: 1.5,
            ),
            borderRadius: AppRadius.card,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.n0 : AppColors.n100,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.info,
            size: 16,
            color: AppColors.brand,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
