import 'package:flutter/material.dart';
import '../design_system/radius.dart';
import 'amz_colors.dart';
import 'amz_typography.dart';

abstract final class AmzTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final bg = dark ? AmzColors.darkBackground : AmzColors.lightBackground;
    final surface = dark ? AmzColors.darkSurface : AmzColors.lightSurface;
    final elevated = dark ? AmzColors.darkElevated : AmzColors.lightElevated;
    final primary = dark ? AmzColors.darkPrimary : AmzColors.lightPrimary;
    final accent = dark ? AmzColors.darkAccent : AmzColors.lightAccent;
    final text = dark ? AmzColors.darkText : AmzColors.lightText;
    final secondaryText = dark ? AmzColors.darkSecondaryText : AmzColors.lightSecondaryText;
    final border = dark ? AmzColors.darkBorder : AmzColors.lightBorder;
    final error = dark ? AmzColors.darkError : AmzColors.lightError;
    final base = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
    final scheme = base.copyWith(
      // Noir sur rouge vif pour améliorer la lisibilité des boutons sombres.
      primary: primary, onPrimary: dark ? Colors.black : Colors.white,
      secondary: accent, surface: surface, onSurface: text,
      onSurfaceVariant: secondaryText, outline: border, outlineVariant: border,
      surfaceContainerLow: surface, surfaceContainer: elevated,
      surfaceContainerHighest: dark ? AmzColors.darkElevated : AmzColors.lightBackgroundSecondary,
      error: error,
    );
    final initial = ThemeData(useMaterial3: true, colorScheme: scheme);
    return initial.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: AmzTypography.apply(initial.textTheme, text, secondaryText),
      appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: text, elevation: 0),
      cardTheme: CardThemeData(color: surface, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AmzRadius.large), side: BorderSide(color: border))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AmzRadius.medium), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AmzRadius.medium), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AmzRadius.medium), borderSide: BorderSide(color: primary, width: 2))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AmzRadius.medium)))),
      // Rouge discret pour l'élément de navigation sélectionné.
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface, indicatorColor: primary.withAlpha(40)),
      navigationRailTheme: NavigationRailThemeData(
          backgroundColor: surface, indicatorColor: primary.withAlpha(40)),
    );
  }
}