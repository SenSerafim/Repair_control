import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payments_repository.dart';
import '../domain/budget.dart';

final projectBudgetProvider = AsyncNotifierProvider.family<
    ProjectBudgetController, ProjectBudget, String>(
  ProjectBudgetController.new,
);

class ProjectBudgetController
    extends FamilyAsyncNotifier<ProjectBudget, String> {
  @override
  Future<ProjectBudget> build(String projectId) {
    return ref.read(paymentsRepositoryProvider).projectBudget(projectId);
  }
}

final stageBudgetProvider = AsyncNotifierProvider.family<
    StageBudgetController, StageBudget?, String>(
  StageBudgetController.new,
);

class StageBudgetController
    extends FamilyAsyncNotifier<StageBudget?, String> {
  @override
  Future<StageBudget?> build(String stageId) {
    return ref.read(paymentsRepositoryProvider).stageBudget(stageId);
  }
}
