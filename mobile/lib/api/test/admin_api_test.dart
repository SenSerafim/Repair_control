import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for AdminApi
void main() {
  final instance = RepairControlApi().getAdminApi();

  group(AdminApi, () {
    //Future adminControllerCreateItem(CreateFaqItemDto createFaqItemDto) async
    test('test adminControllerCreateItem', () async {
      // TODO
    });

    //Future adminControllerCreateSection(CreateFaqSectionDto createFaqSectionDto) async
    test('test adminControllerCreateSection', () async {
      // TODO
    });

    //Future adminControllerDeleteItem(String id) async
    test('test adminControllerDeleteItem', () async {
      // TODO
    });

    //Future adminControllerListFaq() async
    test('test adminControllerListFaq', () async {
      // TODO
    });

    //Future adminControllerListSettings() async
    test('test adminControllerListSettings', () async {
      // TODO
    });

    //Future adminControllerMe() async
    test('test adminControllerMe', () async {
      // TODO
    });

    //Future adminControllerPublicFaq() async
    test('test adminControllerPublicFaq', () async {
      // TODO
    });

    //Future adminControllerPutSetting(PutSettingDto putSettingDto) async
    test('test adminControllerPutSetting', () async {
      // TODO
    });

    //Future adminControllerUpdateItem(String id, UpdateFaqItemDto updateFaqItemDto) async
    test('test adminControllerUpdateItem', () async {
      // TODO
    });

  });
}
