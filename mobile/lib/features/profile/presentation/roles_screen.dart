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

/// s-roles — список доступных ролей с активной + dashed-кнопка добавления.
class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  bool _switching = false;

  Future<void> _setActive(SystemRole role) async {
    setState(() => _switching = true);
    final failure =
        await ref.read(profileControllerProvider.notifier).setActiveRole(role);
    if (!mounted) return;
    setState(() => _switching = false);
    if (failure == null) {
      // Открываем экран успеха.
      context.push(
        '${AppRoutes.profileRolesSwitched}?role=${role.name}',
      );
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _openAddRoleSheet(List<UserRoleEntry> existing) async {
    final used = existing.map((e) => e.role).toSet();
    final available = SystemRole.registerable
        .where((r) => !used.contains(r))
        .toList();
    if (available.isEmpty) {
      AppToast.show(context, message: 'Все роли уже добавлены');
      return;
    }
    final picked = await showAppBottomSheet<SystemRole>(
      context: context,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(
              title: 'Добавить роль',
              subtitle: 'Выберите роль, которую хотите добавить',
            ),
            for (final r in available) ...[
              AppRoleCard.kind(
                kind: _kindFor(r),
                onTap: () => Navigator.of(ctx).pop(r),
              ),
              const SizedBox(height: AppSpacing.x10),
            ],
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      final failure =
          await ref.read(profileControllerProvider.notifier).addRole(picked);
      if (!mounted) return;
      if (failure == null) {
        AppToast.show(
          context,
          message: 'Роль «${picked.displayName}» добавлена',
          kind: AppToastKind.success,
        );
      } else {
        AppToast.show(
          context,
          message: failure.userMessage,
          kind: AppToastKind.error,
        );
      }
    }
  }

  static AppRoleKind _kindFor(SystemRole role) => switch (role) {
        SystemRole.customer => AppRoleKind.customer,
        SystemRole.contractor => AppRoleKind.foreman,
        SystemRole.master => AppRoleKind.master,
        SystemRole.representative => AppRoleKind.representative,
        SystemRole.admin => AppRoleKind.customer,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profileControllerProvider);

    return AppScaffold(
      showBack: true,
      title: 'Мои роли',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить роли',
          onRetry: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
          children: [
            const Text(
              'Каждая роль — отдельный аккаунт со своими проектами. '
              'Здесь — управление списком ролей. Чтобы переключиться '
              'между ними, используйте «Сменить роль» в профиле.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.n500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            for (final entry in profile.roles) ...[
              _RoleRow(
                entry: entry,
                isSwitching: _switching,
                onTap: entry.isActive ? null : () => _setActive(entry.role),
              ),
              const SizedBox(height: AppSpacing.x10),
            ],
            const SizedBox(height: AppSpacing.x6),
            _DashedAddButton(
              onTap: () => _openAddRoleSheet(profile.roles),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.entry,
    required this.onTap,
    required this.isSwitching,
  });

  final UserRoleEntry entry;
  final VoidCallback? onTap;
  final bool isSwitching;

  @override
  Widget build(BuildContext context) {
    final activeBorder = entry.isActive ? AppColors.brand : AppColors.n200;
    final activeBg = entry.isActive ? AppColors.brandLight : AppColors.n0;

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
                    Text(
                      entry.role.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.isActive
                          ? 'Активная роль'
                          : 'Переключиться',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Активна',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n0,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else if (isSwitching)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 18,
                  color: AppColors.n300,
                ),
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

class _DashedAddButton extends StatelessWidget {
  const _DashedAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppDashedBorder(
        color: AppColors.n300,
        borderRadius: AppRadius.r16,
        height: 56,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsBold.plus,
              color: AppColors.brand,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.x6),
            const Text(
              'Добавить роль',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
