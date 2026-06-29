import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../data/approvals_repository.dart';
import '../domain/approval.dart';

class MyApprovalsBuckets {
  const MyApprovalsBuckets({required this.pending, required this.history});

  final List<MyApprovalItem> pending;
  final List<MyApprovalItem> history;

  bool get isEmpty => pending.isEmpty && history.isEmpty;
}

/// «Мои согласования» по всем проектам. Аналог проектного approvals-контроллера,
/// но без family-аргумента: каждый пользователь видит свой собственный срез
/// согласований (адресат либо заявитель).
final myApprovalsControllerProvider =
    AsyncNotifierProvider<MyApprovalsController, MyApprovalsBuckets>(
      MyApprovalsController.new,
    );

class MyApprovalsController extends AsyncNotifier<MyApprovalsBuckets> {
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
  Future<MyApprovalsBuckets> build() async {
    final socket = ref.read(socketServiceProvider);

    _approvalSub = socket.on(SocketEvents.approvalChanged).listen((_) {
      _scheduleRefresh();
    });
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

    final all = await ref.read(approvalsRepositoryProvider).listMine();
    return _bucketize(all);
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final all = await ref.read(approvalsRepositoryProvider).listMine();
        state = AsyncData(_bucketize(all));
      } catch (_) {
        // тихий рефреш — оставляем последнее успешное состояние
      }
    });
  }

  Future<void> refresh() async {
    _refreshDebounce?.cancel();
    try {
      final all = await ref.read(approvalsRepositoryProvider).listMine();
      state = AsyncData(_bucketize(all));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  MyApprovalsBuckets _bucketize(List<MyApprovalItem> all) {
    final pending = <MyApprovalItem>[];
    final history = <MyApprovalItem>[];
    for (final a in all) {
      if (a.approval.status == ApprovalStatus.pending) {
        pending.add(a);
      } else {
        history.add(a);
      }
    }
    pending.sort(
      (a, b) => b.approval.createdAt.compareTo(a.approval.createdAt),
    );
    history.sort(
      (a, b) => b.approval.updatedAt.compareTo(a.approval.updatedAt),
    );
    return MyApprovalsBuckets(pending: pending, history: history);
  }
}
