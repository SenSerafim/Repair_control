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
    );

    return base;
  }
}
