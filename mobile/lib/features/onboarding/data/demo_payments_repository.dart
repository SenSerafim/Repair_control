import 'package:dio/dio.dart';

import '../../finance/data/payments_repository.dart';
import '../../finance/domain/budget.dart';
import '../../finance/domain/money_flow.dart';
import '../../finance/domain/payment.dart';
import 'demo_data.dart';

/// Mock-репозиторий платежей и бюджета для демо-тура.
class DemoPaymentsRepository extends PaymentsRepository {
  DemoPaymentsRepository() : super(Dio());

  @override
  Future<ProjectBudget> projectBudget(String projectId) async =>
      DemoData.projectBudget;

  @override
  Future<MoneyFlow> moneyFlow(
    String projectId, {
    DateTime? from,
    DateTime? to,
  }) async {
    return const MoneyFlow(
      advances: [],
      distributions: [],
      approvedSelfpurchases: [],
      materialPurchases: [],
      totals: MoneyFlowTotals(
        advances: 0,
        distributed: 0,
        undistributed: 0,
        approvedSelfpurchases: 0,
        materials: 0,
      ),
    );
  }

  @override
  Future<StageBudget?> stageBudget(String stageId) async {
    final stage = DemoData.projectBudget.stages
        .where((b) => b.stageId == stageId)
        .firstOrNull;
    return stage;
  }

  @override
  Future<List<Payment>> list({
    required String projectId,
    PaymentStatus? status,
    PaymentKind? kind,
    String? userId,
  }) async {
    Iterable<Payment> result = DemoData.payments;
    if (status != null) result = result.where((p) => p.status == status);
    if (kind != null) result = result.where((p) => p.kind == kind);
    if (userId != null) {
      result = result.where(
        (p) => p.fromUserId == userId || p.toUserId == userId,
      );
    }
    return result.toList();
  }

  @override
  Future<Payment> get(String id) async => DemoData.paymentById(id);

  @override
  Future<Payment> createAdvance({
    required String projectId,
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
    String? photoKey,
  }) async =>
      DemoData.payments.first;

  @override
  Future<Payment> distribute({
    required String parentPaymentId,
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
    String? photoKey,
  }) async =>
      DemoData.payments.first;

  @override
  Future<Payment> confirm(String id) async => DemoData.paymentById(id);

  @override
  Future<Payment> cancel(String id) async => DemoData.paymentById(id);

  @override
  Future<Payment> dispute({
    required String id,
    required String reason,
    List<String>? photoKeys,
  }) async =>
      DemoData.paymentById(id);

  @override
  Future<Payment> resolve({
    required String id,
    required String resolution,
    int? adjustAmount,
  }) async =>
      DemoData.paymentById(id);
}
