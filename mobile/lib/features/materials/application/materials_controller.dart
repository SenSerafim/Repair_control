import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart' show secureStorageProvider;
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

/// Task 8.2 (TZ-2 §5.4): timestamp последнего просмотра списка заявок
/// проекта. Источник истины — `SecureStorage`. Если ключа нет — `null`,
/// и счётчик «новых» равен 0 (не мигаем бейджем при первом заходе).
///
/// Чисто клиентское решение: бекенд про seen-state не знает. При выходе
/// из аккаунта значения остаются в Keychain/EncryptedSharedPrefs — это
/// ОК, ключи привязаны к projectId, а не к userId, и при смене юзера
/// заявки сами по себе тоже сменятся.
final materialsLastSeenProvider =
    AsyncNotifierProvider.family<
      MaterialsLastSeenController,
      DateTime?,
      String
    >(MaterialsLastSeenController.new);

class MaterialsLastSeenController
    extends FamilyAsyncNotifier<DateTime?, String> {
  @override
  Future<DateTime?> build(String projectId) async {
    return ref.read(secureStorageProvider).readMaterialsLastSeen(projectId);
  }

  /// Отмечает «всё видел» — сохраняем `DateTime.now()` (UTC) и обновляем
  /// state. После этого бейдж сразу пропадает.
  Future<void> markAllSeen() async {
    final now = DateTime.now().toUtc();
    await ref.read(secureStorageProvider).writeMaterialsLastSeen(arg, now);
    state = AsyncData(now);
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

  MaterialsRepository get _repo => ref.read(materialsRepositoryProvider);

  /// Обновляет state на новую версию заявки (после mark-delivered / accept-*).
  void _setRequest(MaterialRequest r) {
    state = AsyncData(r);
  }

  /// Master/foreman/customer: «Доставлено». ТЗ NEWFIX §5.7 шаг 1.
  Future<AuthFailure?> markDelivered({String? comment}) async {
    try {
      final r = await _repo.markDelivered(arg, comment: comment);
      _setRequest(r);
      return null;
    } on MaterialsException catch (e) {
      return e.failure;
    }
  }

  /// Foreman/customer: «Принять частично». ТЗ NEWFIX §5.7 шаги 4–5.
  Future<AuthFailure?> acceptPartial({
    required List<AcceptedItemInput> items,
    String? comment,
  }) async {
    try {
      final r = await _repo.acceptPartial(arg, items: items, comment: comment);
      _setRequest(r);
      return null;
    } on MaterialsException catch (e) {
      return e.failure;
    }
  }

  /// Foreman/customer: «Принять полностью». ТЗ NEWFIX §5.7 шаг 4.
  Future<AuthFailure?> acceptFull({String? comment}) async {
    try {
      final r = await _repo.acceptFull(arg, comment: comment);
      _setRequest(r);
      return null;
    } on MaterialsException catch (e) {
      return e.failure;
    }
  }
}
