import 'package:freezed_annotation/freezed_annotation.dart';

part 'faq.freezed.dart';

/// Элемент FAQ (вопрос/ответ).
@freezed
class FaqItem with _$FaqItem {
  const factory FaqItem({
    required String id,
    required String question,
    required String answer,
    required int orderIndex,
  }) = _FaqItem;

  static FaqItem parse(Map<String, dynamic> json) => FaqItem(
        id: json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      );
}

/// Секция FAQ с вложенными items.
@freezed
class FaqSection with _$FaqSection {
  const factory FaqSection({
    required String id,
    required String title,
    required int orderIndex,
    @Default(<FaqItem>[]) List<FaqItem> items,
  }) = _FaqSection;

  static FaqSection parse(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? const [];
    return FaqSection(
      id: json['id'] as String,
      title: json['title'] as String,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      items: itemsRaw
          .map((it) => FaqItem.parse(it as Map<String, dynamic>))
          .toList(),
    );
  }
}
