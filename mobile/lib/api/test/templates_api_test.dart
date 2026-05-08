import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for TemplatesApi
void main() {
  final instance = RepairControlApi().getTemplatesApi();

  group(TemplatesApi, () {
    //Future templatesControllerApply(String templateId, CreateStageFromTemplateDto createStageFromTemplateDto) async
    test('test templatesControllerApply', () async {
      // TODO
    });

    //Future templatesControllerGet(String id) async
    test('test templatesControllerGet', () async {
      // TODO
    });

    //Future templatesControllerPlatform() async
    test('test templatesControllerPlatform', () async {
      // TODO
    });

    //Future templatesControllerSaveFromStage(String stageId, SaveAsTemplateDto saveAsTemplateDto) async
    test('test templatesControllerSaveFromStage', () async {
      // TODO
    });

    //Future templatesControllerUser() async
    test('test templatesControllerUser', () async {
      // TODO
    });

  });
}
