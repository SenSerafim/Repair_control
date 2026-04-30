import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Подложка для шага 1 «Welcome» — показывается под `TourOverlay`-ом
/// в info-режиме (bubble по центру). Сама по себе не интерактивна,
/// единственное взаимодействие — кнопка «Далее» в overlay-bubble,
/// которая продвигает шаг.
class WelcomeTourScreen extends StatelessWidget {
  const WelcomeTourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F6EF7), Color(0xFF6D28D9)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_work_rounded,
                size: 96,
                color: AppColors.n0,
              ),
              const SizedBox(height: 24),
              Text(
                'Repair Control',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.n0,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Управление ремонтом для всех участников',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.n0.withValues(alpha: 0.85),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
