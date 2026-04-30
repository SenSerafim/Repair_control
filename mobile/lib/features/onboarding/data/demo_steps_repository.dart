import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../steps/data/steps_repository.dart';
import '../../steps/domain/question.dart';
import '../../steps/domain/step.dart';
import '../../steps/domain/step_photo.dart';
import '../../steps/domain/substep.dart';
import 'demo_data.dart';

/// Mock-репозиторий шагов для демо-тура.
class DemoStepsRepository extends StepsRepository {
  DemoStepsRepository() : super(Dio());

  @override
  Future<List<Step>> listForStage(String stageId) async =>
      DemoData.stepsForStage(stageId);

  @override
  Future<Step> getStep(String stepId) async => DemoData.stepById(stepId);

  @override
  Future<Step> createStep({
    required String stageId,
    required String title,
    StepType type = StepType.regular,
    int? price,
    String? description,
    List<String>? assigneeIds,
  }) async =>
      DemoData.steps.first;

  @override
  Future<Step> updateStep({
    required String stepId,
    String? title,
    int? price,
    String? description,
    List<String>? assigneeIds,
  }) async =>
      DemoData.stepById(stepId);

  @override
  Future<void> deleteStep(String stepId) async {}

  @override
  Future<void> reorderSteps({
    required String stageId,
    required List<({String id, int orderIndex})> items,
  }) async {}

  @override
  Future<Step> completeStep(String stepId) async => DemoData.stepById(stepId);

  @override
  Future<Step> uncompleteStep(String stepId) async => DemoData.stepById(stepId);

  @override
  Future<Substep> addSubstep({
    required String stepId,
    required String text,
  }) async =>
      DemoData.substepsForStep.first;

  @override
  Future<Substep> updateSubstep({
    required String substepId,
    required String text,
  }) async =>
      DemoData.substepsForStep.firstWhere((s) => s.id == substepId);

  @override
  Future<Substep> completeSubstep(String substepId) async =>
      DemoData.substepsForStep.firstWhere((s) => s.id == substepId);

  @override
  Future<Substep> uncompleteSubstep(String substepId) async =>
      DemoData.substepsForStep.firstWhere((s) => s.id == substepId);

  @override
  Future<void> deleteSubstep(String substepId) async {}

  @override
  Future<List<StepPhoto>> listPhotos(String stepId) async {
    if (stepId == DemoData.stepElectricsSocketsId) {
      return DemoData.photosForStep;
    }
    return const [];
  }

  @override
  Future<PresignedPhoto> presignPhoto({
    required String stepId,
    required String mime,
    required int sizeBytes,
    String? originalName,
  }) async {
    throw UnsupportedError('Photo upload is disabled in demo tour');
  }

  @override
  Future<void> uploadToStorage({
    required PresignedPhoto presigned,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    throw UnsupportedError('Photo upload is disabled in demo tour');
  }

  @override
  Future<StepPhoto> confirmPhoto({
    required String stepId,
    required String fileKey,
    required String mimeType,
    required int sizeBytes,
  }) async {
    throw UnsupportedError('Photo upload is disabled in demo tour');
  }

  @override
  Future<void> deletePhoto(String photoId) async {}

  @override
  Future<List<Question>> listQuestions(String stepId) async {
    if (stepId == DemoData.stepElectricsSocketsId) {
      return DemoData.questionsForStep;
    }
    return const [];
  }

  @override
  Future<Question> askQuestion({
    required String stepId,
    required String text,
    required String addresseeId,
  }) async =>
      DemoData.questionsForStep.first;

  @override
  Future<Question> answerQuestion({
    required String questionId,
    required String answer,
  }) async =>
      DemoData.questionsForStep.first;

  @override
  Future<Question> closeQuestion(String questionId) async =>
      DemoData.questionsForStep.first;
}
