import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../projects/application/project_controller.dart';
import '../data/payments_repository.dart';
import '../domain/payment.dart';
import 'budget_controller.dart';

final paymentsControllerProvider =
    AsyncNotifierProvider.family<PaymentsController, List<Payment>, String>(
      PaymentsController.new,
    );

class PaymentsController extends FamilyAsyncNotifier<List<Payment>, String> {
  @override
  Future<List<Payment>> build(String projectId) async {
    final raw = await ref
        .read(paymentsRepositoryProvider)
        .list(projectId: projectId);
    return [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  PaymentsRepository get _repo => ref.read(paymentsRepositoryProvider);

  /// После любого изменения платежей нужно обновить:
  /// 1) бюджет проекта (planned/spent),
  /// 2) карточку проекта (списки/индикаторы),
  /// 3) money-flow (кассу бригадира, историю движений) — family invalidate
  ///    сбрасывает все варианты date-range,
  /// 4) деталь конкретного платежа, если он передан (parent advance после
  ///    distribute должен пересчитать `children` / `remainingToDistribute`).
  void _invalidateAfterMutation({String? paymentDetailId}) {
    ref
      ..invalidate(projectBudgetProvider(arg))
      ..invalidate(projectControllerProvider(arg))
      ..invalidate(moneyFlowProvider(arg))
      ..invalidate(moneyFlowFilteredProvider);
    if (paymentDetailId != null) {
      ref.invalidate(paymentDetailProvider(paymentDetailId));
    }
  }

  void _upsert(Payment p) {
    final cur = state.value ?? const <Payment>[];
    final exists = cur.any((x) => x.id == p.id);
    final next = exists
        ? cur.map((x) => x.id == p.id ? p : x).toList()
        : [p, ...cur];
    state = AsyncData(next);
  }

  Future<AuthFailure?> createAdvance({
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
    String? photoKey,
  }) async {
    try {
      final p = await _repo.createAdvance(
        projectId: arg,
        toUserId: toUserId,
        amount: amount,
        stageId: stageId,
        comment: comment,
        photoKey: photoKey,
      );
      _upsert(p);
      _invalidateAfterMutation();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> distribute({
    required String parentPaymentId,
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
  }) async {
    try {
      final p = await _repo.distribute(
        parentPaymentId: parentPaymentId,
        toUserId: toUserId,
        amount: amount,
        stageId: stageId,
        comment: comment,
      );
      _upsert(p);
      _invalidateAfterMutation(paymentDetailId: parentPaymentId);
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }

  /// Простая выплата мастеру из кассы бригадира — без выбора parent-аванса.
  /// Кнопка-сценарий по умолчанию на BudgetScreen для роли foreman.
  Future<AuthFailure?> distributeFromWallet({
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
  }) async {
    try {
      final p = await _repo.distributeFromWallet(
        projectId: arg,
        toUserId: toUserId,
        amount: amount,
        stageId: stageId,
        comment: comment,
      );
      _upsert(p);
      _invalidateAfterMutation();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }
}

final paymentDetailProvider =
    AsyncNotifierProvider.family<PaymentDetailController, Payment, String>(
      PaymentDetailController.new,
    );

class PaymentDetailController extends FamilyAsyncNotifier<Payment, String> {
  @override
  Future<Payment> build(String paymentId) {
    return ref.read(paymentsRepositoryProvider).get(paymentId);
  }
}
