import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for PaymentsApi
void main() {
  final instance = RepairControlApi().getPaymentsApi();

  group(PaymentsApi, () {
    //Future paymentsControllerCancel(String id) async
    test('test paymentsControllerCancel', () async {
      // TODO
    });

    //Future paymentsControllerConfirm(String id) async
    test('test paymentsControllerConfirm', () async {
      // TODO
    });

    //Future paymentsControllerCreateAdvance(String projectId, String idempotencyKey, CreateAdvanceDto createAdvanceDto) async
    test('test paymentsControllerCreateAdvance', () async {
      // TODO
    });

    //Future paymentsControllerDispute(String id, DisputePaymentDto disputePaymentDto) async
    test('test paymentsControllerDispute', () async {
      // TODO
    });

    //Future paymentsControllerDistribute(String id, String idempotencyKey, DistributeDto distributeDto) async
    test('test paymentsControllerDistribute', () async {
      // TODO
    });

    //Future paymentsControllerGet(String id) async
    test('test paymentsControllerGet', () async {
      // TODO
    });

    //Future paymentsControllerList(String projectId, String status, String kind, String userId) async
    test('test paymentsControllerList', () async {
      // TODO
    });

    //Future paymentsControllerProjectBudget(String projectId) async
    test('test paymentsControllerProjectBudget', () async {
      // TODO
    });

    //Future paymentsControllerResolve(String id, ResolvePaymentDto resolvePaymentDto) async
    test('test paymentsControllerResolve', () async {
      // TODO
    });

    //Future paymentsControllerStageBudget(String stageId) async
    test('test paymentsControllerStageBudget', () async {
      // TODO
    });

  });
}
