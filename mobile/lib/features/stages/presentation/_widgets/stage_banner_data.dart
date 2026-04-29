import '../../domain/stage.dart';
import '../stage_widgets.dart' show StageDisplayStatus;

/// Sealed-данные для StageStatusBanner (8 вариантов из дизайна Кластер C).
///
/// Каждое состояние этапа разворачивается в свой banner с уникальной палитрой,
/// иконкой и набором полей. Фабрика [StageBannerData.fromStage] инкапсулирует
/// маппинг [StageDisplayStatus] → конкретный variant.
sealed class StageBannerData {
  const StageBannerData();

  /// Маппинг computed-статуса этапа в подходящий вариант banner'а.
  static StageBannerData? fromStage(Stage stage, StageDisplayStatus display) {
    final now = DateTime.now();
    return switch (display) {
      StageDisplayStatus.active => ActiveTimerBanner(
          startedAt: stage.startedAt ?? stage.updatedAt,
          plannedEnd: stage.plannedEnd,
        ),
      StageDisplayStatus.paused => PausedDeadlineShiftBanner(
          originalEnd: stage.originalEnd,
          newEnd: stage.plannedEnd,
        ),
      StageDisplayStatus.review => const ReviewBanner(),
      StageDisplayStatus.overdue => OverdueBanner(
          daysLate: stage.plannedEnd == null
              ? 0
              : now.difference(stage.plannedEnd!).inDays,
        ),
      StageDisplayStatus.lateStart => LateStartBanner(
          startedDue: stage.plannedStart,
        ),
      StageDisplayStatus.rejected => const RejectedBanner(
          reasonText: '',
          actorName: '',
          attempt: 1,
        ),
      StageDisplayStatus.pending =>
        stage.foremanIds.isEmpty ? const WaitingNoContractorBanner() : null,
      StageDisplayStatus.done => const DoneBanner(),
    };
  }
}

/// Active: brand-bg бар с таймером с момента startedAt.
class ActiveTimerBanner extends StageBannerData {
  const ActiveTimerBanner({required this.startedAt, this.plannedEnd});

  final DateTime startedAt;
  final DateTime? plannedEnd;
}

/// Paused: yellow-bg, «Дедлайн сдвинут: original → new».
class PausedDeadlineShiftBanner extends StageBannerData {
  const PausedDeadlineShiftBanner({this.originalEnd, this.newEnd});

  final DateTime? originalEnd;
  final DateTime? newEnd;
}

/// Review: purple gradient.
class ReviewBanner extends StageBannerData {
  const ReviewBanner();
}

/// Overdue: red, «Дедлайн истёк X дней назад».
class OverdueBanner extends StageBannerData {
  const OverdueBanner({required this.daysLate});

  final int daysLate;
}

/// LateStart: yellow, «Дата старта прошла, этап не запущен».
class LateStartBanner extends StageBannerData {
  const LateStartBanner({this.startedDue});

  final DateTime? startedDue;
}

/// Rejected: red box с reason + actor + attempt.
class RejectedBanner extends StageBannerData {
  const RejectedBanner({
    required this.reasonText,
    required this.actorName,
    required this.attempt,
  });

  final String reasonText;
  final String actorName;
  final int attempt;
}

/// Waiting (pending без подрядчика): красный «Не назначен».
class WaitingNoContractorBanner extends StageBannerData {
  const WaitingNoContractorBanner();
}

/// Done: тонкий зелёный «В срок».
class DoneBanner extends StageBannerData {
  const DoneBanner();
}
