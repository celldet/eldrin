import 'package:flutter/material.dart';

/// Retro, monospaced look in both light (parchment) and dark (night ink).
class EldrinTheme {
  const EldrinTheme._();

  static const List<String> _monoFallback = ['Menlo', 'Courier New', 'Courier', 'monospace'];
  static const String fontFamily = 'monospace';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF3E9D2),
        surface: const Color(0xFFE8DABB),
        ink: const Color(0xFF2B2118),
        accent: const Color(0xFF8A4B14),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: const Color(0xFF0E1116),
        surface: const Color(0xFF171C24),
        ink: const Color(0xFFE6D8B5),
        accent: const Color(0xFFF0A93B),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color ink,
    required Color accent,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      onSurface: ink,
      primary: accent,
      secondary: accent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      fontFamilyFallback: _monoFallback,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: _monoFallback,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: ink,
        ),
      ),
      textTheme: ThemeData(brightness: brightness)
          .textTheme
          .apply(
            fontFamily: fontFamily,
            fontFamilyFallback: _monoFallback,
            bodyColor: ink,
            displayColor: ink,
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}
