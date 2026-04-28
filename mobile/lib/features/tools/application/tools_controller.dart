import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../data/tools_repository.dart';
import '../domain/tool.dart';

final myToolsProvider =
    AsyncNotifierProvider<MyToolsController, List<ToolItem>>(
  MyToolsController.new,
);

class MyToolsController extends AsyncNotifier<List<ToolItem>> {
  @override
  Future<List<ToolItem>> build() {
    return ref.read(toolsRepositoryProvider).myTools();
  }

  ToolsRepository get _repo => ref.read(toolsRepositoryProvider);

  void _upsert(ToolItem t) {
    final cur = state.value ?? const <ToolItem>[];
    final exists = cur.any((x) => x.id == t.id);
    state = AsyncData(
      exists
          ? cur.map((x) => x.id == t.id ? t : x).toList()
          : [t, ...cur],
    );
  }

  Future<AuthFailure?> create({
    required String name,
    required int totalQty,
    String? unit,
    String? photoKey,
  }) async {
    try {
      final t = await _repo.createTool(
        name: name,
        totalQty: totalQty,
        unit: unit,
        photoKey: photoKey,
      );
      _upsert(t);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> saveUpdate({
    required String id,
    String? name,
    int? totalQty,
    String? unit,
  }) async {
    try {
      final t = await _repo.updateTool(
        id: id,
        name: name,
        totalQty: totalQty,
        unit: unit,
      );
      _upsert(t);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> remove(String id) async {
    try {
      await _repo.deleteTool(id);
      final cur = state.value ?? const <ToolItem>[];
      state = AsyncData(cur.where((t) => t.id != id).toList());
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }
}

/// Один инструмент по id (для tool detail / редактирования).
final toolDetailProvider = FutureProvider.family<ToolItem, String>((ref, id) {
  return ref.read(toolsRepositoryProvider).getTool(id);
});

final toolIssuancesProvider = AsyncNotifierProvider.family<
    ToolIssuancesController, List<ToolIssuance>, String>(
  ToolIssuancesController.new,
);

class ToolIssuancesController
    extends FamilyAsyncNotifier<List<ToolIssuance>, String> {
  @override
  Future<List<ToolIssuance>> build(String projectId) async {
    final raw =
        await ref.read(toolsRepositoryProvider).listIssuances(projectId);
    return [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ToolsRepository get _repo => ref.read(toolsRepositoryProvider);

  void _upsert(ToolIssuance i) {
    final cur = state.value ?? const <ToolIssuance>[];
    final exists = cur.any((x) => x.id == i.id);
    state = AsyncData(
      exists
          ? cur.map((x) => x.id == i.id ? i : x).toList()
          : [i, ...cur],
    );
  }

  Future<AuthFailure?> issue({
    required String toolItemId,
    required String toUserId,
    required int qty,
    String? stageId,
  }) async {
    try {
      final iss = await _repo.issue(
        projectId: arg,
        toolItemId: toolItemId,
        toUserId: toUserId,
        qty: qty,
        stageId: stageId,
      );
      _upsert(iss);
      ref.invalidate(myToolsProvider); // issuedQty меняется
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> confirm(String id) => _run(() => _repo.confirm(id));

  Future<AuthFailure?> requestReturn({
    required String id,
    required int returnedQty,
  }) =>
      _run(() => _repo.requestReturn(id: id, returnedQty: returnedQty));

  Future<AuthFailure?> returnConfirm(String id) async {
    final failure = await _run(() => _repo.returnConfirm(id));
    if (failure == null) ref.invalidate(myToolsProvider);
    return failure;
  }

  Future<AuthFailure?> _run(Future<ToolIssuance> Function() fn) async {
    try {
      final i = await fn();
      _upsert(i);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }
}
