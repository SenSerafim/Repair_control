import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for MaterialsApi
void main() {
  final instance = RepairControlApi().getMaterialsApi();

  group(MaterialsApi, () {
    //Future materialsControllerConfirmDelivery(String id) async
    test('test materialsControllerConfirmDelivery', () async {
      // TODO
    });

    //Future materialsControllerCreate(String projectId, CreateMaterialRequestDto createMaterialRequestDto) async
    test('test materialsControllerCreate', () async {
      // TODO
    });

    //Future materialsControllerDispute(String id, DisputeMaterialDto disputeMaterialDto) async
    test('test materialsControllerDispute', () async {
      // TODO
    });

    //Future materialsControllerFinalize(String id) async
    test('test materialsControllerFinalize', () async {
      // TODO
    });

    //Future materialsControllerGet(String id) async
    test('test materialsControllerGet', () async {
      // TODO
    });

    //Future materialsControllerList(String projectId, String status, String stageId) async
    test('test materialsControllerList', () async {
      // TODO
    });

    //Future materialsControllerMarkBought(String id, String itemId, MarkBoughtDto markBoughtDto) async
    test('test materialsControllerMarkBought', () async {
      // TODO
    });

    //Future materialsControllerResolve(String id, ResolveMaterialDto resolveMaterialDto) async
    test('test materialsControllerResolve', () async {
      // TODO
    });

    //Future materialsControllerSend(String id) async
    test('test materialsControllerSend', () async {
      // TODO
    });
  });
}
