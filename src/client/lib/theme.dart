import 'package:flutter/material.dart';

/// Цвета и оформление взяты из прототипа prototype/index.html (светлая и тёмная темы).
class AppColors {
  static const accent = Color(0xFF4F46E5);
  static const accent2 = Color(0xFF06B6D4);
  static const ok = Color(0xFF15803D);
  static const bad = Color(0xFFB91C1C);
  static const warn = Color(0xFFB45309);

  static const bgLight = Color(0xFFF3F5FB);
  static const cardLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF1B2233);
  static const mutedLight = Color(0xFF667085);
  static const lineLight = Color(0xFFE4E8F2);

  static const bgDark = Color(0xFF0E1322);
  static const cardDark = Color(0xFF171E31);
  static const inkDark = Color(0xFFE7EBF5);
  static const mutedDark = Color(0xFF9AA4BD);
  static const lineDark = Color(0xFF27304A);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final line = isDark ? AppColors.lineDark : AppColors.lineLight;

    return ThemeData(
      brightness: b,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: b,
        primary: AppColors.accent,
        surface: card,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 15),
        titleLarge: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    );
  }
}
