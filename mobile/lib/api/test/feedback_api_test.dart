import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for FeedbackApi
void main() {
  final instance = RepairControlApi().getFeedbackApi();

  group(FeedbackApi, () {
    //Future feedbackControllerCreate(CreateFeedbackDto createFeedbackDto) async
    test('test feedbackControllerCreate', () async {
      // TODO
    });

    //Future feedbackControllerGet(String id) async
    test('test feedbackControllerGet', () async {
      // TODO
    });

    //Future feedbackControllerList(String status, String cursor) async
    test('test feedbackControllerList', () async {
      // TODO
    });

    //Future feedbackControllerPatch(String id, PatchFeedbackDto patchFeedbackDto) async
    test('test feedbackControllerPatch', () async {
      // TODO
    });

  });
}
