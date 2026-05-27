import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/storage/offline_queue.dart';
import '../../../shared/utils/image_compress.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/steps_repository.dart';
import '../domain/question.dart';
import '../domain/step.dart';
import '../domain/step_photo.dart';
import '../domain/substep.dart';
import 'steps_controller.dart';

class StepDetailData {
  const StepDetailData({
    required this.step,
    required this.substeps,
    required this.photos,
    required this.questions,
  });

  final Step step;
  final List<Substep> substeps;
  final List<StepPhoto> photos;
  final List<Question> questions;

  StepDetailData copyWith({
    Step? step,
    List<Substep>? substeps,
    List<StepPhoto>? photos,
    List<Question>? questions,
  }) => StepDetailData(
    step: step ?? this.step,
    substeps: substeps ?? this.substeps,
    photos: photos ?? this.photos,
    questions: questions ?? this.questions,
  );
}

@immutable
class StepDetailKey {
  const StepDetailKey({
    required this.projectId,
    required this.stageId,
    required this.stepId,
  });

  final String projectId;
  final String stageId;
  final String stepId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepDetailKey &&
          other.projectId == projectId &&
          other.stageId == stageId &&
          other.stepId == stepId;

  @override
  int get hashCode => Object.hash(projectId, stageId, stepId);
}

final stepDetailProvider =
    AsyncNotifierProvider.family<
      StepDetailController,
      StepDetailData,
      StepDetailKey
    >(StepDetailController.new);

/// Текущий черновик отчёта по шагу (ТЗ §4.1).
/// `_ReportSection` обновляет на каждом keystroke, `_ActionCtas` читает
/// при клике «Отметить выполненным» — чтобы текст и завершение шли одним
/// запросом, без отдельной кнопки «Сохранить отчёт».
class StepReportDraft {
  const StepReportDraft({this.whatDid, this.howDid});
  final String? whatDid;
  final String? howDid;
}

final stepReportDraftProvider =
    StateProvider.family<StepReportDraft, String>((_, __) => const StepReportDraft());

class StepDetailController
    extends FamilyAsyncNotifier<StepDetailData, StepDetailKey> {
  StreamSubscription<dynamic>? _substepSub;
  StreamSubscription<dynamic>? _stepSub;
  Timer? _refreshDebounce;

  @override
  Future<StepDetailData> build(StepDetailKey key) async {
    final dio = ref.read(dioProvider);
    final repo = ref.read(stepsRepositoryProvider);
    final socket = ref.read(socketServiceProvider);

    // Real-time: бекенд эмитит `substep:changed` при add/update/complete/
    // uncomplete/delete (см. SubstepsService → feed.emit). Слушаем только
    // события для текущего шага и тихо перезагружаем — без AsyncLoading,
    // чтобы UI у заказчика/мастера обновлялся без мигания.
    _substepSub = socket.on(SocketEvents.substepChanged).listen((payload) {
      if (payload is! Map) return;
      if (payload['projectId']?.toString() != key.projectId) return;
      if (payload['stepId']?.toString() != key.stepId) return;
      _scheduleSilentRefresh();
    });
    // step:changed по конкретному шагу — title/description/status/whatDid
    // могли измениться. Перегружаем детали.
    _stepSub = socket.on(SocketEvents.stepChanged).listen((payload) {
      if (payload is! Map) return;
      if (payload['projectId']?.toString() != key.projectId) return;
      if (payload['stepId']?.toString() != key.stepId) return;
      _scheduleSilentRefresh();
    });
    ref.onDispose(() {
      _substepSub?.cancel();
      _stepSub?.cancel();
      _refreshDebounce?.cancel();
    });

    // GET /steps/:id возвращает объект с вшитыми substeps/photos/questions
    // через Prisma include. Забираем всё за один запрос + отдельно
    // обогащаем photos (если нужны presigned urls).
    final resp = await dio.get<Map<String, dynamic>>(
      '/api/steps/${key.stepId}',
    );
    final json = resp.data!;
    final step = Step.parse(json);
    final substeps = (json['substeps'] as List<dynamic>? ?? const [])
        .map((e) => Substep.parse(e as Map<String, dynamic>))
        .toList();
    // photos и questions тоже могут приходить через include — но чтобы
    // получить presigned URL на превью, надёжнее запросить /photos.
    final photos = await repo.listPhotos(key.stepId);
    final questions = (json['questions'] as List<dynamic>? ?? const [])
        .map((e) => Question.parse(e as Map<String, dynamic>))
        .toList();

    return StepDetailData(
      step: step,
      substeps: substeps,
      photos: photos,
      questions: questions,
    );
  }

  /// Тихий refresh — не мигаем AsyncLoading. Дебаунс 300ms, чтобы серия
  /// событий (substep_added + substep_completed подряд) дала один запрос.
  void _scheduleSilentRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final data = await build(arg);
        state = AsyncData(data);
      } catch (_) {
        // тихий refresh: оставляем последнее успешное состояние
      }
    });
  }

  StepsRepository get _repo => ref.read(stepsRepositoryProvider);

  void _invalidateSiblings() {
    ref.invalidate(
      stepsControllerProvider(
        StepsKey(projectId: arg.projectId, stageId: arg.stageId),
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await build(arg));
    } on StepsException catch (e, st) {
      state = AsyncError(e, st);
    } on DioException catch (e, st) {
      final api = ApiError.fromDio(e);
      state = AsyncError(
        StepsException(AuthFailure.fromApiError(api), api),
        st,
      );
    }
  }

  // ─── Substeps ───

  Future<AuthFailure?> addSubstep(String text) async {
    try {
      final s = await _repo.addSubstep(stepId: arg.stepId, text: text);
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(cur.copyWith(substeps: [...cur.substeps, s]));
      }
      _invalidateSiblings();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> toggleSubstep(Substep sub) async {
    try {
      final updated = sub.isDone
          ? await _repo.uncompleteSubstep(sub.id)
          : await _repo.completeSubstep(sub.id);
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(
          cur.copyWith(
            substeps: cur.substeps
                .map((s) => s.id == updated.id ? updated : s)
                .toList(),
          ),
        );
      }
      _invalidateSiblings();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> deleteSubstep(String substepId) async {
    try {
      await _repo.deleteSubstep(substepId);
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(
          cur.copyWith(
            substeps: cur.substeps.where((s) => s.id != substepId).toList(),
          ),
        );
      }
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  // ─── Report (П2.8 / ТЗ §4.1) ───

  /// Обновление полей отчёта «что/как делал». Результат применяется in-place,
  /// чтобы экран не мигал AppLoadingState; sibling-провайдер шагов этапа
  /// получает invalidate — у списка обновится `hasReport`-флажок.
  Future<AuthFailure?> updateReport({
    String? whatDid,
    String? howDid,
  }) async {
    try {
      final updated = await _repo.updateStep(
        stepId: arg.stepId,
        whatDid: whatDid,
        howDid: howDid,
      );
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(cur.copyWith(step: updated));
      }
      _invalidateSiblings();
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  // ─── Photos ───

  Future<AuthFailure?> uploadPhoto({
    required Uint8List rawBytes,
    required String filename,
  }) async {
    final compressed = compressImage(rawBytes);
    if (compressed == null) return AuthFailure.validation;
    try {
      final presigned = await _repo.presignPhoto(
        stepId: arg.stepId,
        mime: compressed.mimeType,
        sizeBytes: compressed.sizeBytes,
        originalName: filename,
      );
      await _repo.uploadToStorage(
        presigned: presigned,
        bytes: compressed.bytes,
        mimeType: compressed.mimeType,
      );
      final photo = await _repo.confirmPhoto(
        stepId: arg.stepId,
        fileKey: presigned.fileKey,
        mimeType: compressed.mimeType,
        sizeBytes: compressed.sizeBytes,
      );
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(cur.copyWith(photos: [...cur.photos, photo]));
      }
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> deletePhoto(String photoId) async {
    try {
      await _repo.deletePhoto(photoId);
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(
          cur.copyWith(
            photos: cur.photos.where((p) => p.id != photoId).toList(),
          ),
        );
      }
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  // ─── Questions ───

  Future<AuthFailure?> askQuestion({
    required String text,
    required String addresseeId,
  }) async {
    try {
      final q = await _repo.askQuestion(
        stepId: arg.stepId,
        text: text,
        addresseeId: addresseeId,
      );
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(cur.copyWith(questions: [q, ...cur.questions]));
      }
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> answerQuestion({
    required String questionId,
    required String answer,
  }) async {
    final isOffline =
        ref.read(connectivityProvider).value == ConnectivityStatus.offline;
    if (isOffline) {
      await ref
          .read(offlineQueueProvider)
          .enqueue(
            kind: OfflineActionKind.questionAnswer,
            payload: {'questionId': questionId, 'answer': answer},
          );
      return null;
    }
    try {
      final q = await _repo.answerQuestion(
        questionId: questionId,
        answer: answer,
      );
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(
          cur.copyWith(
            questions: cur.questions.map((x) => x.id == q.id ? q : x).toList(),
          ),
        );
      }
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> closeQuestion(String questionId) async {
    try {
      final q = await _repo.closeQuestion(questionId);
      final cur = state.value;
      if (cur != null) {
        state = AsyncData(
          cur.copyWith(
            questions: cur.questions.map((x) => x.id == q.id ? q : x).toList(),
          ),
        );
      }
      return null;
    } on StepsException catch (e) {
      return e.failure;
    }
  }
}
