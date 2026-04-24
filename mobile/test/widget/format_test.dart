import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/shared/utils/format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  Future<void> pumpWithLocale(
    WidgetTester tester,
    Locale locale,
    Widget Function(BuildContext) builder,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru'), Locale('en')],
        home: Builder(builder: (ctx) => builder(ctx)),
      ),
    );
  }

  testWidgets('Fmt.date RU → dd.MM.yyyy', (tester) async {
    String? out;
    await pumpWithLocale(tester, const Locale('ru'), (ctx) {
      out = Fmt.date(ctx, DateTime(2026, 4, 24));
      return const SizedBox();
    });
    expect(out, '24.04.2026');
  });

  testWidgets('Fmt.time → HH:mm', (tester) async {
    String? out;
    await pumpWithLocale(tester, const Locale('ru'), (ctx) {
      out = Fmt.time(ctx, DateTime(2026, 4, 24, 15, 7));
      return const SizedBox();
    });
    expect(out, '15:07');
  });

  testWidgets('Fmt.money RU — пробел-разделитель + рубль', (tester) async {
    String? out;
    await pumpWithLocale(tester, const Locale('ru'), (ctx) {
      out = Fmt.money(ctx, 125000000); // 1 250 000 ₽
      return const SizedBox();
    });
    expect(out!.contains('₽'), isTrue);
    expect(out!.contains('1'), isTrue);
    expect(out!.contains('250'), isTrue);
  });

  testWidgets('Fmt.relative — сегодня/вчера/N дн назад', (tester) async {
    String? today;
    String? yesterday;
    final now = DateTime.now();
    await pumpWithLocale(tester, const Locale('ru'), (ctx) {
      today = Fmt.relative(ctx, now);
      yesterday = Fmt.relative(ctx, now.subtract(const Duration(days: 1)));
      return const SizedBox();
    });
    expect(today, 'сегодня');
    expect(yesterday, 'вчера');
  });
}
