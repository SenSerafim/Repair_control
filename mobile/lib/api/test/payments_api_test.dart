import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for PaymentsApi
void main() {
  final instance = RepairControlApi().getPaymentsApi();

  group(PaymentsApi, () {
    //Future paymentsControllerCreateAdvance(String projectId, String idempotencyKey, CreateAdvanceDto createAdvanceDto) async
    test('test paymentsControllerCreateAdvance', () async {
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

    //Future paymentsControllerList(String projectId, String kind, String userId) async
    test('test paymentsControllerList', () async {
      // TODO
    });

    //Future paymentsControllerProjectBudget(String projectId) async
    test('test paymentsControllerProjectBudget', () async {
      // TODO
    });

    //Future paymentsControllerStageBudget(String stageId) async
    test('test paymentsControllerStageBudget', () async {
      // TODO
    });

  });
}
