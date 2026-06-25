import 'package:flutter/material.dart';

import 'budget_screen.dart';

/// ТЗ NEWFIX §12: экран «Бюджет этапа» (проект → этап → бюджет).
///
/// Егор 23.06.2026: внешний вид должен совпадать с бюджетом из меню. Поэтому
/// экран — тонкая обёртка над [BudgetScreen] с `lockedStageId`: тот же hero,
/// те же табы «Выплаты»/«Материалы» (зафиксированы на этом этапе, фильтр-пилюли
/// скрыты, таб «История» спрятан), только в шапке — название этапа.
class StageBudgetScreen extends StatelessWidget {
  const StageBudgetScreen({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context) =>
      BudgetScreen(projectId: projectId, lockedStageId: stageId);
}
