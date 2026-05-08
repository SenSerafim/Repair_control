import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for NotificationsApi
void main() {
  final instance = RepairControlApi().getNotificationsApi();

  group(NotificationsApi, () {
    //Future notificationsControllerGetSettings() async
    test('test notificationsControllerGetSettings', () async {
      // TODO
    });

    //Future notificationsControllerLogs(String userId, String kind, String from, String to) async
    test('test notificationsControllerLogs', () async {
      // TODO
    });

    //Future notificationsControllerPatchSetting(PatchSettingDto patchSettingDto) async
    test('test notificationsControllerPatchSetting', () async {
      // TODO
    });

  });
}
