import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart' show secureStorageProvider;
import '../data/tour_script.dart';
import '../domain/tour_step.dart';

/// Состояние демо-тура. Активен только в `/tour` route; у любого экрана
/// вне тура `TourOverlay` не рендерится.
class TourState {
  const TourState({required this.index});

  /// Индекс текущего шага в [TourScript.steps].
  final int index;

  TourStep get current => TourScript.steps[index];
  bool get isLast => index >= TourScript.steps.length - 1;
  bool get isFirst => index == 0;

  TourState copyWith({int? index}) => TourState(index: index ?? this.index);
}

/// Контроллер демо-тура. Хранит текущий шаг, умеет двигаться вперёд/назад,
/// отмечать тур пройденным в `SecureStorage`. Сам не делает GoRouter-переходы —
/// `TourShell` слушает state и реагирует.
class TourController extends Notifier<TourState> {
  @override
  TourState build() {
    return const TourState(index: 0);
  }

  /// Перейти к следующему шагу. На последнем — вызвать [complete].
  void advance() {
    if (state.isLast) {
      complete();
      return;
    }
    state = state.copyWith(index: state.index + 1);
  }

  /// Вернуться к предыдущему шагу (для кнопки «Назад» в bubble).
  /// На первом шаге — no-op.
  void back() {
    if (state.isFirst) return;
    state = state.copyWith(index: state.index - 1);
  }

  /// Прервать тур — пользователь подтвердил «Пропустить». Эквивалентно
  /// прохождению до конца: ставит `tutorial.completed = true`, чтобы
  /// тур не показывался при следующем запуске. Если хочется пройти
  /// заново — кнопка в Profile сбрасывает флаг.
  Future<void> cancel() async {
    await ref.read(tutorialCompletedProvider.notifier).markCompleted();
  }

  /// Пройти ровно к шагу с указанным [screenKey]. Используется, когда
  /// пользователь сам тапнул по подсвеченной кнопке и навигация ушла
  /// вперёд (например, с ConsoleScreen на StagesScreen) — `TourShell`
  /// или `TourAnchor`-handler вызывает `advanceToScreen('stages')`.
  void advanceToScreen(String screenKey) {
    final next = TourScript.steps.indexWhere(
      (s) => s.screenKey == screenKey,
      state.index,
    );
    if (next == -1 || next <= state.index) return;
    state = state.copyWith(index: next);
  }

  /// Закончить тур: проставить флаг и не показывать в будущем.
  /// `TourShell` отдельно делает GoRouter-переход на `/projects`.
  Future<void> complete() async {
    await ref.read(tutorialCompletedProvider.notifier).markCompleted();
    if (!state.isLast) {
      state = state.copyWith(index: TourScript.steps.length - 1);
    }
  }
}

/// `NotifierProvider` без `family` — тур всегда один. Override-ится только
/// внутри `/tour` `ProviderScope`, за его пределами доступа к нему нет.
final tourControllerProvider =
    NotifierProvider<TourController, TourState>(TourController.new);

/// Текущее значение «тур пройден» — синхронно доступно из `redirect`
/// GoRouter-а. `null` означает «ещё не загрузили из SecureStorage» —
/// в этом случае редирект просто ждёт следующего тика. Hydrate
/// асинхронно при первом обращении.
class TutorialCompletedNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    Future.microtask(_hydrate);
    return null;
  }

  Future<void> _hydrate() async {
    final v = await ref.read(secureStorageProvider).readTutorialCompleted();
    state = v;
  }

  /// Вызывается из `TourController.complete` — после прохождения тура
  /// пользователь больше не должен попадать в `/tour`.
  Future<void> markCompleted() async {
    await ref
        .read(secureStorageProvider)
        .writeTutorialCompleted(value: true);
    state = true;
  }

  /// «Пройти обучение заново» из Profile — сбрасывает флаг.
  Future<void> reset() async {
    await ref
        .read(secureStorageProvider)
        .writeTutorialCompleted(value: false);
    state = false;
  }
}

final tutorialCompletedProvider =
    NotifierProvider<TutorialCompletedNotifier, bool?>(
  TutorialCompletedNotifier.new,
);
