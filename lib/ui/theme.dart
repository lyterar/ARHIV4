import 'package:flutter/material.dart';

/// Тёмная «космическая» тема Material 3.
class AppColors {
  static const bg = Color(0xFF0B1020);
  static const card = Color(0xFF151D30);
  static const accent = Color(0xFF8AB4F8);
  static const text = Color(0xFFE8EDF7);
  static const muted = Color(0xFF9AA8BF);
  static const up = Color(0xFF81C995);
  static const down = Color(0xFFF28B82);
  static const warn = Color(0xFFFDD663);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    surface: AppColors.bg,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      centerTitle: false,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}
