import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Pill-badge с цветовой точкой 8×8 и подписью — соответствует `.traffic-badge`
/// + `.tb-dot` из дизайна `Кластер B`.
///
/// Точные размеры из CSS:
/// - height: 28px
/// - padding: `0 12px`
/// - dot: 8×8 (border-radius 50%)
/// - gap (dot↔text): 6px
/// - font: 11px / weight 700
/// - border-radius: 100px (pill)
class AppTrafficBadge extends StatelessWidget {
  const AppTrafficBadge({
    required this.label,
    required this.semaphore,
    super.key,
  });

  final String label;
  final Semaphore semaphore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: semaphore.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: semaphore.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(
              color: semaphore.text,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
