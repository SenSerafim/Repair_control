import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for StagesApi
void main() {
  final instance = RepairControlApi().getStagesApi();

  group(StagesApi, () {
    //Future stagesControllerCreate(String projectId, CreateStageDto createStageDto) async
    test('test stagesControllerCreate', () async {
      // TODO
    });

    //Future stagesControllerGet(String stageId) async
    test('test stagesControllerGet', () async {
      // TODO
    });

    //Future stagesControllerList(String projectId) async
    test('test stagesControllerList', () async {
      // TODO
    });

    //Future stagesControllerPause(String stageId, PauseStageDto pauseStageDto) async
    test('test stagesControllerPause', () async {
      // TODO
    });

    //Future stagesControllerReorder(String projectId, ReorderStagesDto reorderStagesDto) async
    test('test stagesControllerReorder', () async {
      // TODO
    });

    //Future stagesControllerResume(String stageId) async
    test('test stagesControllerResume', () async {
      // TODO
    });

    //Future stagesControllerSendToReview(String stageId) async
    test('test stagesControllerSendToReview', () async {
      // TODO
    });

    //Future stagesControllerStart(String stageId) async
    test('test stagesControllerStart', () async {
      // TODO
    });

    //Future stagesControllerUpdate(String stageId, UpdateStageDto updateStageDto) async
    test('test stagesControllerUpdate', () async {
      // TODO
    });

  });
}
