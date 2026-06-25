import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'text_styles.dart';
import 'tokens.dart';

/// Глобальная ThemeData — базируется на AppColors/AppTextStyles.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brand,
      onPrimary: AppColors.n0,
      secondary: AppColors.brandDark,
      onSecondary: AppColors.n0,
      error: AppColors.redDot,
      onError: AppColors.n0,
      surface: AppColors.n0,
      onSurface: AppColors.n800,
      surfaceContainerHighest: AppColors.n100,
      outline: AppColors.n200,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.n50,
      fontFamily: 'Manrope',
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.screenTitle,
        headlineMedium: AppTextStyles.h1,
        titleLarge: AppTextStyles.h2,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.buttonSm,
        labelSmall: AppTextStyles.micro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.n0,
        foregroundColor: AppColors.n800,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h1,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.n0,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.n200,
        space: 1,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.n600, size: 20),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.n100;
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return AppColors.n100;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AppColors.brand, width: 1.5);
          }
          return const BorderSide(color: AppColors.n200);
        }),
        checkmarkColor: AppColors.n0,
        labelStyle: TextStyle(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.n400;
            if (states.contains(WidgetState.selected)) return AppColors.n0;
            return AppColors.n700;
          }),
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: TextStyle(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.n400;
            if (states.contains(WidgetState.selected)) return AppColors.n0;
            return AppColors.n700;
          }),
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      // Серафим 08.06.2026: текст в полях ввода должен быть чёрный/тёмный,
      // а не цвета подсказки. По дефолту TextField берёт subtitle1.color =
      // n400 (как у hint) → пользователь не видит что печатает. Жёстко
      // задаём n800 для value и n400 для hint.
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.n400,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(color: AppColors.n600),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.n800,
        displayColor: AppColors.n800,
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.brand,
      onPrimary: AppColorsDark.n900,
      secondary: AppColorsDark.brandDark,
      onSecondary: AppColorsDark.n900,
      error: AppColorsDark.redDot,
      onError: AppColorsDark.n0,
      surface: AppColorsDark.n50,
      onSurface: AppColorsDark.n800,
      surfaceContainerHighest: AppColorsDark.n100,
      outline: AppColorsDark.n200,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorsDark.n0,
      fontFamily: 'Manrope',
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.screenTitle.copyWith(
          color: AppColorsDark.n800,
        ),
        headlineMedium: AppTextStyles.h1.copyWith(color: AppColorsDark.n800),
        titleLarge: AppTextStyles.h2.copyWith(color: AppColorsDark.n800),
        titleMedium: AppTextStyles.subtitle.copyWith(color: AppColorsDark.n800),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColorsDark.n700),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColorsDark.n700,
        ),
        bodySmall: AppTextStyles.caption.copyWith(color: AppColorsDark.n600),
        labelLarge: AppTextStyles.button.copyWith(color: AppColorsDark.n900),
        labelMedium: AppTextStyles.buttonSm.copyWith(color: AppColorsDark.n900),
        labelSmall: AppTextStyles.micro.copyWith(color: AppColorsDark.n500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsDark.n50,
        foregroundColor: AppColorsDark.n800,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.n50,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.n200,
        space: 1,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColorsDark.n600, size: 20),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColorsDark.n100;
          if (states.contains(WidgetState.selected)) return AppColorsDark.brand;
          return AppColorsDark.n100;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AppColorsDark.brand, width: 1.5);
          }
          return const BorderSide(color: AppColorsDark.n200);
        }),
        checkmarkColor: AppColorsDark.n900,
        labelStyle: TextStyle(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColorsDark.n400;
            }
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark.n900;
            }
            return AppColorsDark.n700;
          }),
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: TextStyle(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColorsDark.n400;
            }
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark.n900;
            }
            return AppColorsDark.n700;
          }),
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
