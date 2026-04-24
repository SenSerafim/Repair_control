import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// s-welcome — первичный экран, брендовый.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.r28),
              boxShadow: AppShadows.shBlue,
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: AppColors.n0,
              size: 56,
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          const Text(
            'Repair Control',
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: AppSpacing.x8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: Text(
              'Контроль ремонта для заказчика, представителя, '
              'бригадира и мастера.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const Spacer(flex: 3),
          AppButton(
            label: 'Войти',
            onPressed: () => context.go(AppRoutes.login),
          ),
          const SizedBox(height: AppSpacing.x12),
          AppButton(
            label: 'Регистрация',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.register),
          ),
          const SizedBox(height: AppSpacing.x24),
        ],
      ),
    );
  }
}
