import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/tools_repository.dart';
import '../domain/tool.dart';

// ───────────────────────── My Tools (профиль) ─────────────────────────

final myToolsProvider =
    AsyncNotifierProvider<MyToolsController, List<ToolItem>>(
      MyToolsController.new,
    );

class MyToolsController extends AsyncNotifier<List<ToolItem>> {
  @override
  Future<List<ToolItem>> build() {
    return ref.read(toolsRepositoryProvider).myTools();
  }

  /// Сброс state до AsyncLoading() — вызывается при logout, чтобы не мерцал
  /// кеш предыдущего пользователя (см. [userScopedInvalidationProvider]).
  void resetForLogout() {
    state = const AsyncValue.loading();
  }

  ToolsRepository get _repo => ref.read(toolsRepositoryProvider);

  void _upsert(ToolItem t) {
    final cur = state.value ?? const <ToolItem>[];
    final exists = cur.any((x) => x.id == t.id);
    state = AsyncData(
      exists ? cur.map((x) => x.id == t.id ? t : x).toList() : [t, ...cur],
    );
  }

  Future<AuthFailure?> create({
    required String name,
    String? photoKey,
    String? serial,
  }) async {
    try {
      final t = await _repo.createMyTool(
        name: name,
        photoKey: photoKey,
        serial: serial,
      );
      _upsert(t);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> saveUpdate({
    required String id,
    String? name,
    String? serial,
    String? photoKey,
  }) async {
    try {
      final t = await _repo.updateTool(
        id: id,
        name: name,
        serial: serial,
        photoKey: photoKey,
      );
      _upsert(t);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> remove(String id) async {
    try {
      await _repo.deleteTool(id);
      final cur = state.value ?? const <ToolItem>[];
      state = AsyncData(cur.where((t) => t.id != id).toList());
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }
}

/// Один инструмент по id (для tool detail / редактирования).
final toolDetailProvider = FutureProvider.family<ToolItem, String>((ref, id) {
  return ref.read(toolsRepositoryProvider).getTool(id);
});

// ───────────────────────── Project Tools (доска проекта) ─────────────────────────

/// Список инструментов проекта с обогащением owner/holder. Виден ВСЕМ
/// участникам (self-custody модель). Все операции (create / attach / claim)
/// инвалидируют этот provider; realtime `tool:changed` тоже инвалидирует.
final projectToolsBoardProvider = AsyncNotifierProvider.family<
  ProjectToolsBoardController,
  List<ToolItem>,
  String
>(ProjectToolsBoardController.new);

class ProjectToolsBoardController
    extends FamilyAsyncNotifier<List<ToolItem>, String> {
  StreamSubscription<dynamic>? _toolSub;
  Timer? _refreshDebounce;

  @override
  Future<List<ToolItem>> build(String projectId) async {
    // Real-time: бекенд эмитит `tool:changed` всем участникам проекта при
    // create/attach/detach/claim. Перезагружаем доску, чтобы у всех ролей
    // сразу обновлялся «У кого сейчас».
    final socket = ref.read(socketServiceProvider);
    _toolSub = socket.on(SocketEvents.toolChanged).listen((payload) {
      if (payload is! Map) return;
      if (payload['projectId']?.toString() != projectId) return;
      _scheduleRefresh();
      final toolId = payload['toolItemId']?.toString();
      if (toolId != null && toolId.isNotEmpty) {
        ref.invalidate(toolCustodyHistoryProvider(toolId));
        ref.invalidate(toolDetailProvider(toolId));
      }
    });
    ref.onDispose(() {
      _toolSub?.cancel();
      _refreshDebounce?.cancel();
    });

    return ref.read(toolsRepositoryProvider).listProjectTools(projectId);
  }

  /// Дебаунс 300ms — несколько подряд событий (claim + добавление) не
  /// провоцируют серию GET'ов.
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final list = await ref.read(toolsRepositoryProvider).listProjectTools(arg);
        state = AsyncData(list);
      } catch (_) {
        // Игнорируем: основной flow сделает invalidate при next mutation.
      }
    });
  }

  ToolsRepository get _repo => ref.read(toolsRepositoryProvider);

  void _upsert(ToolItem t) {
    final cur = state.value ?? const <ToolItem>[];
    final exists = cur.any((x) => x.id == t.id);
    state = AsyncData(
      exists ? cur.map((x) => x.id == t.id ? t : x).toList() : [t, ...cur],
    );
  }

  /// Создать новый инструмент сразу в проекте.
  Future<AuthFailure?> createInProject({
    required String name,
    String? ownerId,
    String? photoKey,
    String? serial,
  }) async {
    try {
      final t = await _repo.createInProject(
        projectId: arg,
        name: name,
        ownerId: ownerId,
        photoKey: photoKey,
        serial: serial,
      );
      _upsert(t);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  /// Bulk attach «из моих инструментов в проект».
  Future<AuthFailure?> attachFromMy(List<String> toolItemIds) async {
    try {
      final added = await _repo.attachFromMy(
        projectId: arg,
        toolItemIds: toolItemIds,
      );
      for (final t in added) {
        _upsert(t);
      }
      ref.invalidate(myToolsProvider);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  /// Self-claim: текущий пользователь становится holder-ом.
  Future<AuthFailure?> claim({required String toolId, String? note}) async {
    try {
      final t = await _repo.claim(toolId: toolId, note: note);
      _upsert(t);
      // Custody-history и detail тоже поменялись — инвалидируем,
      // чтобы tool_detail_screen и timeline сразу показали актуальное.
      ref.invalidate(toolCustodyHistoryProvider(toolId));
      ref.invalidate(toolDetailProvider(toolId));
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }

  /// Открепить инструмент от проекта (owner only).
  Future<AuthFailure?> detach(String toolId) async {
    try {
      await _repo.detachFromProject(projectId: arg, toolId: toolId);
      final cur = state.value ?? const <ToolItem>[];
      state = AsyncData(cur.where((t) => t.id != toolId).toList());
      ref.invalidate(myToolsProvider);
      return null;
    } on ToolsException catch (e) {
      return e.failure;
    }
  }
}

/// Timeline передач инструмента (для tool detail screen).
final toolCustodyHistoryProvider = FutureProvider.family<
  List<ToolCustodyEvent>,
  String
>((ref, toolId) {
  return ref.read(toolsRepositoryProvider).custodyHistory(toolId);
});
