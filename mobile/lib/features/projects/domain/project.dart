import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'project.freezed.dart';

enum ProjectStatus {
  active,
  archived;

  static ProjectStatus fromString(String? raw) {
    if (raw == null) return ProjectStatus.active;
    for (final s in values) {
      if (s.name.toLowerCase() == raw.toLowerCase()) return s;
    }
    return ProjectStatus.active;
  }
}

/// Проект. Соответствует Prisma-модели `Project` + serialize() из
/// backend/apps/api/src/modules/projects/projects.service.ts
/// (workBudget/materialsBudget: BigInt → Number).
@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String ownerId,
    required String title,
    String? address,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    required ProjectStatus status,
    required int workBudget,
    required int materialsBudget,
    required int progressCache,
    required Semaphore semaphore,
    required bool planApproved,
    required bool requiresPlanApproval,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Project;

  static Project parse(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        title: json['title'] as String,
        address: json['address'] as String?,
        plannedStart: _date(json['plannedStart']),
        plannedEnd: _date(json['plannedEnd']),
        status: ProjectStatus.fromString(json['status'] as String?),
        workBudget: (json['workBudget'] as num?)?.toInt() ?? 0,
        materialsBudget: (json['materialsBudget'] as num?)?.toInt() ?? 0,
        progressCache: (json['progressCache'] as num?)?.toInt() ?? 0,
        semaphore: _semaphore(json['semaphoreCache'] as String?),
        planApproved: json['planApproved'] as bool? ?? false,
        requiresPlanApproval:
            json['requiresPlanApproval'] as bool? ?? false,
        archivedAt: _date(json['archivedAt']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

DateTime? _date(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

Semaphore _semaphore(String? raw) {
  switch (raw) {
    case 'green':
      return Semaphore.green;
    case 'yellow':
      return Semaphore.yellow;
    case 'red':
      return Semaphore.red;
    case 'blue':
      return Semaphore.blue;
    case null:
    case 'plan':
    default:
      return Semaphore.plan;
  }
}

extension ProjectX on Project {
  bool get isArchived => status == ProjectStatus.archived;

  String get semaphoreLabel => switch (semaphore) {
        Semaphore.green => 'По графику',
        Semaphore.yellow => 'Отставание',
        Semaphore.red => 'Просрочен',
        Semaphore.blue => 'Согласования',
        Semaphore.plan => 'В плане',
      };

  int get totalBudget => workBudget + materialsBudget;
}
