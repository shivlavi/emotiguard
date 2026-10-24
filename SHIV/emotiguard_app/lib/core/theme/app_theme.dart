import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        brightness: Brightness.light,
        surface: AppColors.bgLight,
        surfaceContainerLow: AppColors.cardLight,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textLightPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1.2),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textLightPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textLightPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: AppColors.textLightPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: AppColors.textLightSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.dark,
        surface: AppColors.bgDark,
        surfaceContainerLow: AppColors.cardDark,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDarkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark, width: 1.2),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textDarkPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDarkPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: AppColors.textDarkPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: AppColors.textDarkSecondary,
        ),
      ),
    );
  }
}
