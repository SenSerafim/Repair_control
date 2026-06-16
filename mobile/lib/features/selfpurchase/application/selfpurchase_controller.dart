import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../auth/domain/auth_failure.dart';
import '../../finance/application/budget_controller.dart';
import '../data/selfpurchase_repository.dart';
import '../domain/self_purchase.dart';

final selfpurchasesControllerProvider =
    AsyncNotifierProvider.family<
      SelfpurchasesController,
      List<SelfPurchase>,
      String
    >(SelfpurchasesController.new);

class SelfpurchasesController
    extends FamilyAsyncNotifier<List<SelfPurchase>, String> {
  // notification:new fallback на случай если approval:changed потерян
  // (старый backend / гонка). Перекрывает основные lifecycle-события самозакупа.
  static const _selfPurchaseNotificationKinds = <String>{
    'selfpurchase_created',
    'selfpurchase_forwarded',
    'selfpurchase_approved',
    'selfpurchase_rejected',
  };

  StreamSubscription<dynamic>? _approvalSub;
  StreamSubscription<dynamic>? _notificationSub;
  Timer? _refreshDebounce;

  @override
  Future<List<SelfPurchase>> build(String projectId) async {
    // Real-time: бекенд эмитит approval:changed для всех selfpurchase_* feed-kinds
    // (см. chats.gateway.ts → APPROVAL_FEED_KINDS). Адресат и инициатор получают
    // событие в свою user:{id} комнату → мобайл тихо перетягивает список без
    // pull-to-refresh, чтобы новый pending сразу появился с кнопкой принять/отклонить.
    final socket = ref.read(socketServiceProvider);
    _approvalSub = socket.on(SocketEvents.approvalChanged).listen((payload) {
      if (payload is! Map) return;
      if (payload['projectId']?.toString() != projectId) return;
      // Прочие scope (plan / extra_work / stage_accept / material_purchase)
      // нам не интересны — отсеиваем, чтобы не дёргать GET.
      final scope = payload['scope']?.toString();
      if (scope != null && scope != 'self_purchase') return;
      _scheduleRefresh();
    });
    _notificationSub = socket.on(SocketEvents.notificationNew).listen((
      payload,
    ) {
      if (payload is! Map) return;
      final kind = payload['kind']?.toString();
      if (kind == null || !_selfPurchaseNotificationKinds.contains(kind)) {
        return;
      }
      _scheduleRefresh();
    });
    ref.onDispose(() {
      _approvalSub?.cancel();
      _notificationSub?.cancel();
      _refreshDebounce?.cancel();
    });

    final raw = await _repo.list(projectId: projectId);
    return [...raw]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  SelfPurchaseRepository get _repo => ref.read(selfPurchaseRepositoryProvider);

  /// Тихий refresh без перевода state в loading — дебаунс 400ms на случай
  /// шторма событий (create → forward → approve приходят серией).
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final raw = await _repo.list(projectId: arg);
        final sorted = [...raw]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = AsyncData(sorted);
        // Если в свежем списке появился approved foreman→customer самозакуп,
        // которого раньше не было approved-ом — это списание в бюджет, обновим.
        if (sorted.any(
          (sp) =>
              sp.status == SelfPurchaseStatus.approved &&
              sp.byRole == SelfPurchaseBy.foreman,
        )) {
          ref.invalidate(projectBudgetProvider(arg));
        }
      } on SelfPurchaseException {
        // Тихий refresh: оставляем последнее успешное состояние.
      }
    });
  }

  void _upsert(SelfPurchase r) {
    final cur = state.value ?? const <SelfPurchase>[];
    final exists = cur.any((x) => x.id == r.id);
    state = AsyncData(
      exists ? cur.map((x) => x.id == r.id ? r : x).toList() : [r, ...cur],
    );
  }

  Future<AuthFailure?> create({
    required int amount,
    String? stageId,
    String? comment,
    List<String>? photoKeys,
  }) async {
    try {
      final r = await _repo.create(
        projectId: arg,
        amount: amount,
        stageId: stageId,
        comment: comment,
        photoKeys: photoKeys,
      );
      _upsert(r);
      return null;
    } on SelfPurchaseException catch (e) {
      return e.failure;
    }
  }

  /// approve с авто-forward при подтверждении бригадиром master-самозакупа.
  /// UI вызывает с [forwardOnApprove]=true когда viewer=foreman и
  /// byRole=master — бекенд создаст 2-ю запись foreman→customer.
  Future<AuthFailure?> approve({
    required String id,
    String? comment,
    bool forwardOnApprove = false,
  }) => _run(
    () => _repo.approve(
      id: id,
      comment: comment,
      forwardOnApprove: forwardOnApprove,
    ),
    // Forward не попадает в budget на approve бригадиром — там лишь
    // создаётся pending для заказчика. Поэтому invalidate бюджета
    // только когда status=approved у foreman→customer записи.
    forwardedFromMaster: forwardOnApprove,
  );

  Future<AuthFailure?> reject({required String id, String? comment}) =>
      _run(() => _repo.reject(id: id, comment: comment));

  Future<AuthFailure?> _run(
    Future<SelfPurchase> Function() fn, {
    bool forwardedFromMaster = false,
  }) async {
    try {
      final r = await fn();
      _upsert(r);
      // После forward оригинал master→foreman остался в списке как approved,
      // плюс должен подтянуться новый foreman→customer pending. Тихий refresh
      // (без loading-стейта), чтобы UI показал обе записи без мигания.
      if (forwardedFromMaster) {
        _scheduleRefresh();
      }
      // Одобренный foreman→customer самозакуп попадает в бюджет.
      if (r.status == SelfPurchaseStatus.approved && !forwardedFromMaster) {
        ref.invalidate(projectBudgetProvider(arg));
      }
      return null;
    } on SelfPurchaseException catch (e) {
      return e.failure;
    }
  }
}
