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
                    icon: Icons.history_rounded,
                    label: 'Лента уведомлений',
                    hint: 'Все push-уведомления',
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  ProfileMenuItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Мои согласования',
                    hint: 'История и активные запросы',
                    onTap: () => context.push(AppRoutes.approvals),
                  ),
                  ProfileMenuItem(
                    icon: Icons.construction_outlined,
                    label: 'Мои инструменты',
                    onTap: () => context.push('/profile/tools'),
                  ),
                  ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Настройки уведомлений',
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
    // Builder обязателен: showAppBottomSheet pushes на root-navigator, а
    // `context` родителя ссылается на shell-navigator. `Navigator.of(ctx)`
    // из builder-scope находит ближайший — root, и pop корректно закрывает
    // sheet даже после того как ProfileScreen unmounted (race-condition
    // при logout → router redirect → ShellRoute disposed).
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      child: Builder(
        builder: (ctx) => Column(
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
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: AppSpacing.x8),
            AppButton(
              label: 'Отмена',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (confirmed ?? false) {
      // logout() меняет authState → unauthenticated → GoRouter redirect
      // на welcome. Сами Navigator.pop() не вызываем — sheet уже закрыт
      // builder'ом, остальное за router'ом.
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
      child: Builder(
        builder: (ctx) => Column(
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
                onTap: () => Navigator.of(ctx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).setMode(picked);
    }
  }
}
