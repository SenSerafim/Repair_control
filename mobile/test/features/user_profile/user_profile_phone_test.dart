// NEWFIX gaps Task 1.1: проверяет, что кнопка «Позвонить» на профиле
// сотрудника вызывает launchUrl с tel:<phone>.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/user_profile/data/user_profile_repository.dart';
import 'package:repair_control/features/user_profile/domain/user_profile_aggregate.dart';
import 'package:repair_control/features/user_profile/presentation/user_profile_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _CapturingUrlLauncher extends UrlLauncherPlatform {
  String? capturedUrl;

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    capturedUrl = url;
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    capturedUrl = url;
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

UserProfileAggregate _buildAggregate({required String phone}) {
  return UserProfileAggregate(
    user: UserProfileHeader(
      id: 'u1',
      firstName: 'Иван',
      lastName: 'Петров',
      phone: phone,
      activeRole: 'master',
    ),
    objects: const [],
    monthStats: const UserProfileMonthStats(stepsDoneThisMonth: 0),
    tools: const [],
    reclamations: const UserProfileReclamations(completed: 0, total: 0),
    payouts: const UserProfilePayouts(
      visible: false,
      monthTotal: 0,
      byProject: [],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('тап по кнопке «Позвонить» вызывает launchUrl с tel:<phone>', (
    tester,
  ) async {
    final mock = _CapturingUrlLauncher();
    UrlLauncherPlatform.instance = mock;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileAggregateProvider(
            'u1',
          ).overrideWith((ref) async => _buildAggregate(phone: '+79991112233')),
        ],
        child: const MaterialApp(home: UserProfileScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('user_profile_phone_button'));
    expect(button, findsOneWidget);

    final iconButton = tester.widget<IconButton>(button);
    expect(iconButton.onPressed, isNotNull);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(mock.capturedUrl, 'tel:+79991112233');
  });

  testWidgets('кнопка «Позвонить» disabled при пустом phone', (tester) async {
    final mock = _CapturingUrlLauncher();
    UrlLauncherPlatform.instance = mock;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileAggregateProvider(
            'u1',
          ).overrideWith((ref) async => _buildAggregate(phone: '')),
        ],
        child: const MaterialApp(home: UserProfileScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('user_profile_phone_button'));
    expect(button, findsOneWidget);

    final iconButton = tester.widget<IconButton>(button);
    expect(iconButton.onPressed, isNull);
    expect(mock.capturedUrl, isNull);
  });
}
