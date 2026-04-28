import 'package:flutter/foundation.dart';
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

/// Параметр для фильтрации money-flow по периоду — равенство по
/// `(projectId, fromIso, toIso)` гарантирует Riverpod-кеш на одинаковый запрос.
@immutable
class MoneyFlowQuery {
  const MoneyFlowQuery({required this.projectId, this.from, this.to});

  final String projectId;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      other is MoneyFlowQuery &&
      other.projectId == projectId &&
      other.from?.toIso8601String() == from?.toIso8601String() &&
      other.to?.toIso8601String() == to?.toIso8601String();

  @override
  int get hashCode => Object.hash(projectId, from, to);
}

/// Эта версия принимает date-range — используется в табе «Материалы»
/// бюджета (e-budget-materials) для фильтрации по периоду.
final moneyFlowFilteredProvider = AsyncNotifierProvider.family<
    MoneyFlowFilteredController, MoneyFlow, MoneyFlowQuery>(
  MoneyFlowFilteredController.new,
);

class MoneyFlowFilteredController
    extends FamilyAsyncNotifier<MoneyFlow, MoneyFlowQuery> {
  @override
  Future<MoneyFlow> build(MoneyFlowQuery query) {
    return ref.read(paymentsRepositoryProvider).moneyFlow(
          query.projectId,
          from: query.from,
          to: query.to,
        );
  }
}
