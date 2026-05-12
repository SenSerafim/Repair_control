import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../auth/domain/auth_failure.dart';
import '../../projects/application/project_controller.dart';
import '../../stages/application/stages_controller.dart';
import '../data/approvals_repository.dart';
import '../domain/approval.dart';

class ApprovalsBuckets {
  const ApprovalsBuckets({required this.pending, required this.history});

  final List<Approval> pending;
  final List<Approval> history;

  ApprovalsBuckets copyWith({
    List<Approval>? pending,
    List<Approval>? history,
  }) => ApprovalsBuckets(
    pending: pending ?? this.pending,
    history: history ?? this.history,
  );

  bool get isEmpty => pending.isEmpty && history.isEmpty;
}

final approvalsControllerProvider =
    AsyncNotifierProvider.family<ApprovalsController, ApprovalsBuckets, String>(
      ApprovalsController.new,
    );

class ApprovalsController
    extends FamilyAsyncNotifier<ApprovalsBuckets, String> {
  // Список kind'ов notification:new, после которых approvals-список меняется.
  // Fallback на случай если approval:changed по какой-то причине потерян
  // (старый клиент / гонка) — push всё равно подхватит. Покрывает три плоскости:
  // (1) approval-domain events; (2) mirror-approval scopes; (3) escalation.
  static const _approvalRelatedNotificationKinds = <String>{
    'approval_requested',
    'approval_approved',
    'approval_rejected',
    'selfpurchase_created',
    'material_request_created',
    'stage_create_requested',
  };

  Timer? _refreshDebounce;
  StreamSubscription<dynamic>? _approvalSub;
  StreamSubscription<dynamic>? _notificationSub;

  @override
  Future<ApprovalsBuckets> build(String projectId) async {
    final socket = ref.read(socketServiceProvider);

    // Прямой сигнал от бэкенда: feed.emit с approval-kind → approval:changed.
    // Фильтруем по projectId, чтобы инвалидировать только нужный family.
    _approvalSub = socket.on(SocketEvents.approvalChanged).listen((payload) {
      if (payload is! Map) return;
      final pid = payload['projectId']?.toString();
      if (pid != null && pid != projectId) return;
      _scheduleRefresh();
    });

    // Fallback по notification:new — для старых backend-сборок без
    // approval:changed.
    _notificationSub = socket.on(SocketEvents.notificationNew).listen((
      payload,
    ) {
      if (payload is! Map) return;
      final kind = payload['kind']?.toString();
      if (kind == null || !_approvalRelatedNotificationKinds.contains(kind)) {
        return;
      }
      _scheduleRefresh();
    });

    ref.onDispose(() {
      _refreshDebounce?.cancel();
      _approvalSub?.cancel();
      _notificationSub?.cancel();
    });

    final all = await ref
        .read(approvalsRepositoryProvider)
        .list(projectId: projectId);
    return _bucketize(all);
  }

  /// Тихий refresh без перевода state в loading — не мигаем UI при
  /// background-обновлении. Дебаунс 500ms на случай шторма событий
  /// (chain create→escalate→notify приходит несколькими событиями подряд).
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final all = await ref
            .read(approvalsRepositoryProvider)
            .list(projectId: arg);
        state = AsyncData(_bucketize(all));
      } on ApprovalsException {
        // Тихий refresh: оставляем последнее успешное состояние.
      }
    });
  }

  /// Принудительный refresh — для pull-to-refresh и resume из background.
  Future<void> refresh() async {
    _refreshDebounce?.cancel();
    try {
      final all = await ref
          .read(approvalsRepositoryProvider)
          .list(projectId: arg);
      state = AsyncData(_bucketize(all));
    } on ApprovalsException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  ApprovalsBuckets _bucketize(List<Approval> all) {
    final pending = <Approval>[];
    final history = <Approval>[];
    for (final a in all) {
      if (a.status == ApprovalStatus.pending) {
        pending.add(a);
      } else {
        history.add(a);
      }
    }
    pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    history.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return ApprovalsBuckets(pending: pending, history: history);
  }

  void _replace(Approval a) {
    final current = state.value;
    if (current == null) return;
    final combined = [
      ...current.pending.where((x) => x.id != a.id),
      ...current.history.where((x) => x.id != a.id),
      a,
    ];
    state = AsyncData(_bucketize(combined));
  }

  void _invalidateStageAndProject(String? stageId) {
    // После решения по approval меняются: project.semaphore,
    // stage.planApproved / status / workBudget.
    ref
      ..invalidate(projectControllerProvider(arg))
      ..invalidate(stagesControllerProvider(arg));
  }

  Future<AuthFailure?> approve({
    required Approval approval,
    String? comment,
  }) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .approve(id: approval.id, comment: comment);
      _replace(updated);
      _invalidateStageAndProject(approval.stageId);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> reject({
    required Approval approval,
    required String comment,
  }) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .reject(id: approval.id, comment: comment);
      _replace(updated);
      _invalidateStageAndProject(approval.stageId);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> resubmit({
    required Approval approval,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .resubmit(id: approval.id, payload: payload);
      _replace(updated);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> cancel(Approval approval) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .cancel(approval.id);
      _replace(updated);
      _invalidateStageAndProject(approval.stageId);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }
}

/// Детальный провайдер отдельного согласования — используется экраном
/// детали для свежего state с attachments.
final approvalDetailProvider =
    AsyncNotifierProvider.family<ApprovalDetailController, Approval, String>(
      ApprovalDetailController.new,
    );

class ApprovalDetailController extends FamilyAsyncNotifier<Approval, String> {
  Timer? _refreshDebounce;
  StreamSubscription<dynamic>? _approvalSub;

  @override
  Future<Approval> build(String approvalId) async {
    final socket = ref.read(socketServiceProvider);
    // Если по этой конкретной approval-записи приходит обновление —
    // перезагружаем детали. Фильтр по approvalId защищает от лишних запросов.
    _approvalSub = socket.on(SocketEvents.approvalChanged).listen((payload) {
      if (payload is! Map) return;
      final aid = payload['approvalId']?.toString();
      if (aid != null && aid != approvalId) return;
      _scheduleRefresh(approvalId);
    });
    ref.onDispose(() {
      _refreshDebounce?.cancel();
      _approvalSub?.cancel();
    });
    return ref.read(approvalsRepositoryProvider).get(approvalId);
  }

  void _scheduleRefresh(String approvalId) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final fresh = await ref
            .read(approvalsRepositoryProvider)
            .get(approvalId);
        state = AsyncData(fresh);
      } on ApprovalsException {
        // Тихий refresh.
      }
    });
  }
}
