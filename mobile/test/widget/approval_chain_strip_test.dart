import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/selfpurchase/presentation/_widgets/approval_chain_strip.dart';

void main() {
  testWidgets('ApprovalChainStrip 2-step (foreman → customer) рендерится',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApprovalChainStrip(
            steps: [
              ChainStep(
                label: 'Вы (бригадир)',
                state: ChainStepState.current,
                tone: ChainStepTone.purple,
              ),
              ChainStep(
                label: 'Заказчик',
                state: ChainStepState.pending,
                tone: ChainStepTone.customer,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('ЦЕПОЧКА ОДОБРЕНИЯ'), findsOneWidget);
    expect(find.text('Вы (бригадир)'), findsOneWidget);
    expect(find.text('Заказчик'), findsOneWidget);
  });

  testWidgets('ApprovalChainStrip 3-step (master → foreman → customer)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApprovalChainStrip(
            footnote: 'После вашего подтверждения уйдёт заказчику',
            steps: [
              ChainStep(
                label: 'Мастер',
                state: ChainStepState.done,
                tone: ChainStepTone.purple,
              ),
              ChainStep(
                label: 'Вы (бригадир)',
                state: ChainStepState.current,
                tone: ChainStepTone.purple,
              ),
              ChainStep(
                label: 'Заказчик',
                state: ChainStepState.pending,
                tone: ChainStepTone.customer,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Мастер'), findsOneWidget);
    expect(find.text('Вы (бригадир)'), findsOneWidget);
    expect(find.text('Заказчик'), findsOneWidget);
    expect(find.text('После вашего подтверждения уйдёт заказчику'),
        findsOneWidget);
  });
}
