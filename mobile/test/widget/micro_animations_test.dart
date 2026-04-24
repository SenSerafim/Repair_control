import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/app_micro_animations.dart';

void main() {
  testWidgets('AppAnimatedSendButton — send → check при sent=true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAnimatedSendButton(onTap: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAnimatedSendButton(onTap: () {}, sent: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('AppUploadProgressBar рисуется', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppUploadProgressBar(progress: 0.5),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
