import 'package:flutter/material.dart';
import 'package:sudoku/theme/app_colors.dart';

/// 应用主题
class AppTheme {
  /// 明亮主题
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      bodySmall: TextStyle(fontSize: 14, color: Colors.black54),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightBackground,
      error: AppColors.error,
      onSecondary: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.buttonPrimary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  /// 暗黑主题
  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
      bodySmall: TextStyle(fontSize: 14, color: Colors.white70),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkBackground,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.darkButtonPrimary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
}
