import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Сценарий ROAD_TO_100 §3.2.4:
///   offline → mark step done → online → action drained без ошибки.
///
/// PENDING: требует Connectivity-mock в integration-driver (плагин
/// `connectivity_plus_platform_interface` поддерживает override) +
/// staging-бэк для финальной верификации шага.
///
/// Unit-тест на OfflineQueue logic уже зелёный:
///   test/offline_queue_kinds_test.dart, test/offline_conflict_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline sync — PENDING staging infra + connectivity mock',
    (tester) async {},
    skip: true,
  );
}
