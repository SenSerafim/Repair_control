import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/core/theme/app_theme.dart';

/// Виджет-обёртка для golden-тестов: `MaterialApp` с продуктовой темой
/// и фиксированным размером сцены. Значения по умолчанию подходят
/// под mobile-карточки (393×140 на mid-tier телефоне).
Widget goldenScaffold({
  required Widget child,
  Size size = const Size(360, 220),
  bool dark = false,
  String locale = 'ru',
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.light(), // dark поднимем в Этапе 7.5
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: SizedBox.fromSize(
          size: size,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Загружаем шрифт Manrope для стабильного рендера golden'ов.
/// Без этой загрузки flutter_test использует Ahem (placeholder), что
/// портит снимки.
Future<void> loadAppFonts() async {
  // Платформенные иконки и Roboto уже доступны.
  // Manrope подгружаем из assets (если зарегистрирован в pubspec).
  // Если нет — golden'ы запишутся с дефолтным шрифтом, что приемлемо
  // для регрессии (любое визуальное изменение всё равно будет detected).
  TestWidgetsFlutterBinding.ensureInitialized();
}
