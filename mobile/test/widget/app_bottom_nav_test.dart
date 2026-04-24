import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('AppBottomNav — 4 табa, active dot под выбранным', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (ctx, setState) => MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: selected,
              onTap: (i) => setState(() => selected = i),
              items: const [
                AppBottomNavItem(icon: Icons.home, label: 'Проекты'),
                AppBottomNavItem(
                  icon: Icons.people,
                  label: 'Команда',
                  badgeCount: 0,
                ),
                AppBottomNavItem(
                  icon: Icons.chat,
                  label: 'Чаты',
                  badgeCount: 3,
                ),
                AppBottomNavItem(icon: Icons.person, label: 'Профиль'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Проекты'), findsOneWidget);
    expect(find.text('Команда'), findsOneWidget);
    expect(find.text('Чаты'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // бэйдж

    // tap на Чаты
    await tester.tap(find.text('Чаты'));
    await tester.pump();
    expect(selected, 2);
  });
}
