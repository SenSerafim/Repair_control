import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Сценарий ROAD_TO_100 §3.2.5:
///   эмиссия FCM payload → DeepLinkRouter → корректный экран для каждого
///   из 6 типов deep-link (approval/stage/payment/chat/material/document).
///
/// PENDING: требует program-driven эмиссию `RemoteMessage` через
/// `FirebaseMessagingPlatform` test-binding + staging-бэк для resolved-целей.
///
/// Unit-тест на DeepLinkRouter уже покрывает 6 payload типов:
///   test/s17_parse_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'push deep-links — PENDING FCM driver mock',
    (tester) async {},
    skip: true,
  );
}
