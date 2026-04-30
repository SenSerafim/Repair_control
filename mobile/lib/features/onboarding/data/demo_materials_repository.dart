import 'package:dio/dio.dart';

import '../../materials/data/materials_repository.dart';
import '../../materials/domain/material_request.dart';
import 'demo_data.dart';

/// Mock-репозиторий материалов для демо-тура.
class DemoMaterialsRepository extends MaterialsRepository {
  DemoMaterialsRepository() : super(Dio());

  @override
  Future<List<MaterialRequest>> list({
    required String projectId,
    MaterialRequestStatus? status,
  }) async {
    if (status != null) {
      return DemoData.materialRequests.where((m) => m.status == status).toList();
    }
    return DemoData.materialRequests;
  }

  @override
  Future<MaterialRequest> get(String id) async => DemoData.materialById(id);

  @override
  Future<MaterialRequest> create({
    required String projectId,
    required MaterialRecipient recipient,
    required String title,
    required List<MaterialItemInput> items,
    String? stageId,
    String? comment,
  }) async =>
      DemoData.materialRequests.first;

  @override
  Future<MaterialRequest> send(String id) async => DemoData.materialById(id);

  @override
  Future<MaterialRequest> markBought({
    required String requestId,
    required String itemId,
    required int pricePerUnit,
  }) async =>
      DemoData.materialById(requestId);

  @override
  Future<MaterialRequest> finalizeRequest(String id) async =>
      DemoData.materialById(id);

  @override
  Future<MaterialRequest> confirmDelivery(String id) async =>
      DemoData.materialById(id);

  @override
  Future<MaterialRequest> dispute({
    required String id,
    required String reason,
  }) async =>
      DemoData.materialById(id);

  @override
  Future<MaterialRequest> resolve({
    required String id,
    required String resolution,
  }) async =>
      DemoData.materialById(id);
}
