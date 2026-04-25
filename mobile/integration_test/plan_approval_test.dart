import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Сценарий ROAD_TO_100 §3.2.2:
///   Foreman submits план → Customer approves → Foreman может стартовать.
///
/// PENDING: требует реальный staging-бэк + 2 тест-аккаунта с
/// предустановленными проектами (см. backend/prisma/seed.ts) +
/// программный driver для переключения активного пользователя.
///
/// Текущий smoke-тест помечен skip — будет реализован после поднятия
/// staging-environment с автоматическими фикстурами.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'plan approval flow — PENDING staging infra',
    (tester) async {
      // Полный сценарий:
      //   1. Login as foreman_test → submit plan-approval.
      //   2. Logout, login as customer_test → approve в списке pending.
      //   3. Logout, login as foreman_test → нажать Start (раньше disabled).
    },
    skip: true,
  );
}
