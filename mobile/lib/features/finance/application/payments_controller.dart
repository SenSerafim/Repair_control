import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../projects/application/project_controller.dart';
import '../data/payments_repository.dart';
import '../domain/payment.dart';
import 'budget_controller.dart';

final paymentsControllerProvider = AsyncNotifierProvider.family<
    PaymentsController, List<Payment>, String>(PaymentsController.new);

class PaymentsController extends FamilyAsyncNotifier<List<Payment>, String> {
  @override
  Future<List<Payment>> build(String projectId) async {
    final raw = await ref
        .read(paymentsRepositoryProvider)
        .list(projectId: projectId);
    return [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  PaymentsRepository get _repo => ref.read(paymentsRepositoryProvider);

  void _invalidateBudgetAndProject() {
    ref
      ..invalidate(projectBudgetProvider(arg))
      ..invalidate(projectControllerProvider(arg));
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
      _invalidateBudgetAndProject();
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
      _invalidateBudgetAndProject();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> confirm(String id) async {
    try {
      final p = await _repo.confirm(id);
      _upsert(p);
      _invalidateBudgetAndProject();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> cancel(String id) async {
    try {
      final p = await _repo.cancel(id);
      _upsert(p);
      _invalidateBudgetAndProject();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> dispute({
    required String id,
    required String reason,
    List<String>? photoKeys,
  }) async {
    try {
      final p = await _repo.dispute(id: id, reason: reason, photoKeys: photoKeys);
      _upsert(p);
      _invalidateBudgetAndProject();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> resolve({
    required String id,
    required String resolution,
    int? adjustAmount,
  }) async {
    try {
      final p = await _repo.resolve(
        id: id,
        resolution: resolution,
        adjustAmount: adjustAmount,
      );
      _upsert(p);
      _invalidateBudgetAndProject();
      return null;
    } on PaymentsException catch (e) {
      return e.failure;
    }
  }
}

final paymentDetailProvider = AsyncNotifierProvider.family<
    PaymentDetailController, Payment, String>(PaymentDetailController.new);

class PaymentDetailController extends FamilyAsyncNotifier<Payment, String> {
  @override
  Future<Payment> build(String paymentId) {
    return ref.read(paymentsRepositoryProvider).get(paymentId);
  }
}
