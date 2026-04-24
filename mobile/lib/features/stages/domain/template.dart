import 'package:freezed_annotation/freezed_annotation.dart';

part 'template.freezed.dart';

enum TemplateKind {
  platform,
  user;

  static TemplateKind fromString(String? raw) =>
      raw == 'user' ? TemplateKind.user : TemplateKind.platform;
}

@freezed
class TemplateStep with _$TemplateStep {
  const factory TemplateStep({
    required String id,
    required String title,
    required int orderIndex,
    int? price,
  }) = _TemplateStep;

  static TemplateStep parse(Map<String, dynamic> json) => TemplateStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toInt(),
      );
}

@freezed
class StageTemplate with _$StageTemplate {
  const factory StageTemplate({
    required String id,
    required TemplateKind kind,
    required String title,
    String? description,
    String? authorId,
    @Default(<TemplateStep>[]) List<TemplateStep> steps,
  }) = _StageTemplate;

  static StageTemplate parse(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];
    final steps = rawSteps
        .map((s) => TemplateStep.parse(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return StageTemplate(
      id: json['id'] as String,
      kind: TemplateKind.fromString(json['kind'] as String?),
      title: json['title'] as String,
      description: json['description'] as String?,
      authorId: json['authorId'] as String?,
      steps: steps,
    );
  }
}
