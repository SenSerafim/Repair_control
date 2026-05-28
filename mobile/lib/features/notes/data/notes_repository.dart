import 'dart:io';
import 'dart:typed_data';

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

/// NEWFIX-2 §11.5 — фильтр экрана «Заметки проекта». При scope=null + filter:
/// - all → все scope, видимые мне
/// - mine → только мои (любой scope, authorId = me)
/// - team → только team_broadcast
enum NotesListFilter {
  all,
  mine,
  team;

  String get apiValue => switch (this) {
    NotesListFilter.all => 'all',
    NotesListFilter.mine => 'mine',
    NotesListFilter.team => 'team',
  };
}

class NotesRepository {
  NotesRepository(this._dio);
  final Dio _dio;

  Future<List<Note>> list({
    required String projectId,
    NoteScope? scope,
    NotesListFilter? filter,
    String? stageId,
    String? search,
  }) => _call(() async {
    final r = await _dio.get<List<dynamic>>(
      '/api/projects/$projectId/notes',
      queryParameters: {
        if (scope != null) 'scope': scope.apiValue,
        if (filter != null) 'filter': filter.apiValue,
        if (stageId != null) 'stageId': stageId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return r.data!.map((e) => Note.parse(e as Map<String, dynamic>)).toList();
  });

  Future<Note> create({
    required String projectId,
    required NoteScope scope,
    NoteKind kind = NoteKind.text,
    String? text,
    String? audioKey,
    String? audioMimeType,
    int? audioDurationMs,
    String? addresseeId,
    String? stageId,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/projects/$projectId/notes',
      data: {
        'scope': scope.apiValue,
        'kind': kind.apiValue,
        if (text != null && text.isNotEmpty) 'text': text,
        if (audioKey != null) 'audioKey': audioKey,
        if (audioMimeType != null) 'audioMimeType': audioMimeType,
        if (audioDurationMs != null) 'audioDurationMs': audioDurationMs,
        if (addresseeId != null) 'addresseeId': addresseeId,
        if (stageId != null) 'stageId': stageId,
      },
    );
    return Note.parse(r.data!);
  });

  Future<Note> update({required String noteId, required String text}) =>
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

  /// E11 — presign + raw PUT для аудио-заметки. Возвращает audioKey и MIME
  /// для последующего POST /projects/:id/notes.
  Future<NoteAudioUploadResult> uploadAudio({
    required File file,
    required String mimeType,
  }) => _call(() async {
    final bytes = await file.readAsBytes();
    final presign = await _dio.post<Map<String, dynamic>>(
      '/api/files/presign-upload',
      data: {
        'originalName': file.uri.pathSegments.last,
        'mimeType': mimeType,
        'sizeBytes': bytes.length,
        'scope': 'notes/audio',
      },
    );
    final upload = NotePresignedUpload.fromJson(presign.data!);
    await _putBytes(
      url: upload.url,
      method: upload.method,
      bytes: bytes,
      mimeType: mimeType,
      extraHeaders: upload.headers,
    );
    return NoteAudioUploadResult(
      audioKey: upload.fileKey,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  });

  Future<void> _putBytes({
    required String url,
    required String method,
    required Uint8List bytes,
    required String mimeType,
    Map<String, String> extraHeaders = const {},
  }) async {
    final rawDio = Dio();
    try {
      await rawDio.request<void>(
        url,
        data: bytes,
        options: Options(
          method: method,
          headers: {
            ...extraHeaders,
            'Content-Type': mimeType,
            'Content-Length': bytes.length.toString(),
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw NotesException(AuthFailure.fromApiError(api), api);
    }
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw NotesException(AuthFailure.fromApiError(api), api);
    }
  }
}

class NotePresignedUpload {
  NotePresignedUpload({
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
  });

  factory NotePresignedUpload.fromJson(Map<String, dynamic> json) =>
      NotePresignedUpload(
        fileKey: (json['key'] ?? json['fileKey']) as String,
        url: (json['url'] ?? json['uploadUrl']) as String,
        method: json['method'] as String? ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );

  final String fileKey;
  final String url;
  final String method;
  final Map<String, String> headers;
}

class NoteAudioUploadResult {
  NoteAudioUploadResult({
    required this.audioKey,
    required this.mimeType,
    required this.sizeBytes,
  });
  final String audioKey;
  final String mimeType;
  final int sizeBytes;
}

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.read(dioProvider));
});
