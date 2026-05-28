import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/storage/offline_queue.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

final notesControllerProvider =
    AsyncNotifierProvider.family<NotesController, List<Note>, String>(
      NotesController.new,
    );

class NotesController extends FamilyAsyncNotifier<List<Note>, String> {
  @override
  Future<List<Note>> build(String projectId) {
    return ref.read(notesRepositoryProvider).list(projectId: projectId);
  }

  Future<AuthFailure?> create({
    required NoteScope scope,
    NoteKind kind = NoteKind.text,
    String? text,
    String? audioKey,
    String? audioMimeType,
    int? audioDurationMs,
    String? addresseeId,
    String? stageId,
  }) async {
    final isOffline =
        ref.read(connectivityProvider).value == ConnectivityStatus.offline;
    if (isOffline && kind == NoteKind.text) {
      // Аудио — отложенно не сохраняем: presign+PUT требуют сеть.
      // Оффлайн-очередь раньше использовалась только для text, оставляем как было.
      await ref
          .read(offlineQueueProvider)
          .enqueue(
            kind: OfflineActionKind.noteCreate,
            payload: {
              'projectId': arg,
              'scope': scope.apiValue,
              'text': text ?? '',
              if (addresseeId != null) 'addresseeId': addresseeId,
              if (stageId != null) 'stageId': stageId,
            },
          );
      return null;
    }
    try {
      final note = await ref
          .read(notesRepositoryProvider)
          .create(
            projectId: arg,
            scope: scope,
            kind: kind,
            text: text,
            audioKey: audioKey,
            audioMimeType: audioMimeType,
            audioDurationMs: audioDurationMs,
            addresseeId: addresseeId,
            stageId: stageId,
          );
      final cur = state.value ?? const <Note>[];
      state = AsyncData([note, ...cur]);
      return null;
    } on NotesException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> updateText({
    required String noteId,
    required String text,
  }) async {
    try {
      final updated = await ref
          .read(notesRepositoryProvider)
          .update(noteId: noteId, text: text);
      final cur = state.value ?? const <Note>[];
      state = AsyncData(cur.map((n) => n.id == noteId ? updated : n).toList());
      return null;
    } on NotesException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> delete(String noteId) async {
    final prev = state.value ?? const <Note>[];
    state = AsyncData(prev.where((n) => n.id != noteId).toList());
    try {
      await ref.read(notesRepositoryProvider).delete(noteId);
      return null;
    } on NotesException catch (e) {
      state = AsyncData(prev);
      return e.failure;
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notesRepositoryProvider).list(projectId: arg),
    );
  }
}

/// NEWFIX-2 §11.5 — server-side фильтрация для нового ProjectNotesScreen.
/// Возвращает плоский список Note под выбранным фильтром. При изменении
/// notesControllerProvider (create/update/delete) — автоматически
/// инвалидируется через watch.
final projectNotesByFilterProvider = FutureProvider.autoDispose
    .family<List<Note>, ({String projectId, NotesListFilter filter})>((
      ref,
      args,
    ) async {
      ref.watch(notesControllerProvider(args.projectId));
      return ref
          .read(notesRepositoryProvider)
          .list(projectId: args.projectId, filter: args.filter);
    });
