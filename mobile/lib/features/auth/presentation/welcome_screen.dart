import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// s-welcome — брендовый стартовый экран.
///
/// Дизайн: тёмный градиент (heroDark) + 2 радиальных blob'а для глубины,
/// логотип-щит с inset highlight и насыщенным glow, заголовок с subtle
/// текстовой тенью. Соответствует CSS-эталону в `design/Кластер_A___Профиль.html`.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.heroDark),
          child: Stack(
            children: [
              // Декоративные radial-blob слои (brand + purple) — эмулируют
              // CSS overlay из дизайн-референса.
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroBlobBrand,
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroBlobPurple,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x20,
                  ),
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
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.n0,
                          letterSpacing: -0.85,
                          height: 1.12,
                          shadows: [
                            Shadow(
                              color: Color(0x4D4F6EF7),
                              offset: Offset(0, 2),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x14),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.x20,
                        ),
                        child: Text(
                          'Управляйте строительством удалённо — '
                          'в реальном времени',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0x9EFFFFFF),
                            height: 1.45,
                            letterSpacing: -0.1,
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
            ],
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
        width: 104,
        height: 104,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x24FFFFFF), Color(0x0AFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0x2EFFFFFF)),
          boxShadow: const [
            // Brand-glow + ближняя тёмная тень — соответствует CSS hero-logo.
            BoxShadow(
              color: Color(0x524F6EF7),
              offset: Offset(0, 12),
              blurRadius: 40,
            ),
            BoxShadow(
              color: Color(0x4D000000),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FD)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33FFFFFF),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            PhosphorIconsFill.shieldCheck,
            color: AppColors.brand,
            size: 32,
          ),
        ),
      ),
    );
  }
}
