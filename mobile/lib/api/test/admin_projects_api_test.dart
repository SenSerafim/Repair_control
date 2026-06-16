import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for AdminProjectsApi
void main() {
  final instance = RepairControlApi().getAdminProjectsApi();

  group(AdminProjectsApi, () {
    //Future adminProjectsControllerDetail(String id) async
    test('test adminProjectsControllerDetail', () async {
      // TODO
    });

    //Future adminProjectsControllerForceArchive(String id, ForceArchiveDto forceArchiveDto) async
    test('test adminProjectsControllerForceArchive', () async {
      // TODO
    });

    //Future adminProjectsControllerList({ String q, String status, String ownerId, num limit, num offset }) async
    test('test adminProjectsControllerList', () async {
      // TODO
    });
  });
}
