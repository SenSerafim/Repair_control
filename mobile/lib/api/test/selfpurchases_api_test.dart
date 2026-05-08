import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for SelfpurchasesApi
void main() {
  final instance = RepairControlApi().getSelfpurchasesApi();

  group(SelfpurchasesApi, () {
    //Future selfPurchasesControllerApprove(String id, DecideSelfPurchaseDto decideSelfPurchaseDto) async
    test('test selfPurchasesControllerApprove', () async {
      // TODO
    });

    //Future selfPurchasesControllerCreate(String projectId, String idempotencyKey, CreateSelfPurchaseDto createSelfPurchaseDto) async
    test('test selfPurchasesControllerCreate', () async {
      // TODO
    });

    //Future selfPurchasesControllerGet(String id) async
    test('test selfPurchasesControllerGet', () async {
      // TODO
    });

    //Future selfPurchasesControllerList(String projectId, String status, String byUserId) async
    test('test selfPurchasesControllerList', () async {
      // TODO
    });

    //Future selfPurchasesControllerReject(String id, DecideSelfPurchaseDto decideSelfPurchaseDto) async
    test('test selfPurchasesControllerReject', () async {
      // TODO
    });

  });
}
