import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:repair_control/core/theme/tokens.dart';
import 'package:repair_control/features/approvals/domain/approval.dart';
import 'package:repair_control/features/approvals/presentation/approval_widgets.dart';

Approval _approval({
  required ApprovalScope scope,
  required ApprovalStatus status,
  int attempt = 1,
  Map<String, dynamic>? payload,
}) =>
    Approval(
      id: 'a1',
      scope: scope,
      projectId: 'p1',
      requestedById: 'u1',
      addresseeId: 'u2',
      status: status,
      attemptNumber: attempt,
      payload: payload ?? const {},
      createdAt: DateTime(2026, 4, 14, 14, 32),
      updatedAt: DateTime(2026, 4, 14, 14, 32),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      locale: const Locale('ru'),
      home: Scaffold(
        body: SizedBox(width: 360, child: child),
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  group('ApprovalCard', () {
    testWidgets('step — рендерит scope-badge "Шаг"', (tester) async {
      await tester.pumpWidget(_wrap(ApprovalCard(
        approval: _approval(
          scope: ApprovalScope.step,
          status: ApprovalStatus.pending,
        ),
        onTap: () {},
      )));
      expect(find.text('Шаг'), findsWidgets);
    });

    testWidgets('stageAccept — выделенная карточка с brand-обводкой',
        (tester) async {
      await tester.pumpWidget(_wrap(ApprovalCard(
        approval: _approval(
          scope: ApprovalScope.stageAccept,
          status: ApprovalStatus.pending,
        ),
        onTap: () {},
      )));
      expect(find.text('Приёмка этапа'), findsWidgets);

      // Корневой Container карточки имеет brand-обводку 1.5px.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final highlight = containers.firstWhere(
        (c) {
          final d = c.decoration;
          if (d is! BoxDecoration) return false;
          final border = d.border;
          if (border is! Border) return false;
          return border.top.color == AppColors.brand && border.top.width == 1.5;
        },
      );
      expect(highlight, isNotNull);
    });

    testWidgets('attempt > 1 — показывает «Попытка N»', (tester) async {
      await tester.pumpWidget(_wrap(ApprovalCard(
        approval: _approval(
          scope: ApprovalScope.step,
          status: ApprovalStatus.pending,
          attempt: 3,
        ),
        onTap: () {},
      )));
      expect(find.text('Попытка 3'), findsOneWidget);
    });

    testWidgets('history — показывает status-badge', (tester) async {
      await tester.pumpWidget(_wrap(ApprovalCard(
        approval: _approval(
          scope: ApprovalScope.step,
          status: ApprovalStatus.approved,
        ),
        onTap: () {},
      )));
      expect(find.text('Одобрено'), findsOneWidget);
    });

    testWidgets('onTap срабатывает', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(ApprovalCard(
        approval: _approval(
          scope: ApprovalScope.step,
          status: ApprovalStatus.pending,
        ),
        onTap: () => tapped = true,
      )));
      await tester.tap(find.byType(ApprovalCard));
      expect(tapped, isTrue);
    });
  });
}
