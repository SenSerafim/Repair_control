import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum AppFeedDotTone {
  /// Старт действия (begin step / begin stage).
  start,

  /// Одобрение / завершение / подтверждение.
  success,

  /// Пауза / сдвиг дедлайна / предупреждение.
  warning,

  /// Отклонение / спор / просрочка.
  danger,

  /// Частичная закупка / специфические события.
  info,
}

/// 10×10 цветная точка слева от feed-event row.
///
/// Цвета по дизайну `Кластер F` (`f-feed`).
class AppFeedDot extends StatelessWidget {
  const AppFeedDot({required this.tone, this.size = 10, super.key});

  final AppFeedDotTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: _toneColor(tone),
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _toneColor(AppFeedDotTone tone) {
  switch (tone) {
    case AppFeedDotTone.start:
      return AppColors.brand;
    case AppFeedDotTone.success:
      return AppColors.greenDot;
    case AppFeedDotTone.warning:
      return AppColors.yellowDot;
    case AppFeedDotTone.danger:
      return AppColors.redDot;
    case AppFeedDotTone.info:
      return AppColors.purple;
  }
}
