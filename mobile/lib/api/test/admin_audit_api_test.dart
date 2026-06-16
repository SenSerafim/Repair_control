import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for AdminAuditApi
void main() {
  final instance = RepairControlApi().getAdminAuditApi();

  group(AdminAuditApi, () {
    //Future adminAuditControllerList(String actorId, String action, String from, String to, String limit) async
    test('test adminAuditControllerList', () async {
      // TODO
    });

    //Future adminAuditControllerStats() async
    test('test adminAuditControllerStats', () async {
      // TODO
    });
  });
}
