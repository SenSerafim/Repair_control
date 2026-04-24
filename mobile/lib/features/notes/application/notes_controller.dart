import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/storage/offline_queue.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

final notesControllerProvider = AsyncNotifierProvider.family<
    NotesController, List<Note>, String>(NotesController.new);

class NotesController extends FamilyAsyncNotifier<List<Note>, String> {
  @override
  Future<List<Note>> build(String projectId) {
    return ref.read(notesRepositoryProvider).list(projectId: projectId);
  }

  Future<AuthFailure?> create({
    required NoteScope scope,
    required String text,
    String? addresseeId,
    String? stageId,
  }) async {
    final isOffline = ref.read(connectivityProvider).value ==
        ConnectivityStatus.offline;
    if (isOffline) {
      await ref.read(offlineQueueProvider).enqueue(
        kind: OfflineActionKind.noteCreate,
        payload: {
          'projectId': arg,
          'scope': scope.apiValue,
          'text': text,
          if (addresseeId != null) 'addresseeId': addresseeId,
          if (stageId != null) 'stageId': stageId,
        },
      );
      return null;
    }
    try {
      final note = await ref.read(notesRepositoryProvider).create(
            projectId: arg,
            scope: scope,
            text: text,
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
      final updated =
          await ref.read(notesRepositoryProvider).update(noteId: noteId, text: text);
      final cur = state.value ?? const <Note>[];
      state = AsyncData(
        cur.map((n) => n.id == noteId ? updated : n).toList(),
      );
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
}
