import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Шапка bottom-sheet'а — узкая n200-пилюля 40×4 по центру.
///
/// Дизайн `Кластер F` (`f-chat-new`, `f-chat-forward`, `f-doc-share`).
class AppDragHandle extends StatelessWidget {
  const AppDragHandle({this.bottom = 20, super.key});

  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: bottom),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.n200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
