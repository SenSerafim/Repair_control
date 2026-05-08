import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for StepsApi
void main() {
  final instance = RepairControlApi().getStepsApi();

  group(StepsApi, () {
    //Future stepsControllerAddSubstep(String stepId, AddSubstepDto addSubstepDto) async
    test('test stepsControllerAddSubstep', () async {
      // TODO
    });

    //Future stepsControllerCompleteStep(String stepId) async
    test('test stepsControllerCompleteStep', () async {
      // TODO
    });

    //Future stepsControllerCompleteSubstep(String substepId) async
    test('test stepsControllerCompleteSubstep', () async {
      // TODO
    });

    //Future stepsControllerConfirmPhoto(String stepId, ConfirmPhotoDto confirmPhotoDto) async
    test('test stepsControllerConfirmPhoto', () async {
      // TODO
    });

    //Future stepsControllerCreateStep(String stageId, CreateStepDto createStepDto) async
    test('test stepsControllerCreateStep', () async {
      // TODO
    });

    //Future stepsControllerDeletePhoto(String photoId) async
    test('test stepsControllerDeletePhoto', () async {
      // TODO
    });

    //Future stepsControllerDeleteStep(String stepId) async
    test('test stepsControllerDeleteStep', () async {
      // TODO
    });

    //Future stepsControllerDeleteSubstep(String substepId) async
    test('test stepsControllerDeleteSubstep', () async {
      // TODO
    });

    //Future stepsControllerGetStep(String stepId) async
    test('test stepsControllerGetStep', () async {
      // TODO
    });

    //Future stepsControllerListPhotos(String stepId) async
    test('test stepsControllerListPhotos', () async {
      // TODO
    });

    //Future stepsControllerListSteps(String stageId) async
    test('test stepsControllerListSteps', () async {
      // TODO
    });

    //Future stepsControllerPresignPhoto(String stepId, PresignPhotoDto presignPhotoDto) async
    test('test stepsControllerPresignPhoto', () async {
      // TODO
    });

    //Future stepsControllerReorderSteps(String stageId, ReorderStepsDto reorderStepsDto) async
    test('test stepsControllerReorderSteps', () async {
      // TODO
    });

    //Future stepsControllerUncompleteStep(String stepId) async
    test('test stepsControllerUncompleteStep', () async {
      // TODO
    });

    //Future stepsControllerUncompleteSubstep(String substepId) async
    test('test stepsControllerUncompleteSubstep', () async {
      // TODO
    });

    //Future stepsControllerUpdateStep(String stepId, UpdateStepDto updateStepDto) async
    test('test stepsControllerUpdateStep', () async {
      // TODO
    });

    //Future stepsControllerUpdateSubstep(String substepId, UpdateSubstepDto updateSubstepDto) async
    test('test stepsControllerUpdateSubstep', () async {
      // TODO
    });

  });
}
