import 'package:freezed_annotation/freezed_annotation.dart';

part 'substep.freezed.dart';

@freezed
class Substep with _$Substep {
  const factory Substep({
    required String id,
    required String stepId,
    required String text,
    required String authorId,
    required bool isDone,
    DateTime? doneAt,
    String? doneById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Substep;

  static Substep parse(Map<String, dynamic> json) => Substep(
        id: json['id'] as String,
        stepId: json['stepId'] as String,
        text: json['text'] as String,
        authorId: json['authorId'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        doneAt: _date(json['doneAt']),
        doneById: json['doneById'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw) : null;
