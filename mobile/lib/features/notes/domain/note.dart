import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';

enum NoteScope {
  personal,
  forMe,
  stage,

  /// П1.10 / П2.19 — заметка для всей команды проекта; разрешено создавать
  /// «впрок» (когда команда ещё пуста). Видна каждому участнику с момента
  /// создания, исторически (П10.7).
  teamBroadcast;

  String get apiValue => switch (this) {
    NoteScope.personal => 'personal',
    NoteScope.forMe => 'for_me',
    NoteScope.stage => 'stage',
    NoteScope.teamBroadcast => 'team_broadcast',
  };

  static NoteScope fromString(String? raw) {
    switch (raw) {
      case 'for_me':
        return NoteScope.forMe;
      case 'stage':
        return NoteScope.stage;
      case 'team_broadcast':
        return NoteScope.teamBroadcast;
      case 'personal':
      default:
        return NoteScope.personal;
    }
  }

  String get displayName => switch (this) {
    NoteScope.personal => 'Только мне',
    NoteScope.forMe => 'Конкретному участнику',
    NoteScope.stage => 'Всей команде этапа',
    NoteScope.teamBroadcast => 'Всей команде проекта',
  };

  /// Короткое пояснение, которое показывается под радио-опцией в форме
  /// создания заметки — отвечает на вопрос «кто это увидит?».
  String get hint => switch (this) {
    NoteScope.personal =>
      'Никто, кроме вас, не увидит эту заметку. Подходит для напоминаний.',
    NoteScope.forMe =>
      'Адресная заметка одному участнику. Видна вам и адресату.',
    NoteScope.stage =>
      'Видна всем участникам этапа — мастерам, бригадиру, заказчику.',
    NoteScope.teamBroadcast =>
      'Видна всей команде проекта. Можно создать заранее — будущие участники тоже увидят её исторически.',
  };
}

/// NEWFIX-2 §11.4 — формат заметки.
enum NoteKind {
  text,
  audio;

  String get apiValue => switch (this) {
    NoteKind.text => 'text',
    NoteKind.audio => 'audio',
  };

  static NoteKind fromString(String? raw) {
    switch (raw) {
      case 'audio':
        return NoteKind.audio;
      case 'text':
      default:
        return NoteKind.text;
    }
  }
}

/// Задел для варианта B (фоновый STT) — статус расшифровки голосовой заметки.
/// Сейчас бекенд возвращает только `null` (вариант A); enum нужен для
/// корректного парсинга, когда STT-pipeline появится.
enum TranscriptStatus {
  pending,
  done,
  failed;

  static TranscriptStatus? fromString(String? raw) {
    switch (raw) {
      case 'pending':
        return TranscriptStatus.pending;
      case 'done':
        return TranscriptStatus.done;
      case 'failed':
        return TranscriptStatus.failed;
      default:
        return null;
    }
  }
}

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required NoteScope scope,
    required NoteKind kind,
    required String authorId,
    String? addresseeId,
    String? projectId,
    String? stageId,
    String? text,
    String? audioKey,
    String? audioMimeType,
    int? audioDurationMs,
    String? audioUrl,
    String? transcript,
    TranscriptStatus? transcriptStatus,
    String? transcriptProvider,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Note;

  static Note parse(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    scope: NoteScope.fromString(json['scope'] as String?),
    kind: NoteKind.fromString(json['kind'] as String?),
    authorId: json['authorId'] as String? ?? '',
    addresseeId: json['addresseeId'] as String?,
    projectId: json['projectId'] as String?,
    stageId: json['stageId'] as String?,
    text: json['text'] as String?,
    audioKey: json['audioKey'] as String?,
    audioMimeType: json['audioMimeType'] as String?,
    audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
    audioUrl: json['audioUrl'] as String?,
    transcript: json['transcript'] as String?,
    transcriptStatus: TranscriptStatus.fromString(
      json['transcriptStatus'] as String?,
    ),
    transcriptProvider: json['transcriptProvider'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
