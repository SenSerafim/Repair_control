import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/steps/presentation/_widgets/step_mini_menu.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) =>
      t.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  group('StepMiniMenu — NEWFIX TZ-фронт §11.5', () {
    testWidgets(
      'показывает «Добавить материал в заявку» когда onAddMaterial не null',
      (t) async {
        var called = false;
        await pump(
          t,
          StepMiniMenu(
            onAddSubstep: null,
            onAddPhoto: null,
            onAddMaterial: () => called = true,
            onAskQuestion: null,
            onSendForApproval: null,
            onExtraWork: null,
          ),
        );
        expect(find.text('Добавить материал в заявку'), findsOneWidget);
        await t.tap(find.text('Добавить материал в заявку'));
        await t.pumpAndSettle();
        expect(called, isTrue);
      },
    );

    testWidgets('скрывает пункт когда onAddMaterial = null', (t) async {
      await pump(
        t,
        const StepMiniMenu(
          onAddSubstep: null,
          onAddPhoto: null,
          onAddMaterial: null,
          onAskQuestion: null,
          onSendForApproval: null,
          onExtraWork: null,
        ),
      );
      expect(find.text('Добавить материал в заявку'), findsNothing);
    });

    testWidgets('пункт отображается между «Добавить фото» и «Задать вопрос»', (
      t,
    ) async {
      await pump(
        t,
        StepMiniMenu(
          onAddSubstep: null,
          onAddPhoto: () {},
          onAddMaterial: () {},
          onAskQuestion: () {},
          onSendForApproval: null,
          onExtraWork: null,
        ),
      );
      final photoY = t.getTopLeft(find.text('Добавить фото')).dy;
      final materialY = t
          .getTopLeft(find.text('Добавить материал в заявку'))
          .dy;
      final questionY = t.getTopLeft(find.text('Задать вопрос')).dy;
      expect(photoY, lessThan(materialY));
      expect(materialY, lessThan(questionY));
    });
  });
}
