import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Подложка для шага 14 «Готово» — info-режим, bubble по центру в overlay
/// предлагает «Перейти к приложению». Кнопка вызывает `tourController.advance()`,
/// которое срабатывает как `complete()` и переключает `tutorialCompletedProvider`.
class TourCompletionScreen extends StatelessWidget {
  const TourCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF4F6EF7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.n0.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: AppColors.n0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Отлично!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.n0,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Теперь вы знаете, как работает приложение',
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
