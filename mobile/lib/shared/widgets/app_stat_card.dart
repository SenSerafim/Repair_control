import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Мини-карточка статистики (3 в row на консоли).
///
/// Дизайн `Кластер B` (s-console-*): label uppercase, value большая
/// с опциональным подчинённым "/total", subtext, тонкий progress bar.
/// Цвет value/bar — по semaphore.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    this.total,
    required this.subtext,
    required this.progress,
    this.semaphore = Semaphore.green,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final String? total;
  final String subtext;
  final double progress; // 0..1
  final Semaphore semaphore;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.n400,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: valueColor ?? AppColors.n900,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                if (total != null)
                  TextSpan(
                    text: '/$total',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.n400,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.n400,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.n100,
              valueColor: AlwaysStoppedAnimation<Color>(semaphore.dot),
            ),
          ),
        ],
      ),
    );
  }
}
