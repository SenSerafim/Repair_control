import 'package:dio/dio.dart';

import '../../stages/data/stages_repository.dart';
import '../../stages/domain/pause_reason.dart';
import '../../stages/domain/stage.dart';
import '../../stages/domain/template.dart';
import 'demo_data.dart';

/// Mock-репозиторий этапов для демо-тура. См. `DemoProjectsRepository`.
class DemoStagesRepository extends StagesRepository {
  DemoStagesRepository() : super(Dio());

  @override
  Future<List<Stage>> list(String projectId) async => DemoData.stages;

  @override
  Future<Stage> get({required String projectId, required String stageId}) async =>
      DemoData.stageById(stageId);

  @override
  Future<Stage> create({
    required String projectId,
    required String title,
    int? orderIndex,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
    List<String>? foremanIds,
  }) async =>
      DemoData.stages.first;

  @override
  Future<Stage> update({
    required String projectId,
    required String stageId,
    String? title,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
    List<String>? foremanIds,
  }) async =>
      DemoData.stageById(stageId);

  @override
  Future<void> reorder({
    required String projectId,
    required List<({String id, int orderIndex})> items,
  }) async {}

  @override
  Future<Stage> start({
    required String projectId,
    required String stageId,
  }) async =>
      DemoData.stageById(stageId);

  @override
  Future<Stage> pause({
    required String projectId,
    required String stageId,
    required PauseReason reason,
    String? comment,
  }) async =>
      DemoData.stageById(stageId);

  @override
  Future<Stage> resume({
    required String projectId,
    required String stageId,
  }) async =>
      DemoData.stageById(stageId);

  @override
  Future<Stage> sendToReview({
    required String projectId,
    required String stageId,
  }) async =>
      DemoData.stageById(stageId);

  @override
  Future<List<StageTemplate>> listPlatformTemplates() async => const [];

  @override
  Future<List<StageTemplate>> listUserTemplates() async => const [];

  @override
  Future<StageTemplate> getTemplate(String id) async {
    throw UnsupportedError('Templates are disabled in demo tour');
  }

  @override
  Future<Stage> applyTemplate({
    required String templateId,
    required String projectId,
    DateTime? plannedStart,
    DateTime? plannedEnd,
  }) async =>
      DemoData.stages.first;

  @override
  Future<StageTemplate> saveAsTemplate({
    required String stageId,
    required String title,
  }) async {
    throw UnsupportedError('Templates are disabled in demo tour');
  }
}
