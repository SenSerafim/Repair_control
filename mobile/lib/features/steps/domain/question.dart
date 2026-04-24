import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';

enum QuestionStatus {
  open,
  answered,
  closed;

  static QuestionStatus fromString(String? raw) {
    switch (raw) {
      case 'answered':
        return QuestionStatus.answered;
      case 'closed':
        return QuestionStatus.closed;
      case 'open':
      default:
        return QuestionStatus.open;
    }
  }

  String get displayName => switch (this) {
        QuestionStatus.open => 'Открыт',
        QuestionStatus.answered => 'Отвечен',
        QuestionStatus.closed => 'Закрыт',
      };
}

@freezed
class Question with _$Question {
  const factory Question({
    required String id,
    required String stepId,
    required String authorId,
    required String addresseeId,
    required String text,
    required QuestionStatus status,
    String? answer,
    DateTime? answeredAt,
    String? answeredBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Question;

  static Question parse(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        stepId: json['stepId'] as String,
        authorId: json['authorId'] as String? ?? '',
        addresseeId: json['addresseeId'] as String? ?? '',
        text: json['text'] as String,
        status: QuestionStatus.fromString(json['status'] as String?),
        answer: json['answer'] as String?,
        answeredAt: _d(json['answeredAt']),
        answeredBy: json['answeredBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
