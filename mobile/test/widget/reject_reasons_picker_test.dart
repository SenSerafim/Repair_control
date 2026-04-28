import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/selfpurchase/presentation/_widgets/reject_reasons_picker.dart';

void main() {
  testWidgets('RejectReasonsPicker рендерит 4 причины и обрабатывает выбор',
      (tester) async {
    RejectReason picked = RejectReason.notAgreed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => RejectReasonsPicker(
              selected: picked,
              onChanged: (r) => setState(() => picked = r),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Не согласована закупка'), findsOneWidget);
    expect(find.text('Завышена цена'), findsOneWidget);
    expect(find.text('Нет чека / плохое фото'), findsOneWidget);
    expect(find.text('Другая причина'), findsOneWidget);

    await tester.tap(find.text('Завышена цена'));
    await tester.pump();
    expect(picked, RejectReason.overpriced);
  });

  test('RejectReason.apiValue для каждого варианта корректен', () {
    expect(RejectReason.notAgreed.apiValue, 'not_agreed');
    expect(RejectReason.overpriced.apiValue, 'overpriced');
    expect(RejectReason.noReceipt.apiValue, 'no_receipt');
    expect(RejectReason.other.apiValue, 'other');
  });
}
