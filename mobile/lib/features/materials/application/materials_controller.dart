import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../finance/application/budget_controller.dart';
import '../data/materials_repository.dart';
import '../domain/material_request.dart';

final materialsControllerProvider = AsyncNotifierProvider.family<
    MaterialsController, List<MaterialRequest>, String>(
  MaterialsController.new,
);

class MaterialsController
    extends FamilyAsyncNotifier<List<MaterialRequest>, String> {
  @override
  Future<List<MaterialRequest>> build(String projectId) async {
    final raw = await ref
        .read(materialsRepositoryProvider)
        .list(projectId: projectId);
    return [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  MaterialsRepository get _repo => ref.read(materialsRepositoryProvider);

  void _invalidateBudget() {
    ref.invalidate(projectBudgetProvider(arg));
  }

  void _upsert(MaterialRequest r) {
    final cur = state.value ?? const <MaterialRequest>[];
    final exists = cur.any((x) => x.id == r.id);
    state = AsyncData(
      exists
          ? cur.map((x) => x.id == r.id ? r : x).toList()
          : [r, ...cur],
    );
  }

  Future<AuthFailure?> create({
    required MaterialRecipient recipient,
    required String title,
    required List<MaterialItemInput> items,
    String? stageId,
    String? comment,
  }) async {
    try {
      final r = await _repo.create(
        projectId: arg,
        recipient: recipient,
        title: title,
        items: items,
        stageId: stageId,
        comment: comment,
      );
      _upsert(r);
      return null;
    } on MaterialsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> send(String id) => _run(() => _repo.send(id));
  Future<AuthFailure?> markBought({
    required String requestId,
    required String itemId,
    required int pricePerUnit,
  }) =>
      _run(
        () => _repo.markBought(
          requestId: requestId,
          itemId: itemId,
          pricePerUnit: pricePerUnit,
        ),
      );
  Future<AuthFailure?> finalizeRequest(String id) async {
    final failure = await _run(() => _repo.finalizeRequest(id));
    if (failure == null) _invalidateBudget();
    return failure;
  }

  Future<AuthFailure?> confirmDelivery(String id) =>
      _run(() => _repo.confirmDelivery(id));
  Future<AuthFailure?> dispute({required String id, required String reason}) =>
      _run(() => _repo.dispute(id: id, reason: reason));
  Future<AuthFailure?> resolve({
    required String id,
    required String resolution,
  }) async {
    final failure =
        await _run(() => _repo.resolve(id: id, resolution: resolution));
    if (failure == null) _invalidateBudget();
    return failure;
  }

  Future<AuthFailure?> _run(Future<MaterialRequest> Function() fn) async {
    try {
      final r = await fn();
      _upsert(r);
      return null;
    } on MaterialsException catch (e) {
      return e.failure;
    }
  }
}

final materialDetailProvider = AsyncNotifierProvider.family<
    MaterialDetailController, MaterialRequest, String>(
  MaterialDetailController.new,
);

class MaterialDetailController
    extends FamilyAsyncNotifier<MaterialRequest, String> {
  @override
  Future<MaterialRequest> build(String id) =>
      ref.read(materialsRepositoryProvider).get(id);
}
