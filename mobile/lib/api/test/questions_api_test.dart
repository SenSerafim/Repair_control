import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for QuestionsApi
void main() {
  final instance = RepairControlApi().getQuestionsApi();

  group(QuestionsApi, () {
    //Future questionsControllerAnswer(String id, AnswerQuestionDto answerQuestionDto) async
    test('test questionsControllerAnswer', () async {
      // TODO
    });

    //Future questionsControllerAsk(String stepId, AskQuestionDto askQuestionDto) async
    test('test questionsControllerAsk', () async {
      // TODO
    });

    //Future questionsControllerClose(String id) async
    test('test questionsControllerClose', () async {
      // TODO
    });

    //Future questionsControllerListForStep(String stepId) async
    test('test questionsControllerListForStep', () async {
      // TODO
    });

    //Future questionsControllerListMine(String filter) async
    test('test questionsControllerListMine', () async {
      // TODO
    });

  });
}
