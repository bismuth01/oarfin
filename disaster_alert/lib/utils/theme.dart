import 'package:flutter/material.dart';

// App color palette
class AppColors {
  static const Color primary = Color(0xFF1E88E5); // Blue
  static const Color secondary = Color(
    0xFFFF8F00,
  ); // Amber/Orange (alert color)
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Colors.white;
  static const Color error = Color(0xFFD32F2F); // Red for errors/severe alerts
  static const Color success = Color(0xFF388E3C); // Green for success messages
  static const Color warning = Color(0xFFF57C00); // Orange for warnings
  static const Color info = Color(0xFF0288D1); // Light Blue for info

  // Alert severity colors
  static const Color criticalAlert = Color(0xFFD32F2F); // Red
  static const Color warningAlert = Color(0xFFF57C00); // Orange
  static const Color watchAlert = Color(0xFFFFB300); // Amber
  static const Color infoAlert = Color(0xFF0288D1); // Light Blue
  static const Color safeZone = Color(0xFF388E3C); // Green
}

// App text styles
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle body1 = TextStyle(fontSize: 16, color: Colors.black87);

  static const TextStyle body2 = TextStyle(fontSize: 14, color: Colors.black54);

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// Main app theme
final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
    background: AppColors.background,
    surface: AppColors.card,
  ),
  scaffoldBackgroundColor: AppColors.background,
  cardTheme: CardTheme(
    color: AppColors.card,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    elevation: 0,
    centerTitle: true,
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    buttonColor: AppColors.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: Colors.black54,
    indicator: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.primary, width: 3)),
    ),
  ),
);
