import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../data/materials_repository.dart';
import '../domain/material_request.dart';

final materialsControllerProvider =
    AsyncNotifierProvider.family<
      MaterialsController,
      List<MaterialRequest>,
      String
    >(MaterialsController.new);

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

  void _upsert(MaterialRequest r) {
    final cur = state.value ?? const <MaterialRequest>[];
    final exists = cur.any((x) => x.id == r.id);
    state = AsyncData(
      exists ? cur.map((x) => x.id == r.id ? r : x).toList() : [r, ...cur],
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
}

final materialDetailProvider =
    AsyncNotifierProvider.family<
      MaterialDetailController,
      MaterialRequest,
      String
    >(MaterialDetailController.new);

class MaterialDetailController
    extends FamilyAsyncNotifier<MaterialRequest, String> {
  @override
  Future<MaterialRequest> build(String id) =>
      ref.read(materialsRepositoryProvider).get(id);
}
