import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/note.dart';

class NotesException implements Exception {
  NotesException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class NotesRepository {
  NotesRepository(this._dio);
  final Dio _dio;

  Future<List<Note>> list({
    required String projectId,
    NoteScope? scope,
    String? stageId,
    String? search,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/notes',
          queryParameters: {
            if (scope != null) 'scope': scope.apiValue,
            if (stageId != null) 'stageId': stageId,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        );
        return r.data!
            .map((e) => Note.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Note> create({
    required String projectId,
    required NoteScope scope,
    required String text,
    String? addresseeId,
    String? stageId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/notes',
          data: {
            'scope': scope.apiValue,
            'text': text,
            if (addresseeId != null) 'addresseeId': addresseeId,
            if (stageId != null) 'stageId': stageId,
          },
        );
        return Note.parse(r.data!);
      });

  Future<Note> update({
    required String noteId,
    required String text,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/notes/$noteId',
          data: {'text': text},
        );
        return Note.parse(r.data!);
      });

  Future<void> delete(String noteId) => _call(() async {
        await _dio.delete<void>('/api/notes/$noteId');
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw NotesException(AuthFailure.fromApiError(api), api);
    }
  }
}

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.read(dioProvider));
});
