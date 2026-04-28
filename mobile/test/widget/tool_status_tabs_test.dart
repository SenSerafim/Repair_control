import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/tools/presentation/_widgets/tool_status_tabs.dart';

void main() {
  testWidgets('ToolStatusTabs показывает counts в каждой вкладке',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolStatusTabs(
            selected: ToolStatusTab.all,
            onChanged: (_) {},
            allCount: 5,
            issuedCount: 3,
            warehouseCount: 2,
          ),
        ),
      ),
    );
    expect(find.text('Все (5)'), findsOneWidget);
    expect(find.text('Выданные (3)'), findsOneWidget);
    expect(find.text('На складе (2)'), findsOneWidget);
  });

  testWidgets('Tap по табу вызывает onChanged', (tester) async {
    ToolStatusTab selected = ToolStatusTab.all;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => ToolStatusTabs(
              selected: selected,
              onChanged: (t) => setState(() => selected = t),
              allCount: 5,
              issuedCount: 3,
              warehouseCount: 2,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Выданные (3)'));
    await tester.pump();
    expect(selected, ToolStatusTab.issued);
  });
}
