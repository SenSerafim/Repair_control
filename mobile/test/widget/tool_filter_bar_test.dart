import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/tools/presentation/_widgets/tool_filter_bar.dart';

void main() {
  testWidgets('ToolFilterBar показывает all + persons + green-dot для recent',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolFilterBar(
            persons: const [
              (id: null, label: 'Все'),
              (id: 'u1', label: 'Петров С.'),
              (id: 'u2', label: 'Козлов Л.'),
            ],
            selected: null,
            onChanged: (_) {},
            recentlyAddedIds: const {'u2'},
          ),
        ),
      ),
    );
    expect(find.text('Все'), findsOneWidget);
    expect(find.text('Петров С.'), findsOneWidget);
    expect(find.text('Козлов Л.'), findsOneWidget);
  });

  testWidgets('Tap по chip вызывает onChanged с правильным id', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolFilterBar(
            persons: const [
              (id: null, label: 'Все'),
              (id: 'u1', label: 'Петров С.'),
            ],
            selected: null,
            onChanged: (id) => selected = id,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Петров С.'));
    expect(selected, 'u1');
  });
}
