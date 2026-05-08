import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for ApprovalsApi
void main() {
  final instance = RepairControlApi().getApprovalsApi();

  group(ApprovalsApi, () {
    //Future approvalsControllerApprove(String id, DecideApprovalDto decideApprovalDto) async
    test('test approvalsControllerApprove', () async {
      // TODO
    });

    //Future approvalsControllerCancel(String id) async
    test('test approvalsControllerCancel', () async {
      // TODO
    });

    //Future approvalsControllerCreate(String projectId, CreateApprovalDto createApprovalDto) async
    test('test approvalsControllerCreate', () async {
      // TODO
    });

    //Future approvalsControllerGet(String id) async
    test('test approvalsControllerGet', () async {
      // TODO
    });

    //Future approvalsControllerList(String projectId, String scope, String status, String addresseeId) async
    test('test approvalsControllerList', () async {
      // TODO
    });

    //Future approvalsControllerReject(String id, DecideApprovalDto decideApprovalDto) async
    test('test approvalsControllerReject', () async {
      // TODO
    });

    //Future approvalsControllerResubmit(String id, ResubmitApprovalDto resubmitApprovalDto) async
    test('test approvalsControllerResubmit', () async {
      // TODO
    });

  });
}
