import 'package:flutter/material.dart';

class AppTheme {
  // Colors extracted from Hesba logo
  static const Color primaryColor = Color(0xFF1A4FD6);      // Main Blue
  static const Color primaryDark = Color(0xFF0F2D8A);       // Dark Blue
  static const Color primaryLight = Color(0xFF3B6FF5);      // Light Blue
  static const Color secondaryColor = Color(0xFFF5A623);    // Yellow/Gold
  static const Color secondaryDark = Color(0xFFD4901A);     // Dark Gold
  static const Color backgroundColor = Color(0xFFF5F7FA);   // Light Background
  static const Color surfaceColor = Color(0xFFFFFFFF);      // White
  static const Color errorColor = Color(0xFFFF6B6B);        // Red
  static const Color successColor = Color(0xFF4CAF50);      // Green
  static const Color textPrimary = Color(0xFF1A1A2E);       // Dark Text
  static const Color textSecondary = Color(0xFF6B7280);     // Gray Text
  static const Color textLight = Color(0xFFFFFFFF);         // White Text

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F1420);    // Dark Background
  static const Color darkSurface = Color(0xFF1A2232);       // Dark Surface
  static const Color darkSurfaceAlt = Color(0xFF232D42);    // Dark Surface Alt
  static const Color darkTextPrimary = Color(0xFFF1F5F9);   // Light Text on dark
  static const Color darkTextSecondary = Color(0xFF9AA5B8); // Muted Text on dark

  static const String fontFamily = 'Cairo';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textSecondary, fontFamily: fontFamily),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkSurfaceAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: darkTextSecondary, fontFamily: fontFamily),
      ),
    );
  }
}
