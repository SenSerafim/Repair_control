import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payments_repository.dart';
import '../domain/budget.dart';
import '../domain/money_flow.dart';

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

/// P1.5: «Движение средств» проекта. Для customer/representative.canSeeBudget
/// возвращает 4 секции (advances/distributions/approvedSelfpurchases/materialPurchases)
/// + totals. Для остальных — пустой объект.
final moneyFlowProvider =
    AsyncNotifierProvider.family<MoneyFlowController, MoneyFlow, String>(
  MoneyFlowController.new,
);

class MoneyFlowController extends FamilyAsyncNotifier<MoneyFlow, String> {
  @override
  Future<MoneyFlow> build(String projectId) {
    return ref.read(paymentsRepositoryProvider).moneyFlow(projectId);
  }
}
