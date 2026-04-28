import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/presentation/_widgets/resolve_option_card.dart';

void main() {
  testWidgets('ResolveOptionCard рендерит title + subtitle и dispatch onTap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResolveOptionCard(
            icon: Icons.local_shipping_outlined,
            title: 'Довезли остаток',
            subtitle: 'Недостающие позиции доставлены',
            selected: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Довезли остаток'), findsOneWidget);
    expect(find.text('Недостающие позиции доставлены'), findsOneWidget);
    await tester.tap(find.byType(ResolveOptionCard));
    expect(tapped, isTrue);
  });

  testWidgets('Selected — цвет brand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResolveOptionCard(
            icon: Icons.payments_outlined,
            title: 'Возврат денег',
            subtitle: 'Скорректировать сумму',
            selected: true,
            onTap: () {},
          ),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Возврат денег'));
    expect(title.style?.color, isNotNull);
  });
}
