import '../../../shared/widgets/status_pill.dart';
import 'stage.dart';

/// Светофор-ветки этапа по ТЗ §2.4. Зеркало `progressCache.semaphoreCache`
/// на бэкенде. Клиент должен уметь пересчитывать локально для оптимистичных
/// апдейтов и для случаев когда `progressCache` устарел.
///
/// 5 цветовых веток + 1 computed (lateStart рассматривается как red).
enum TrafficLight {
  /// Этап завершён или активный без просрочек / приёмки в процессе.
  green,

  /// Этап на паузе (любой причины).
  yellow,

  /// `plannedEnd` уже прошёл, но этап не done; либо `plannedStart` прошёл,
  /// а `startedAt` не выставлен (lateStart) — критичное отставание.
  red,

  /// Этап на приёмке (sent_to_review). Голубая ветка ТЗ — «ожидает действия
  /// заказчика».
  blue,

  /// Этап в `pending` со штатным плановым стартом — серая «в плане».
  /// Эквивалентно `Semaphore.plan` из дизайна.
  grey;

  Semaphore get semaphore => switch (this) {
        TrafficLight.green => Semaphore.green,
        TrafficLight.yellow => Semaphore.yellow,
        TrafficLight.red => Semaphore.red,
        TrafficLight.blue => Semaphore.blue,
        TrafficLight.grey => Semaphore.plan,
      };

  String get bannerTitle => switch (this) {
        TrafficLight.green => 'По графику',
        TrafficLight.yellow => 'Этап на паузе',
        TrafficLight.red => 'Просрочен',
        TrafficLight.blue => 'Ожидает приёмки',
        TrafficLight.grey => 'В плане',
      };

  String get bannerSubtitle => switch (this) {
        TrafficLight.green =>
          'Темп нормальный — продолжайте работу по плану.',
        TrafficLight.yellow =>
          'Дедлайн сдвинется на длительность паузы автоматически.',
        TrafficLight.red =>
          'Дедлайн прошёл. Запросите перенос или ускорьте темп.',
        TrafficLight.blue =>
          'Заказчик увидит этап в согласованиях и подтвердит/отклонит приёмку.',
        TrafficLight.grey =>
          'Этап ещё не запущен. Бригадир нажмёт «Запустить» когда придёт время.',
      };
}

/// Полная формула из ТЗ §2.4 + Gaps §2 (lateStart, корректировка после паузы).
///
/// Приоритет проверок (сверху вниз):
/// 1. `done` → green (завершённый этап всегда зелёный, даже если был просрочен).
/// 2. `rejected` → red (отказ заказчика).
/// 3. `paused` → yellow (любой override).
/// 4. `review` → blue (на приёмке).
/// 5. `pending` + plannedStart прошёл (lateStart) → red.
/// 6. plannedEnd прошёл и status != done → red (overdue).
/// 7. `active` без overdue → green.
/// 8. `pending` без lateStart → grey.
TrafficLight computeTrafficLight(Stage stage, {DateTime? now}) {
  final when = now ?? DateTime.now();

  if (stage.status == StageStatus.done) return TrafficLight.green;
  if (stage.status == StageStatus.rejected) return TrafficLight.red;
  if (stage.status == StageStatus.paused) return TrafficLight.yellow;
  if (stage.status == StageStatus.review) return TrafficLight.blue;

  // lateStart — pending + plannedStart в прошлом.
  if (stage.isLateStart(when)) return TrafficLight.red;

  // overdue — plannedEnd в прошлом, этап ещё не done.
  if (stage.plannedEnd != null && stage.plannedEnd!.isBefore(when)) {
    return TrafficLight.red;
  }

  if (stage.status == StageStatus.active) return TrafficLight.green;

  // Остался pending без late-start — серая «в плане» ветка.
  return TrafficLight.grey;
}

/// Агрегатор по этапам для проекта. Берёт «худшую» ветку среди этапов:
/// red > yellow > blue > green > grey. Игнорирует rejected/done в смысле
/// определения приоритета (они не блокируют общую картину).
TrafficLight computeProjectTrafficLight(
  Iterable<Stage> stages, {
  DateTime? now,
}) {
  if (stages.isEmpty) return TrafficLight.grey;
  final lights = stages.map((s) => computeTrafficLight(s, now: now)).toList();

  // Все done → green; все rejected → red.
  if (lights.every((l) => l == TrafficLight.green) &&
      stages.every((s) => s.status == StageStatus.done)) {
    return TrafficLight.green;
  }

  bool has(TrafficLight l) => lights.contains(l);
  if (has(TrafficLight.red)) return TrafficLight.red;
  if (has(TrafficLight.yellow)) return TrafficLight.yellow;
  if (has(TrafficLight.blue)) return TrafficLight.blue;
  if (has(TrafficLight.green)) return TrafficLight.green;
  return TrafficLight.grey;
}
