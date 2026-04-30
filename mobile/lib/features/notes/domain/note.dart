import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';

enum NoteScope {
  personal,
  forMe,
  stage;

  String get apiValue => switch (this) {
        NoteScope.personal => 'personal',
        NoteScope.forMe => 'for_me',
        NoteScope.stage => 'stage',
      };

  static NoteScope fromString(String? raw) {
    switch (raw) {
      case 'for_me':
        return NoteScope.forMe;
      case 'stage':
        return NoteScope.stage;
      case 'personal':
      default:
        return NoteScope.personal;
    }
  }

  String get displayName => switch (this) {
        NoteScope.personal => 'Только мне',
        NoteScope.forMe => 'Конкретному участнику',
        NoteScope.stage => 'Всей команде этапа',
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
      };
}

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required NoteScope scope,
    required String authorId,
    String? addresseeId,
    String? projectId,
    String? stageId,
    required String text,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Note;

  static Note parse(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        scope: NoteScope.fromString(json['scope'] as String?),
        authorId: json['authorId'] as String? ?? '',
        addresseeId: json['addresseeId'] as String?,
        projectId: json['projectId'] as String?,
        stageId: json['stageId'] as String?,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
