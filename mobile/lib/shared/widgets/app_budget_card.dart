import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Карточка бюджета консоли — 2 строки (Работы / Материалы) с прогресс-барами.
///
/// Дизайн `Кластер B` (s-console-green/yellow/red).
class AppBudgetCard extends StatelessWidget {
  const AppBudgetCard({
    required this.totalLabel,
    required this.totalValue,
    required this.workSpent,
    required this.workTotal,
    required this.materialsSpent,
    required this.materialsTotal,
    this.workColor = AppColors.brand,
    this.materialsColor = AppColors.greenDot,
    this.onTap,
    super.key,
  });

  final String totalLabel;
  final String totalValue;
  final String workSpent;
  final String workTotal;
  final String materialsSpent;
  final String materialsTotal;
  final Color workColor;
  final Color materialsColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n900,
                ),
              ),
              Text(
                totalValue,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.n900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          _Row(
            label: 'Работы',
            spent: workSpent,
            total: workTotal,
            progress: _ratio(workSpent, workTotal),
            color: workColor,
          ),
          const SizedBox(height: 6),
          _Row(
            label: 'Материалы',
            spent: materialsSpent,
            total: materialsTotal,
            progress: _ratio(materialsSpent, materialsTotal),
            color: materialsColor,
          ),
          if (onTap != null) ...[
            const SizedBox(height: AppSpacing.x10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Подробнее о бюджете',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIconsRegular.arrowRight,
                    size: 11,
                    color: AppColors.brand,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        onTap: onTap,
        child: card,
      ),
    );
  }

  static double _ratio(String spent, String total) {
    final s = double.tryParse(spent.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final t = double.tryParse(total.replaceAll(RegExp(r'\D'), '')) ?? 1;
    return t == 0 ? 0 : (s / t).clamp(0.0, 1.0);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.spent,
    required this.total,
    required this.progress,
    required this.color,
  });

  final String label;
  final String spent;
  final String total;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.n500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progress,
              backgroundColor: AppColors.n100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: spent,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n800,
                ),
              ),
              TextSpan(
                text: ' / $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
