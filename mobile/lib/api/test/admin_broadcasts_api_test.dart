import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for AdminBroadcastsApi
void main() {
  final instance = RepairControlApi().getAdminBroadcastsApi();

  group(AdminBroadcastsApi, () {
    //Future broadcastsControllerGet(String id) async
    test('test broadcastsControllerGet', () async {
      // TODO
    });

    //Future broadcastsControllerList(String status) async
    test('test broadcastsControllerList', () async {
      // TODO
    });

    //Future broadcastsControllerPreview(PreviewDto previewDto) async
    test('test broadcastsControllerPreview', () async {
      // TODO
    });

    //Future broadcastsControllerSend(SendBroadcastDto sendBroadcastDto) async
    test('test broadcastsControllerSend', () async {
      // TODO
    });
  });
}
