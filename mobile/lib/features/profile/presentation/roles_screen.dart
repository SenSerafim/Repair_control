import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/system_role.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/role_picker.dart';
import '../application/profile_controller.dart';
import '../domain/user_profile.dart';

/// s-roles — текущие роли с активной, возможность переключить
/// и добавить/удалить.
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
      AppToast.show(
        context,
        message: 'Активная роль: ${role.displayName}',
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

  Future<void> _openAddRoleSheet(List<UserRoleEntry> existing) async {
    final available = SystemRole.registerable
        .where((r) => !existing.any((e) => e.role == r))
        .toList();
    if (available.isEmpty) {
      AppToast.show(
        context,
        message: 'Все роли уже добавлены',
      );
      return;
    }
    final picked = await showAppBottomSheet<SystemRole>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Добавить роль',
            subtitle: 'Вы сможете переключаться между ролями в любой момент.',
          ),
          for (final r in available) ...[
            RoleCard(
              role: r,
              selected: false,
              onTap: () => Navigator.of(context).pop(r),
            ),
            const SizedBox(height: AppSpacing.x10),
          ],
        ],
      ),
    );
    if (picked != null) {
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
          children: [
            const SizedBox(height: AppSpacing.x16),
            const Text(
              'Нажмите на роль, чтобы сделать её активной.',
              style: AppTextStyles.bodyMedium,
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
            const SizedBox(height: AppSpacing.x12),
            AppButton(
              label: 'Добавить роль',
              variant: AppButtonVariant.ghost,
              onPressed: () => _openAddRoleSheet(profile.roles),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.x16),
        decoration: BoxDecoration(
          color: entry.isActive ? AppColors.brandLight : AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: entry.isActive ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.role.displayName, style: AppTextStyles.h2),
                  const SizedBox(height: 2),
                  Text(
                    entry.isActive ? 'Активная роль' : 'Переключиться',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (entry.isActive)
              const Icon(
                Icons.check_circle,
                color: AppColors.brand,
                size: 22,
              )
            else if (isSwitching)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n300,
              ),
          ],
        ),
      ),
    );
  }
}
