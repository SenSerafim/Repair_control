import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Inline-бейдж «Неизменяемое» с иконкой замочка для feed-events.
///
/// Дизайн `Кластер F` (`f-feed`): pill `bg n100 + color n400 + 10/700 +
/// padding 2×6 + radius 4`. Используется на approved/completed/paid/
/// partial_purchase/dateChanged event-items.
class AppImmutableBadge extends StatelessWidget {
  const AppImmutableBadge({
    this.text = 'Неизменяемое',
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 10, color: AppColors.n400),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.n400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
