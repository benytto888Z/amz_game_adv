import 'package:flutter/material.dart';

import '../design_system/radius.dart';
import 'amz_theme.dart';
import 'amz_typography.dart';

/// Variante claire bleutée ; elle ne suit pas l'apparence du système.
ThemeData get amzLiquidTheme {
  const background = Color(0xFFE9F5FC);
  const surface = Color(0xFFF8FCFF);
  const elevated = Color(0xFFDCEFF9);
  const primary = Color(0xFF075C89);
  const secondary = Color(0xFF087F8C);
  const text = Color(0xFF102A3B);
  const muted = Color(0xFF476779);
  const border = Color(0xFFB8D4E3);

  final base = AmzTheme.build(Brightness.light);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: muted,
    outline: border,
    outlineVariant: border,
    surfaceContainerLow: surface,
    surfaceContainer: elevated,
    surfaceContainerHighest: elevated,
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AmzRadius.medium),
    borderSide: const BorderSide(color: border),
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: AmzTypography.apply(base.textTheme, text, muted),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmzRadius.large),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmzRadius.medium),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withAlpha(40),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withAlpha(40),
    ),
  );
}
