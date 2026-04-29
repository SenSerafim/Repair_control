import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// «Попытка N» pill — `design/Кластер D` карточки и хедер деталей.
///
/// При `attemptNumber == 1` бейдж скрыт (возвращается `SizedBox.shrink`).
/// При `attemptNumber >= 2` подсвечивается красным (`redBg`/`redText`) —
/// сигнал, что согласование уже отклонялось.
class AttemptBadge extends StatelessWidget {
  const AttemptBadge({required this.attemptNumber, super.key});

  final int attemptNumber;

  @override
  Widget build(BuildContext context) {
    if (attemptNumber <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Попытка $attemptNumber',
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.redText,
          height: 1.2,
        ),
      ),
    );
  }
}
