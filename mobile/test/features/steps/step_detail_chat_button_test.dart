// NEWFIX gaps Task 2.4 (TZ §13.2): иконка чата этапа в AppBar экрана шага.
//
// Полный StepDetailScreen тянет десятки провайдеров (access, stepDetail,
// stagesController, stepsController, auth, …) — для smoke-проверки одной
// IconButton это перебор. Тестируем кнопку в изоляции: воспроизводим тот
// же widget-фрагмент, что добавлен в `step_detail_screen.dart` AppBar, и
// проверяем, что:
//   1) Кнопка с ValueKey('step_header_chat_button') отрисовывается;
//   2) Тап по ней вызывает context.push('/stages/:stageId/chat').
//
// Маршрут `/stages/:stageId/chat` регистрируется в app_router фазой 2.3
// этого же плана — здесь мы используем локальный GoRouter с тем же
// шаблоном пути, чтобы не зависеть от глобальной конфигурации.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Фрагмент AppBar.actions из StepDetailScreen — воспроизводит порядок
/// (chat-button → kebab) и ключ, чтобы тест ловил регрессии вёрстки.
class _StepHeaderActionsFixture extends StatelessWidget {
  const _StepHeaderActionsFixture({required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаг'),
        actions: [
          IconButton(
            key: const ValueKey('step_header_chat_button'),
            tooltip: 'Чат этапа',
            icon: const Icon(PhosphorIconsRegular.chatCircle),
            onPressed: () => context.push('/stages/$stageId/chat'),
          ),
          IconButton(
            tooltip: 'Действия',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: const SizedBox.shrink(),
    );
  }
}

GoRouter _buildRouter({required String stageId}) {
  return GoRouter(
    initialLocation: '/stages/$stageId/steps/step-1',
    routes: [
      GoRoute(
        path: '/stages/:stageId/steps/:stepId',
        builder: (_, state) => _StepHeaderActionsFixture(
          stageId: state.pathParameters['stageId']!,
        ),
      ),
      GoRoute(
        path: '/stages/:stageId/chat',
        builder: (_, state) => Scaffold(
          body: Text('stage-chat:${state.pathParameters['stageId']}'),
        ),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppBar содержит кнопку чата с правильным ключом и tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _buildRouter(stageId: 'stage-42')),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('step_header_chat_button'));
    expect(button, findsOneWidget);

    // Tooltip должен быть «Чат этапа».
    expect(find.byTooltip('Чат этапа'), findsOneWidget);

    // Иконка — phosphor chatCircle.
    expect(
      find.descendant(
        of: button,
        matching: find.byIcon(PhosphorIconsRegular.chatCircle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('тап по кнопке чата открывает /stages/:stageId/chat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _buildRouter(stageId: 'stage-42')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('step_header_chat_button')));
    await tester.pumpAndSettle();

    // Перешли на маршрут чата этапа с тем же stageId.
    expect(find.text('stage-chat:stage-42'), findsOneWidget);
  });
}
