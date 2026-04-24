import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/storage/offline_queue.dart';
import '../../auth/domain/auth_failure.dart';
import '../../projects/application/project_controller.dart';
import '../../stages/application/stages_controller.dart';
import '../data/steps_repository.dart';
import '../domain/step.dart';

/// Шаги одного этапа + мутации. После каждого мутирующего действия
/// invalidate stagesController и projectController — progressCache этапа
/// и светофор проекта пересчитываются бекендом.
final stepsControllerProvider = AsyncNotifierProvider.family<
    StepsController, List<Step>, StepsKey>(StepsController.new);

@immutable
class StepsKey {
  const StepsKey({required this.projectId, required this.stageId});
  final String projectId;
  final String stageId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepsKey &&
          other.projectId == projectId &&
          other.stageId == stageId;

  @override
  int get hashCode => Object.hash(projectId, stageId);
}

class StepsController extends FamilyAsyncNotifier<List<Step>, StepsKey> {
  @override
  Future<List<Step>> build(StepsKey key) async {
    final list = await ref
        .read(stepsRepositoryProvider)
        .listForStage(key.stageId);
    return [...list]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  StepsRepository get _repo => ref.read(stepsRepositoryProvider);

  void _invalidateStageAndProject() {
    ref
      ..invalidate(stagesControllerProvider(arg.projectId))
      ..invalidate(projectControllerProvider(arg.projectId));
  }

  void _replace(Step s) {
    final current = state.value ?? const <Step>[];
    final exists = current.any((x) => x.id == s.id);
    final next = exists
        ? current.map((x) => x.id == s.id ? s : x).toList()
        : [...current, s]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    state = AsyncData(next);
  }

  Future<AuthFailure?> createRegular({
    required String title,
    String? description,
    List<String>? assigneeIds,
  }) =>
      _doCreate(
        title: title,
        type: StepType.regular,
        description: description,
        assigneeIds: assigneeIds,
      );

  Future<AuthFailure?> createExtra({
    required String title,
    required int priceKopecks,
    String? description,
  }) =>
      _doCreate(
        title: title,
        type: StepType.extra,
        price: priceKopecks,
        description: description,
      );

  Future<AuthFailure?> _doCreate({
    required String title,
    required StepType type,
    int? price,
    String? description,
    List<String>? assigneeIds,
  }) async {
    try {
      final s = await _repo.createStep(
        stageId: arg.stageId,
        title: title,
        type: type,
        price: price,
        description: description,
        assigneeIds: assigneeIds,
      );
      _replace(s);
      _invalidateStageAndProject();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> saveUpdate({
    required String stepId,
    String? title,
    int? price,
    String? description,
    List<String>? assigneeIds,
  }) async {
    try {
      final s = await _repo.updateStep(
        stepId: stepId,
        title: title,
        price: price,
        description: description,
        assigneeIds: assigneeIds,
      );
      _replace(s);
      _invalidateStageAndProject();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> delete(String stepId) async {
    final prev = state.value ?? const <Step>[];
    state = AsyncData(prev.where((s) => s.id != stepId).toList());
    try {
      await _repo.deleteStep(stepId);
      _invalidateStageAndProject();
      return null;
    } on StepsException catch (e) {
      state = AsyncData(prev);
      return e.failure;
    }
  }

  Future<AuthFailure?> complete(String stepId) async {
    if (_isOffline()) {
      await _enqueueStepToggle(stepId, complete: true);
      _markLocally(stepId, completed: true);
      return null;
    }
    try {
      final s = await _repo.completeStep(stepId);
      _replace(s);
      _invalidateStageAndProject();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> uncomplete(String stepId) async {
    if (_isOffline()) {
      await _enqueueStepToggle(stepId, complete: false);
      _markLocally(stepId, completed: false);
      return null;
    }
    try {
      final s = await _repo.uncompleteStep(stepId);
      _replace(s);
      _invalidateStageAndProject();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  bool _isOffline() =>
      ref.read(connectivityProvider).value == ConnectivityStatus.offline;

  Future<void> _enqueueStepToggle(String stepId,
      {required bool complete}) async {
    await ref.read(offlineQueueProvider).enqueue(
      kind: OfflineActionKind.stepToggle,
      payload: {'stepId': stepId, 'complete': complete},
    );
  }

  void _markLocally(String stepId, {required bool completed}) {
    final current = state.value ?? const <Step>[];
    state = AsyncData([
      for (final s in current)
        if (s.id == stepId)
          s.copyWith(
            status: completed ? StepStatus.done : StepStatus.pending,
            doneAt: completed ? DateTime.now() : null,
          )
        else
          s,
    ]);
  }

  Future<AuthFailure?> reorder(List<String> newOrder) async {
    final current = state.value ?? const <Step>[];
    if (newOrder.length != current.length) return AuthFailure.validation;
    final byId = {for (final s in current) s.id: s};
    final reordered = <Step>[
      for (var i = 0; i < newOrder.length; i++)
        (byId[newOrder[i]] ?? (throw StateError('unknown step')))
            .copyWith(orderIndex: i),
    ];
    state = AsyncData(reordered);
    try {
      await _repo.reorderSteps(
        stageId: arg.stageId,
        items: [
          for (var i = 0; i < newOrder.length; i++)
            (id: newOrder[i], orderIndex: i),
        ],
      );
      _invalidateStageAndProject();
      return null;
    } on StepsException catch (e) {
      state = AsyncData(current);
      return e.failure;
    }
  }
}
