import 'package:flutter/material.dart';

class AppColors {
  static const purple = Color(0xFF7B5EA7);
  static const purpleLight = Color(0xFFEDE4F7);
  static const blush = Color(0xFFFBF1F5);
  static const night = Color(0xFF1E1638);
  static const nightCard = Color(0xFF2C2250);
  static const ink = Color(0xFF2B2340);
  static const mint = Color(0xFFD6F2E3);
  static const sky = Color(0xFFD9E8FB);
  static const rose = Color(0xFFFBDDE4);
  static const lilac = Color(0xFFE6DAF8);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple),
      scaffoldBackgroundColor: AppColors.blush,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.purpleLight,
      ),
    );
  }
}