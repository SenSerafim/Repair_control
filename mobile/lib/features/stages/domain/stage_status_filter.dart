import '../presentation/stage_widgets.dart' show StageDisplayStatus;
import 'stage.dart';

/// Публичный фильтр статусов этапов — используется в двух местах:
/// 1) `stages_screen.dart` (полный экран этапов проекта),
/// 2) `console_screen.dart` (карусель этапов на главной консоли проекта).
///
/// Хранится в `domain/`, потому что инкапсулирует доменное правило
/// «какие этапы попадают в каждый фильтр» (через [StageDisplayStatus] и
/// признак `foremanIds.isEmpty`). Раньше энум был приватным в
/// `stages_screen.dart` (`_Filter`) — продублировался бы на консоли;
/// чтобы избежать рассинхрона между экранами, вынесен сюда.
enum StageStatusFilter {
  all,
  active,
  pending,
  paused,
  done,
  noContractor;

  /// Лейбл чипа на UI. Локализация RU (default), EN — задел.
  String get label => switch (this) {
    StageStatusFilter.all => 'Все',
    StageStatusFilter.active => 'В работе',
    StageStatusFilter.pending => 'Ожидает',
    StageStatusFilter.paused => 'На паузе',
    StageStatusFilter.done => 'Завершён',
    StageStatusFilter.noContractor => 'Без бригадира',
  };

  /// Подходит ли этап под этот фильтр.
  ///
  /// Использует [StageDisplayStatus.of] чтобы corretly мапить computed-
  /// состояния: `lateStart` идёт в `pending`, `overdue` — в `active`.
  bool match(Stage s, {DateTime? now}) {
    if (this == StageStatusFilter.noContractor) {
      return s.foremanIds.isEmpty;
    }
    if (this == StageStatusFilter.all) return true;
    final display = StageDisplayStatus.of(s, now: now);
    return switch (this) {
      StageStatusFilter.all => true,
      StageStatusFilter.active =>
        display == StageDisplayStatus.active ||
            display == StageDisplayStatus.overdue,
      StageStatusFilter.pending =>
        display == StageDisplayStatus.pending ||
            display == StageDisplayStatus.lateStart,
      StageStatusFilter.paused => display == StageDisplayStatus.paused,
      StageStatusFilter.done => display == StageDisplayStatus.done,
      StageStatusFilter.noContractor => s.foremanIds.isEmpty,
    };
  }
}
