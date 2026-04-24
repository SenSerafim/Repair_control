import 'package:flutter/material.dart';

import 'tokens.dart';

/// Типографика — Manrope 500/600/700/800/900.
/// Иерархия из `design/Кластер *.html`.
class AppTextStyles {
  const AppTextStyles._();

  static const String _family = 'Manrope';

  static const TextStyle screenTitle = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppColors.n800,
    height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.n800,
    height: 1.25,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.n800,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.n700,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.n700,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.n600,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.n500,
    height: 1.4,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.n400,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle tiny = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.n400,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.n0,
  );

  static const TextStyle buttonSm = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.n0,
  );
}
