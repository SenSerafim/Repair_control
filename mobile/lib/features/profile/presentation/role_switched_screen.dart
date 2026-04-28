import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// s-role-switched — full-screen success после смены активной роли.
///
/// Параметры передаются через query: `?role=contractor` (`SystemRole.name`).
class RoleSwitchedScreen extends StatelessWidget {
  const RoleSwitchedScreen({required this.role, super.key});

  final SystemRole role;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: '',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.successHero,
              borderRadius: BorderRadius.circular(AppRadius.r24),
              boxShadow: AppShadows.shGreen,
            ),
            child: Icon(
              PhosphorIconsFill.usersThree,
              color: AppColors.n0,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          const Text(
            'Роль переключена',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Вы теперь: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n500,
                  ),
                ),
                TextSpan(
                  text: role.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: const Text(
              'Проекты и данные обновлены. Вы видите проекты, '
              'назначенные вам в этой роли.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n400,
                height: 1.55,
              ),
            ),
          ),
          const Spacer(flex: 3),
          AppButton(
            label: 'К проектам',
            onPressed: () => context.go(AppRoutes.projects),
          ),
          const SizedBox(height: AppSpacing.x10),
          AppButton(
            label: 'Назад к ролям',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.x24),
        ],
      ),
    );
  }
}
