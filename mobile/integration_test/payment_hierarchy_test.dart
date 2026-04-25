import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Сценарий ROAD_TO_100 §3.2.3:
///   create-advance (заказчик) → confirm (бригадир) → distribute 3×master →
///   dispute (master) → resolve (заказчик).
///
/// Покрывает иерархию `parentPaymentId` и обновление BudgetCalculator.
///
/// PENDING: требует staging-бэк, 5 тест-аккаунтов (1 заказчик + 1 foreman
/// + 3 master) и программный driver для переключения логина.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'payment hierarchy — PENDING staging infra',
    (tester) async {
      // Сценарий бэкенд-e2e уже зелёный:
      //   backend/apps/api/test/payments-materials.e2e-spec.ts
      // Mobile integration воспроизводит его через UI.
    },
    skip: true,
  );
}
