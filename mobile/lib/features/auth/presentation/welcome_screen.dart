import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// s-welcome — брендовый стартовый экран.
///
/// Дизайн: тёмный градиент (heroDark), полупрозрачный логотип-щит с
/// галочкой, белая «Зарегистрироваться» и outline-белая «Войти в аккаунт».
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.heroDark),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  _Logo(),
                  const SizedBox(height: AppSpacing.x32),
                  const Text(
                    'Контроль ремонта',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n0,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.x20),
                    child: Text(
                      'Управляйте строительством удалённо — '
                      'в реальном времени',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0x8CFFFFFF),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  AppButton(
                    label: 'Зарегистрироваться',
                    variant: AppButtonVariant.white,
                    onPressed: () => context.go(AppRoutes.register),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  AppButton(
                    label: 'Войти в аккаунт',
                    variant: AppButtonVariant.outlineWhite,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: AppSpacing.x24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0x4DFFFFFF)),
        ),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.n0,
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIconsFill.shieldCheck,
            color: AppColors.brand,
            size: 32,
          ),
        ),
      ),
    );
  }
}
