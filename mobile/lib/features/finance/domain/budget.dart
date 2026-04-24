import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';

@freezed
class BudgetBucket with _$BudgetBucket {
  const factory BudgetBucket({
    required int planned,
    required int spent,
    required int remaining,
  }) = _BudgetBucket;

  static BudgetBucket parse(Map<String, dynamic>? json) => BudgetBucket(
        planned: (json?['planned'] as num?)?.toInt() ?? 0,
        spent: (json?['spent'] as num?)?.toInt() ?? 0,
        remaining: (json?['remaining'] as num?)?.toInt() ?? 0,
      );

  static const empty =
      BudgetBucket(planned: 0, spent: 0, remaining: 0);
}

extension BudgetBucketX on BudgetBucket {
  double get progress {
    if (planned <= 0) return 0;
    final raw = spent / planned;
    return raw.clamp(0.0, 1.0);
  }

  bool get overSpent => spent > planned;
}

@freezed
class StageBudget with _$StageBudget {
  const factory StageBudget({
    required String stageId,
    required String title,
    required BudgetBucket work,
    required BudgetBucket materials,
    required BudgetBucket total,
  }) = _StageBudget;

  static StageBudget parse(Map<String, dynamic> json) => StageBudget(
        stageId: json['stageId'] as String,
        title: json['title'] as String? ?? 'Этап',
        work: BudgetBucket.parse(json['work'] as Map<String, dynamic>?),
        materials:
            BudgetBucket.parse(json['materials'] as Map<String, dynamic>?),
        total: BudgetBucket.parse(json['total'] as Map<String, dynamic>?),
      );
}

@freezed
class ProjectBudget with _$ProjectBudget {
  const factory ProjectBudget({
    required BudgetBucket work,
    required BudgetBucket materials,
    required BudgetBucket total,
    @Default(<StageBudget>[]) List<StageBudget> stages,
  }) = _ProjectBudget;

  static ProjectBudget parse(Map<String, dynamic> json) => ProjectBudget(
        work: BudgetBucket.parse(json['work'] as Map<String, dynamic>?),
        materials:
            BudgetBucket.parse(json['materials'] as Map<String, dynamic>?),
        total: BudgetBucket.parse(json['total'] as Map<String, dynamic>?),
        stages: (json['stages'] as List<dynamic>? ?? const [])
            .map((e) => StageBudget.parse(e as Map<String, dynamic>))
            .toList(),
      );
}
