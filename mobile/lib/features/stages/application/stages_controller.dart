import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../auth/domain/auth_failure.dart';
import '../../projects/application/project_controller.dart';
import '../data/stages_repository.dart';
import '../domain/pause_reason.dart';
import '../domain/stage.dart';

/// Список этапов одного проекта + мутации. Оптимистичный UI с откатом.
/// После каждой мутации invalidate projectController, чтобы обновить
/// project.semaphore и progressCache на консоли.
final stagesControllerProvider =
    AsyncNotifierProvider.family<StagesController, List<Stage>, String>(
      StagesController.new,
    );

class StagesController extends FamilyAsyncNotifier<List<Stage>, String> {
  StreamSubscription<dynamic>? _stageSub;
  StreamSubscription<dynamic>? _stepSub;
  Timer? _refreshDebounce;

  @override
  Future<List<Stage>> build(String projectId) async {
    // Real-time: бекенд эмитит `stage:changed` для всех STAGE_FEED_KINDS
    // (stage_created/started/paused/resumed/sent_to_review/accepted/...).
    // Перезагружаем список этапов проекта, чтобы у других ролей сразу
    // отобразились новые статусы, новые этапы, переназначения бригадира.
    // `step:changed` влияет на `progressCache` этапа → тоже триггерит refresh.
    final socket = ref.read(socketServiceProvider);
    _stageSub = socket.on(SocketEvents.stageChanged).listen((payload) {
      if (payload is! Map) return;
      if (payload['projectId']?.toString() != projectId) return;
      _scheduleRefresh();
    });
    _stepSub = socket.on(SocketEvents.stepChanged).listen((payload) {
      if (payload is! Map) return;
      if (payload['projectId']?.toString() != projectId) return;
      // step_completed / step_uncompleted / step_created / step_deleted —
      // влияют на progressCache этапа. recalcStage на бэке отдаст новые
      // числа при следующем GET /stages.
      _scheduleRefresh();
    });
    ref.onDispose(() {
      _stageSub?.cancel();
      _stepSub?.cancel();
      _refreshDebounce?.cancel();
    });

    final raw = await ref.read(stagesRepositoryProvider).list(projectId);
    return _sorted(raw);
  }

  /// Дебаунс 400ms — несколько событий подряд (например, step_completed +
  /// progress_recalculated) не приводят к серии повторных GET'ов.
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final raw = await _repo.list(arg);
        state = AsyncData(_sorted(raw));
      } on StagesException {
        // тихий refresh: оставляем последнее успешное состояние
      }
    });
  }

  List<Stage> _sorted(List<Stage> list) =>
      [...list]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  StagesRepository get _repo => ref.read(stagesRepositoryProvider);

  void _invalidateProject() {
    ref.invalidate(projectControllerProvider(arg));
  }

  Future<AuthFailure?> create({
    required String title,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
    List<String>? foremanIds,
  }) async {
    try {
      final s = await _repo.create(
        projectId: arg,
        title: title,
        plannedStart: plannedStart,
        plannedEnd: plannedEnd,
        workBudget: workBudget,
        materialsBudget: materialsBudget,
        foremanIds: foremanIds,
      );
      state = AsyncData(_sorted([...(state.value ?? []), s]));
      _invalidateProject();
      return null;
    } on StagesException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> saveUpdate({
    required String stageId,
    String? title,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
    List<String>? foremanIds,
  }) async {
    try {
      final s = await _repo.update(
        projectId: arg,
        stageId: stageId,
        title: title,
        plannedStart: plannedStart,
        plannedEnd: plannedEnd,
        workBudget: workBudget,
        materialsBudget: materialsBudget,
        foremanIds: foremanIds,
      );
      _replace(s);
      _invalidateProject();
      return null;
    } on StagesException catch (e) {
      return e.failure;
    }
  }

  /// Оптимистичный reorder. Локальное применение индексов — сразу,
  /// откат при ошибке.
  Future<AuthFailure?> reorder(List<String> newOrder) async {
    final current = state.value ?? [];
    if (newOrder.length != current.length) {
      return AuthFailure.validation;
    }
    final byId = {for (final s in current) s.id: s};
    final reordered = <Stage>[];
    for (var i = 0; i < newOrder.length; i++) {
      final id = newOrder[i];
      final s = byId[id];
      if (s == null) return AuthFailure.validation;
      reordered.add(s.copyWith(orderIndex: i));
    }
    state = AsyncData(reordered);
    try {
      await _repo.reorder(
        projectId: arg,
        items: [
          for (var i = 0; i < newOrder.length; i++)
            (id: newOrder[i], orderIndex: i),
        ],
      );
      return null;
    } on StagesException catch (e) {
      state = AsyncData(current);
      return e.failure;
    }
  }

  Future<AuthFailure?> start(String stageId) =>
      _transition(() => _repo.start(projectId: arg, stageId: stageId));

  Future<AuthFailure?> pause({
    required String stageId,
    required PauseReason reason,
    String? comment,
  }) => _transition(
    () => _repo.pause(
      projectId: arg,
      stageId: stageId,
      reason: reason,
      comment: comment,
    ),
  );

  Future<AuthFailure?> resume(String stageId) =>
      _transition(() => _repo.resume(projectId: arg, stageId: stageId));

  Future<AuthFailure?> sendToReview(String stageId) =>
      _transition(() => _repo.sendToReview(projectId: arg, stageId: stageId));

  Future<AuthFailure?> _transition(Future<Stage> Function() action) async {
    try {
      final updated = await action();
      _replace(updated);
      _invalidateProject();
      return null;
    } on StagesException catch (e) {
      return e.failure;
    }
  }

  /// Обновляет стадию после успешной мутации (или добавляет, если новой).
  void _replace(Stage s) {
    final current = state.value ?? [];
    final exists = current.any((x) => x.id == s.id);
    state = AsyncData(
      _sorted(
        exists
            ? current.map((x) => x.id == s.id ? s : x).toList()
            : [...current, s],
      ),
    );
  }
}
