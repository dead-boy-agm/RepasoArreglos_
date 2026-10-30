import 'package:flutter/material.dart';

/// Paleta tomada de los mockups de RappoLink (PowerPoint).
class RL {
  static const primary = Color(0xFF2E6BFF);
  static const violet = Color(0xFF7C5CE7);
  static const soft = Color(0xFFEEF3FF);
  static const bg = Color(0xFFF7F9FC);
  static const text = Color(0xFF1F2937);
  static const text2 = Color(0xFF354052);
  static const muted = Color(0xFF7B8796);
  static const border = Color(0xFFE5EAF1);
  static const green = Color(0xFF12A150);
  static const greenSoft = Color(0xFFE6F7EE);
  static const red = Color(0xFFE5484D);
  static const redSoft = Color(0xFFFDECEC);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFFF4DD);
  static const violetSoft = Color(0xFFF0ECFD);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: RL.primary,
    primary: RL.primary,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: RL.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: RL.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: RL.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: RL.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: RL.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: RL.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RL.primary,
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, letterSpacing: .6, fontSize: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: RL.soft,
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}
