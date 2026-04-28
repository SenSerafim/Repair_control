import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/config/app_theme_mode.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../notifications/application/notifications_controller.dart';
import '../application/profile_controller.dart';
import 'delete_account_sheet.dart';
import 'language_sheet.dart';
import 'logout_sheet.dart';
import 'profile_hero.dart';

/// s-profile — главный экран профиля: hero + 4 группы AppMenuRow.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: async.when(
        loading: () => const Center(child: AppLoadingState()),
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
            padding: EdgeInsets.zero,
            children: [
              ProfileHero(
                profile: profile,
                onTapRole: () =>
                    context.push(AppRoutes.profileRoleSwitcher),
              ),
              const SizedBox(height: AppSpacing.x16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
                child: Column(
                  children: [
                    // Группа 1 — личное.
                    AppMenuGroup(
                      children: [
                        AppMenuRow(
                          icon: PhosphorIconsFill.identificationBadge,
                          iconBg: AppColors.purpleBg,
                          iconColor: AppColors.purple,
                          label: 'Мои роли',
                          value:
                              '${profile.roles.length} ${_roleNoun(profile.roles.length)}',
                          onTap: () => context.push(AppRoutes.profileRoles),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.user,
                          iconBg: AppColors.brandLight,
                          iconColor: AppColors.brand,
                          label: 'Данные профиля',
                          onTap: () => context.push(AppRoutes.profileEdit),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.shieldCheck,
                          iconBg: AppColors.purpleBg,
                          iconColor: AppColors.purple,
                          label: 'Права представителя',
                          sub: 'Справочный список доступных действий',
                          onTap: () =>
                              context.push(AppRoutes.profileRepRights),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.wrench,
                          iconBg: AppColors.yellowBg,
                          iconColor: AppColors.yellowText,
                          label: 'Мои инструменты',
                          onTap: () => context.push(AppRoutes.profileTools),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x12),
                    // Группа 2 — активность и события.
                    AppMenuGroup(
                      children: [
                        AppMenuRow(
                          icon: PhosphorIconsFill.bellRinging,
                          iconBg: AppColors.yellowBg,
                          iconColor: AppColors.yellowText,
                          label: 'Лента уведомлений',
                          value: _unreadLabel(ref),
                          onTap: () => context.push(AppRoutes.notifications),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.checkSquare,
                          iconBg: AppColors.purpleBg,
                          iconColor: AppColors.purple,
                          label: 'Мои согласования',
                          sub: 'История и активные запросы',
                          onTap: () => context.push(AppRoutes.approvals),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.bookOpen,
                          iconBg: AppColors.greenLight,
                          iconColor: AppColors.greenDark,
                          label: 'Справочник работ',
                          sub: 'Методология ремонта',
                          onTap: () => context.push(AppRoutes.methodology),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x12),
                    // Группа 3 — настройки приложения.
                    AppMenuGroup(
                      children: [
                        AppMenuRow(
                          icon: PhosphorIconsFill.bell,
                          iconBg: AppColors.brandLight,
                          iconColor: AppColors.brand,
                          label: 'Настройки уведомлений',
                          onTap: () =>
                              context.push(AppRoutes.profileNotifSettings),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.translate,
                          iconBg: AppColors.n100,
                          iconColor: AppColors.n600,
                          label: 'Язык',
                          value: profile.language == 'ru'
                              ? 'Русский'
                              : 'English',
                          onTap: () => _openLanguageSheet(context, ref),
                        ),
                        AppMenuRow(
                          icon: _themeIcon(ref.watch(themeModeProvider)),
                          iconBg: AppColors.n100,
                          iconColor: AppColors.n600,
                          label: 'Тема',
                          value: _themeLabel(ref.watch(themeModeProvider)),
                          onTap: () => _openThemeSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x12),
                    // Группа 4 — поддержка.
                    AppMenuGroup(
                      children: [
                        AppMenuRow(
                          icon: PhosphorIconsFill.question,
                          iconBg: AppColors.greenLight,
                          iconColor: AppColors.greenDark,
                          label: 'Помощь и FAQ',
                          onTap: () => context.push(AppRoutes.profileHelp),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.chatCircleDots,
                          iconBg: AppColors.brandLight,
                          iconColor: AppColors.brand,
                          label: 'Обратная связь',
                          value: 'Telegram',
                          onTap: () =>
                              context.push(AppRoutes.profileFeedback),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x12),
                    AppMenuGroup(
                      children: [
                        AppMenuRow(
                          icon: PhosphorIconsFill.swap,
                          iconBg: AppColors.brandLight,
                          iconColor: AppColors.brand,
                          label: 'Сменить роль',
                          value: profile.activeRole?.displayName,
                          onTap: () =>
                              context.push(AppRoutes.profileRoleSwitcher),
                        ),
                        AppMenuRow(
                          icon: PhosphorIconsFill.signOut,
                          iconBg: AppColors.yellowBg,
                          iconColor: AppColors.yellowText,
                          label: 'Выйти из аккаунта',
                          onTap: () => showLogoutSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x12),
                    AppMenuGroup(
                      children: [
                        AppMenuRow(
                          icon: PhosphorIconsFill.trash,
                          iconBg: AppColors.redBg,
                          iconColor: AppColors.redDot,
                          label: 'Удалить аккаунт',
                          danger: true,
                          onTap: () => showDeleteAccountSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x16),
                    const _VersionFooter(),
                    const SizedBox(height: AppSpacing.x24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleNoun(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'роль';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'роли';
    return 'ролей';
  }

  String? _unreadLabel(WidgetRef ref) {
    final unread =
        ref.watch(notificationsProvider).where((n) => !n.read).length;
    if (unread == 0) return null;
    return unread > 99 ? '99+' : '$unread';
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.light => PhosphorIconsFill.sun,
        ThemeMode.dark => PhosphorIconsFill.moon,
        ThemeMode.system => PhosphorIconsFill.circleHalf,
      };

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
        ThemeMode.system => 'Системная',
      };

  Future<void> _openLanguageSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showLanguageSheet(context, ref);
  }

  Future<void> _openThemeSheet(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final picked = await showAppBottomSheet<ThemeMode>(
      context: context,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBottomSheetHeader(
              title: 'Тема приложения',
              subtitle: 'Выберите внешний вид интерфейса',
            ),
            for (final m in ThemeMode.values)
              AppMenuRow(
                icon: _themeIcon(m),
                iconBg: AppColors.n100,
                iconColor: AppColors.n600,
                label: _themeLabel(m),
                trailing: m == current
                    ? const Icon(
                        PhosphorIconsBold.check,
                        size: 18,
                        color: AppColors.brand,
                      )
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

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x20),
        child: Text(
          'Контроль ремонта v1.0',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.n300,
          ),
        ),
      ),
    );
  }
}
