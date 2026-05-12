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

  static const empty = BudgetBucket(planned: 0, spent: 0, remaining: 0);
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
    materials: BudgetBucket.parse(json['materials'] as Map<String, dynamic>?),
    total: BudgetBucket.parse(json['total'] as Map<String, dynamic>?),
  );
}

/// Master видит только свои выплаты, без planned/spent проекта.
/// Backend заполняет `earnings[]` + `viewerKind='master'`.
class MasterEarning {
  const MasterEarning({
    required this.paymentId,
    required this.amount,
    required this.createdAt,
    this.stageId,
  });

  final String paymentId;
  final String? stageId;
  final int amount;
  final DateTime createdAt;

  static MasterEarning parse(Map<String, dynamic> json) => MasterEarning(
    paymentId: json['paymentId'] as String,
    stageId: json['stageId'] as String?,
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

enum BudgetViewerKind { owner, representative, foreman, master, unknown }

/// ProjectBudget — plain Dart (не freezed), чтобы можно было добавлять поля
/// без перегенерации .freezed.dart (build_runner локально не запускается).
class ProjectBudget {
  const ProjectBudget({
    required this.work,
    required this.materials,
    required this.total,
    this.stages = const <StageBudget>[],
    this.viewerKind = BudgetViewerKind.unknown,
    this.earnings = const <MasterEarning>[],
    this.noStageBudget = false,
  });

  final BudgetBucket work;
  final BudgetBucket materials;
  final BudgetBucket total;
  final List<StageBudget> stages;
  final BudgetViewerKind viewerKind;
  final List<MasterEarning> earnings;

  /// true → бригадир видит свои этапы, но workBudget/materialsBudget на них = 0,
  /// а у Project бюджет задан. UI показывает inline-баннер «Заказчик не разнёс
  /// бюджет по вашим этапам».
  final bool noStageBudget;

  static ProjectBudget parse(Map<String, dynamic> json) {
    final viewer = switch (json['viewerKind'] as String?) {
      'owner' => BudgetViewerKind.owner,
      'representative' => BudgetViewerKind.representative,
      'foreman' => BudgetViewerKind.foreman,
      'master' => BudgetViewerKind.master,
      _ => BudgetViewerKind.unknown,
    };
    return ProjectBudget(
      work: BudgetBucket.parse(json['work'] as Map<String, dynamic>?),
      materials: BudgetBucket.parse(json['materials'] as Map<String, dynamic>?),
      total: BudgetBucket.parse(json['total'] as Map<String, dynamic>?),
      stages: (json['stages'] as List<dynamic>? ?? const [])
          .map((e) => StageBudget.parse(e as Map<String, dynamic>))
          .toList(),
      viewerKind: viewer,
      earnings: (json['earnings'] as List<dynamic>? ?? const [])
          .map((e) => MasterEarning.parse(e as Map<String, dynamic>))
          .toList(),
      noStageBudget: json['noStageBudget'] as bool? ?? false,
    );
  }
}
