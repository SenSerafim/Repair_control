import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';

/// Явное переключение роли — full-screen.
///
/// Шаги:
/// 1. Открывается экран со списком всех ролей пользователя.
/// 2. Tap по роли = выделение (синяя рамка), фактическая активная роль
///    остаётся прежней до подтверждения.
/// 3. Кнопка «Сделать основной» внизу — применяет выбор:
///    PUT /api/me/active-role → инвалидирует projects/archive →
///    success-screen.
///
/// Каждая роль — изолированный «аккаунт» со своими проектами/задачами.
class RoleSwitcherScreen extends ConsumerStatefulWidget {
  const RoleSwitcherScreen({super.key});

  @override
  ConsumerState<RoleSwitcherScreen> createState() =>
      _RoleSwitcherScreenState();
}

class _RoleSwitcherScreenState extends ConsumerState<RoleSwitcherScreen> {
  SystemRole? _selected;
  bool _busy = false;

  Future<void> _apply() async {
    final role = _selected;
    if (role == null || _busy) return;
    final current =
        ref.read(profileControllerProvider).valueOrNull?.activeRole;
    if (current == role) {
      // Already active — просто закрываем.
      context.pop();
      return;
    }
    setState(() => _busy = true);
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .setActiveRole(role);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      context.go('${AppRoutes.profileRolesSwitched}?role=${role.name}');
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
    final async = ref.watch(profileControllerProvider);

    return AppScaffold(
      showBack: true,
      title: 'Сменить роль',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить роли',
          onRetry: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profile) {
          // По умолчанию выделена активная роль.
          _selected ??= profile.activeRole;
          return Column(
            children: [
              const SizedBox(height: AppSpacing.x16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.x4),
                child: Text(
                  'Каждая роль — отдельный аккаунт со своими проектами '
                  'и данными. Выберите, в какой роли продолжить работу.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n500,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              Expanded(
                child: ListView.separated(
                  itemCount: profile.roles.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x10),
                  itemBuilder: (_, i) {
                    final entry = profile.roles[i];
                    return _RoleRow(
                      entry: entry,
                      selected: _selected == entry.role,
                      onTap: () => setState(() => _selected = entry.role),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              AppButton(
                label: _selected == profile.activeRole
                    ? 'Это уже основная роль'
                    : 'Сделать основной',
                icon: PhosphorIconsBold.check,
                isLoading: _busy,
                onPressed: _selected == null ||
                        _selected == profile.activeRole
                    ? null
                    : _apply,
              ),
              const SizedBox(height: AppSpacing.x12),
              AppButton(
                label: 'Управление ролями',
                variant: AppButtonVariant.secondary,
                icon: PhosphorIconsRegular.gear,
                onPressed:
                    _busy ? null : () => context.push(AppRoutes.profileRoles),
              ),
              const SizedBox(height: AppSpacing.x16),
            ],
          );
        },
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final UserRoleEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBorder = selected ? AppColors.brand : AppColors.n200;
    final activeBg = selected ? AppColors.brandLight : AppColors.n0;

    return Material(
      color: activeBg,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            border: Border.all(color: activeBorder, width: 2),
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _gradientFor(entry.role),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(
                  _iconFor(entry.role),
                  color: AppColors.n0,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.role.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.n800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (entry.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Сейчас',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenDark,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.role.description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(SystemRole r) => switch (r) {
        SystemRole.customer => PhosphorIconsFill.user,
        SystemRole.contractor => PhosphorIconsFill.wrench,
        SystemRole.master => PhosphorIconsFill.hardHat,
        SystemRole.representative => PhosphorIconsFill.usersThree,
        SystemRole.admin => PhosphorIconsFill.shieldStar,
      };

  static LinearGradient _gradientFor(SystemRole r) => switch (r) {
        SystemRole.customer => AppGradients.avatarBlue,
        SystemRole.contractor => AppGradients.avatarGreen,
        SystemRole.master => AppGradients.avatarYellow,
        SystemRole.representative => AppGradients.avatarPurple,
        SystemRole.admin => AppGradients.avatarGrey,
      };
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.n300,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(PhosphorIconsBold.check, size: 14, color: AppColors.n0)
          : null,
    );
  }
}
