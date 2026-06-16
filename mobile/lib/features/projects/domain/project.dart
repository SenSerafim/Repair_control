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
    String? description,
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

  static Project parse(Map<String, dynamic> json) {
    final p = Project(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      address: json['address'] as String?,
      description: json['description'] as String?,
      plannedStart: _date(json['plannedStart']),
      plannedEnd: _date(json['plannedEnd']),
      status: ProjectStatus.fromString(json['status'] as String?),
      workBudget: (json['workBudget'] as num?)?.toInt() ?? 0,
      materialsBudget: (json['materialsBudget'] as num?)?.toInt() ?? 0,
      progressCache: (json['progressCache'] as num?)?.toInt() ?? 0,
      semaphore: _semaphore(json['semaphoreCache'] as String?),
      planApproved: json['planApproved'] as bool? ?? false,
      requiresPlanApproval: json['requiresPlanApproval'] as bool? ?? false,
      archivedAt: _date(json['archivedAt']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
    // NEWFIX §1 — счётчики этапов приходят с listForUser (backend
    // aggregateStageCounts). Сохраняем в внешний кеш, чтобы не дёргать
    // freezed-регенерацию ради 3 полей.
    final total = (json['stagesTotal'] as num?)?.toInt();
    if (total != null) {
      ProjectStageStats._cache[p.id] = (
        done: (json['stagesDone'] as num?)?.toInt() ?? 0,
        total: total,
        inProgress: (json['stagesInProgress'] as num?)?.toInt() ?? 0,
      );
    }
    return p;
  }
}

typedef ProjectStageStatsRecord = ({int done, int total, int inProgress});

/// Кеш счётчиков этапов проекта (NEWFIX §1). Заполняется в `Project.parse`
/// из payload бекенда, читается в карточке проекта.
class ProjectStageStats {
  ProjectStageStats._();
  static final Map<String, ProjectStageStatsRecord> _cache = {};

  static ProjectStageStatsRecord? of(String projectId) => _cache[projectId];
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
    case 'paused':
      return Semaphore.paused;
    case null:
    case 'plan':
    default:
      return Semaphore.plan;
  }
}

extension ProjectX on Project {
  bool get isArchived => status == ProjectStatus.archived;

  /// Клиентский фикс рассинхрона с `semaphoreCache` (cron 15 мин + recalc по
  /// триггерам). Если у проекта дедлайн прошёл, но кеш ещё green/blue/yellow —
  /// поднимаем флаг сами: `paused`, когда план не утверждён (блокер у
  /// заказчика), иначе `red`. Не трогаем cache=done/red — там бекенд уже прав.
  Semaphore get effectiveSemaphore {
    if (isArchived) return semaphore;
    if (semaphore == Semaphore.red || semaphore == Semaphore.plan) {
      return semaphore;
    }
    if (plannedEnd == null) return semaphore;
    final now = DateTime.now();
    final due = DateTime(plannedEnd!.year, plannedEnd!.month, plannedEnd!.day);
    final today = DateTime(now.year, now.month, now.day);
    if (!due.isBefore(today)) return semaphore;
    return planApproved ? Semaphore.red : Semaphore.paused;
  }

  String get semaphoreLabel => _labelFor(semaphore);
  String get effectiveSemaphoreLabel => _labelFor(effectiveSemaphore);

  int get totalBudget => workBudget + materialsBudget;

  ProjectStageStatsRecord? get stageStats => ProjectStageStats.of(id);
}

String _labelFor(Semaphore s) => switch (s) {
  Semaphore.green => 'По графику',
  Semaphore.yellow => 'Отставание',
  Semaphore.red => 'Просрочен',
  Semaphore.blue => 'Согласования',
  Semaphore.plan => 'В плане',
  Semaphore.paused => 'На паузе',
};
