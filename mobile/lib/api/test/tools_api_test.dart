import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for ToolsApi
void main() {
  final instance = RepairControlApi().getToolsApi();

  group(ToolsApi, () {
    //Future toolsControllerConfirmReceipt(String id) async
    test('test toolsControllerConfirmReceipt', () async {
      // TODO
    });

    //Future toolsControllerConfirmReturn(String id) async
    test('test toolsControllerConfirmReturn', () async {
      // TODO
    });

    //Future toolsControllerCreate(CreateToolDto createToolDto) async
    test('test toolsControllerCreate', () async {
      // TODO
    });

    //Future toolsControllerGet(String id) async
    test('test toolsControllerGet', () async {
      // TODO
    });

    //Future toolsControllerIssue(String projectId, IssueToolDto issueToolDto) async
    test('test toolsControllerIssue', () async {
      // TODO
    });

    //Future toolsControllerList(String projectId) async
    test('test toolsControllerList', () async {
      // TODO
    });

    //Future toolsControllerListMine() async
    test('test toolsControllerListMine', () async {
      // TODO
    });

    //Future toolsControllerRequestReturn(String id, ReturnToolDto returnToolDto) async
    test('test toolsControllerRequestReturn', () async {
      // TODO
    });

    //Future toolsControllerUpdate(String id, UpdateToolDto updateToolDto) async
    test('test toolsControllerUpdate', () async {
      // TODO
    });

  });
}
