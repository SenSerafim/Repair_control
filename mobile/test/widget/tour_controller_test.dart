import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/storage/secure_storage.dart';
import 'package:repair_control/features/auth/application/auth_controller.dart'
    show secureStorageProvider;
import 'package:repair_control/features/onboarding/application/tour_controller.dart';
import 'package:repair_control/features/onboarding/data/tour_script.dart';

/// In-memory fake над `SecureStorage` — наследуется, чтобы тип сошёлся
/// в provider-override. Для тура нужны только два метода.
class _FakeSecureStorage extends SecureStorage {
  _FakeSecureStorage();
  bool tutorialCompleted = false;

  @override
  Future<bool> readTutorialCompleted() async => tutorialCompleted;
  @override
  Future<void> writeTutorialCompleted({required bool value}) async {
    tutorialCompleted = value;
  }
}

void main() {
  group('TourController', () {
    late ProviderContainer container;
    late _FakeSecureStorage storage;

    setUp(() {
      storage = _FakeSecureStorage();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
    });

    test('starts at index 0', () {
      final state = container.read(tourControllerProvider);
      expect(state.index, 0);
      expect(state.isFirst, isTrue);
      expect(state.isLast, isFalse);
    });

    test('advance moves to next step', () {
      final ctrl = container.read(tourControllerProvider.notifier);
      ctrl.advance();
      expect(container.read(tourControllerProvider).index, 1);
    });

    test('back returns to previous step', () {
      final ctrl = container.read(tourControllerProvider.notifier);
      ctrl
        ..advance()
        ..advance()
        ..back();
      expect(container.read(tourControllerProvider).index, 1);
    });

    test('back on first step is no-op', () {
      final ctrl = container.read(tourControllerProvider.notifier);
      ctrl.back();
      expect(container.read(tourControllerProvider).index, 0);
    });

    test('advanceToScreen jumps forward to matching step', () {
      final ctrl = container.read(tourControllerProvider.notifier);
      ctrl.advanceToScreen('approvals');
      final state = container.read(tourControllerProvider);
      expect(state.current.screenKey, 'approvals');
    });

    test('advanceToScreen does not jump backward', () {
      final ctrl = container.read(tourControllerProvider.notifier);
      ctrl
        ..advance()
        ..advance()
        ..advance();
      final before = container.read(tourControllerProvider).index;
      ctrl.advanceToScreen('console'); // earlier screen
      expect(container.read(tourControllerProvider).index, before);
    });

    test('complete writes tutorial.completed=true', () async {
      final ctrl = container.read(tourControllerProvider.notifier);
      await ctrl.complete();
      expect(storage.tutorialCompleted, isTrue);
      expect(container.read(tourControllerProvider).isLast, isTrue);
    });

    test('cancel writes tutorial.completed=true', () async {
      final ctrl = container.read(tourControllerProvider.notifier);
      await ctrl.cancel();
      expect(storage.tutorialCompleted, isTrue);
    });

    test('advance on last step calls complete', () async {
      final ctrl = container.read(tourControllerProvider.notifier);
      // Прыгнуть на последний шаг.
      for (var i = 0; i < TourScript.steps.length - 1; i++) {
        ctrl.advance();
      }
      expect(container.read(tourControllerProvider).isLast, isTrue);
      ctrl.advance(); // на последнем — complete()
      // Дать microtask`ам отработать.
      await Future<void>.delayed(Duration.zero);
      expect(storage.tutorialCompleted, isTrue);
    });
  });

  group('TourScript', () {
    test('contains exactly 14 steps', () {
      expect(TourScript.steps.length, 14);
    });

    test('first step is welcome', () {
      expect(TourScript.steps.first.id, 'welcome');
      expect(TourScript.steps.first.screenKey, 'welcome');
    });

    test('last step is completion', () {
      expect(TourScript.steps.last.id, 'completion');
      expect(TourScript.steps.last.screenKey, 'completion');
    });

    test('all step ids are unique', () {
      final ids = TourScript.steps.map((s) => s.id).toSet();
      expect(ids.length, TourScript.steps.length);
    });
  });
}


