import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/presentation/_widgets/material_lifecycle_timeline.dart';

void main() {
  testWidgets('MaterialLifecycleTimeline рендерит шаги с разным состоянием',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MaterialLifecycleTimeline(
            steps: [
              LifecycleStep(
                title: 'Создана',
                state: LifecycleStepState.done,
                dateLabel: '01.02.2025',
                immutable: true,
              ),
              LifecycleStep(
                title: 'Куплено: 20 из 30',
                state: LifecycleStepState.active,
                dateLabel: '10.02.2025',
              ),
              LifecycleStep(
                title: 'Доставлено',
                state: LifecycleStepState.pending,
                dateLabel: '—',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Создана'), findsOneWidget);
    expect(find.text('01.02.2025 (неизменяемая)'), findsOneWidget);
    expect(find.text('Куплено: 20 из 30'), findsOneWidget);
    expect(find.text('Доставлено'), findsOneWidget);
  });
}
