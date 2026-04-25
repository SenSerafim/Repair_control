import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_theme_mode.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import 'profile_hero.dart';
import 'profile_menu_group.dart';

/// s-profile — главный экран профиля: hero + группы меню.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileControllerProvider);

    return AppScaffold(
      title: 'Профиль',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить профиль',
          subtitle: e.toString(),
          onRetry: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            children: [
              const SizedBox(height: AppSpacing.x12),
              ProfileHero(
                profile: profile,
                onEdit: () => context.push(AppRoutes.profileEdit),
              ),
              const SizedBox(height: AppSpacing.x20),
              ProfileMenuGroup(
                items: [
                  ProfileMenuItem(
                    icon: Icons.badge_outlined,
                    label: 'Мои роли',
                    hint: '${profile.roles.length} из 4 доступных',
                    onTap: () => context.push(AppRoutes.profileRoles),
                  ),
                  ProfileMenuItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Права представителя',
                    hint: profile.activeRole?.name == 'representative'
                        ? 'Доступно в активной роли'
                        : 'Настраиваются в проекте',
                    onTap: () => context.push(AppRoutes.profileRepRights),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x12),
              ProfileMenuGroup(
                items: [
                  ProfileMenuItem(
                    icon: Icons.construction_outlined,
                    label: 'Мои инструменты',
                    onTap: () => context.push('/profile/tools'),
                  ),
                  ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Уведомления',
                    onTap: () => context.push(AppRoutes.profileNotifSettings),
                  ),
                  ProfileMenuItem(
                    icon: Icons.language_outlined,
                    label: 'Язык',
                    hint: profile.language == 'ru' ? 'Русский' : 'English',
                    onTap: () => context.push(AppRoutes.profileLanguage),
                  ),
                  ProfileMenuItem(
                    icon: Icons.dark_mode_outlined,
                    label: 'Тема',
                    hint: _themeModeLabel(ref.watch(themeModeProvider)),
                    onTap: () => _showThemeSheet(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x12),
              ProfileMenuGroup(
                items: [
                  ProfileMenuItem(
                    icon: Icons.help_outline,
                    label: 'Помощь и FAQ',
                    onTap: () => context.push(AppRoutes.profileHelp),
                  ),
                  ProfileMenuItem(
                    icon: Icons.forum_outlined,
                    label: 'Обратная связь',
                    onTap: () => context.push(AppRoutes.profileFeedback),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x12),
              ProfileMenuGroup(
                items: [
                  ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Выйти',
                    isDestructive: true,
                    onTap: () async {
                      await _confirmLogout(context, ref);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Выйти из аккаунта?',
            subtitle:
                'Потребуется ввести телефон и пароль, чтобы войти снова.',
          ),
          AppButton(
            label: 'Да, выйти',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.x8),
          AppButton(
            label: 'Отмена',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  String _themeModeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
        ThemeMode.system => 'Системная',
      };

  Future<void> _showThemeSheet(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final picked = await showAppBottomSheet<ThemeMode>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Тема приложения',
            subtitle: 'Выберите внешний вид интерфейса',
          ),
          for (final m in ThemeMode.values)
            ListTile(
              leading: Icon(
                switch (m) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.brightness_auto_outlined,
                },
              ),
              title: Text(_themeModeLabel(m)),
              trailing: m == current
                  ? const Icon(Icons.check_rounded, color: AppColors.brand)
                  : null,
              onTap: () => Navigator.of(context).pop(m),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).setMode(picked);
    }
  }
}
