import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for FeedExportsApi
void main() {
  final instance = RepairControlApi().getFeedExportsApi();

  group(FeedExportsApi, () {
    //Future exportsControllerCreate(String projectId, String idempotencyKey, CreateExportDto createExportDto) async
    test('test exportsControllerCreate', () async {
      // TODO
    });

    //Future exportsControllerGet(String id) async
    test('test exportsControllerGet', () async {
      // TODO
    });

    //Future exportsControllerList(String projectId) async
    test('test exportsControllerList', () async {
      // TODO
    });

    //Future exportsControllerListFeed(String projectId, { String cursor, num limit, List<String> kind, String stageId, String dateFrom, String dateTo, String actorId }) async
    test('test exportsControllerListFeed', () async {
      // TODO
    });
  });
}
