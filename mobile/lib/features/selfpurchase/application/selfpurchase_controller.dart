import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../finance/application/budget_controller.dart';
import '../data/selfpurchase_repository.dart';
import '../domain/self_purchase.dart';

final selfpurchasesControllerProvider = AsyncNotifierProvider.family<
    SelfpurchasesController, List<SelfPurchase>, String>(
  SelfpurchasesController.new,
);

class SelfpurchasesController
    extends FamilyAsyncNotifier<List<SelfPurchase>, String> {
  @override
  Future<List<SelfPurchase>> build(String projectId) async {
    final raw = await ref
        .read(selfPurchaseRepositoryProvider)
        .list(projectId: projectId);
    return [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  SelfPurchaseRepository get _repo =>
      ref.read(selfPurchaseRepositoryProvider);

  void _upsert(SelfPurchase r) {
    final cur = state.value ?? const <SelfPurchase>[];
    final exists = cur.any((x) => x.id == r.id);
    state = AsyncData(
      exists
          ? cur.map((x) => x.id == r.id ? r : x).toList()
          : [r, ...cur],
    );
  }

  Future<AuthFailure?> create({
    required int amount,
    String? stageId,
    String? comment,
    List<String>? photoKeys,
  }) async {
    try {
      final r = await _repo.create(
        projectId: arg,
        amount: amount,
        stageId: stageId,
        comment: comment,
        photoKeys: photoKeys,
      );
      _upsert(r);
      return null;
    } on SelfPurchaseException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> approve({required String id, String? comment}) =>
      _run(() => _repo.approve(id: id, comment: comment));

  Future<AuthFailure?> reject({required String id, String? comment}) =>
      _run(() => _repo.reject(id: id, comment: comment));

  Future<AuthFailure?> _run(Future<SelfPurchase> Function() fn) async {
    try {
      final r = await fn();
      _upsert(r);
      // Одобренный selfpurchase попадает в бюджет.
      if (r.status == SelfPurchaseStatus.approved) {
        ref.invalidate(projectBudgetProvider(arg));
      }
      return null;
    } on SelfPurchaseException catch (e) {
      return e.failure;
    }
  }
}
